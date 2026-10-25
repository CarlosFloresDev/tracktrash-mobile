"""QA de preferencias y antelación contra Flutter/API/PostgreSQL reales.

Requiere Playwright y Edge. Variables opcionales TRACKTRASH_WEB_URL y
TRACKTRASH_API_URL; defaults localhost:5300/5080. La API demo debe permitir el
origen web de prueba. Restaura el perfil y la suscripción al terminar.
"""
import json
import os
import re
import urllib.request
from pathlib import Path
from playwright.sync_api import sync_playwright

api = os.environ.get('TRACKTRASH_API_URL', 'http://localhost:5080')
web = os.environ.get('TRACKTRASH_WEB_URL', 'http://localhost:5300')
out = Path(__file__).resolve().parents[1] / 'docs' / 'screenshots'
out.mkdir(parents=True, exist_ok=True)


def request(path, method='GET', data=None):
    req = urllib.request.Request(api + '/api/v1/' + path,
        data=None if data is None else json.dumps(data).encode(),
        headers={'Authorization': 'Bearer demo-vecino', 'Content-Type': 'application/json'},
        method=method)
    with urllib.request.urlopen(req, timeout=20) as response:
        body = response.read()
        return json.loads(body) if body else None


original = request('perfil')
route = request('rutas')[0]
editable = {k: original[k] for k in ('nombre', 'telefono', 'direccion', 'latitud', 'longitud', 'recibirAvisos', 'preferenciasAvisos')}
try:
    setup = dict(editable, recibirAvisos=True,
        preferenciasAvisos={'horarios': True, 'recojos': True, 'incidencias': True, 'recompensas': True})
    request('perfil', 'PUT', setup)
    with sync_playwright() as p:
        browser = p.chromium.launch(channel='msedge', headless=True)
        page = browser.new_page(viewport={'width': 430, 'height': 1100}, reduced_motion='reduce')
        errors = []
        page.on('pageerror', lambda e: errors.append(str(e)))

        def button(name):
            return page.get_by_role('button', name=name, exact=True)

        def reveal(locator):
            for _ in range(12):
                if locator.count() and locator.first.is_visible():
                    return
                page.mouse.move(210, 750)
                page.mouse.wheel(0, 320)
                page.wait_for_timeout(350)
            locator.first.wait_for()

        def shot(name):
            page.mouse.move(0, 0)
            page.wait_for_timeout(1200)
            page.screenshot(path=str(out / f'{name}.png'))

        page.goto(web)
        page.locator('flt-semantics-placeholder').evaluate('(e)=>e.click()')
        button('Probar como vecino').click(timeout=60000)
        page.get_by_role('tab').nth(4).click(timeout=60000)
        pickups = page.get_by_role('switch', name=re.compile('Seguimiento de recojos'))
        reveal(pickups)
        pickups.click()
        save = button('Guardar cambios')
        reveal(save)
        with page.expect_response(lambda r: '/perfil' in r.url and r.request.method == 'PUT') as saved:
            save.click()
        assert saved.value.status == 204, saved.value.text()
        assert request('perfil')['preferenciasAvisos']['recojos'] is False
        page.wait_for_timeout(1300)
        reveal(page.get_by_role('switch', name=re.compile('Seguimiento de recojos')))
        shot('preferencias-avisos-mobile')

        page.get_by_role('tab').nth(0).click()
        schedules = button(re.compile('^Horarios de recolecci.n'))
        reveal(schedules)
        schedules.click()
        anticipation = page.get_by_role('button', name=re.compile('Anticipaci.n del aviso'))
        anticipation.first.wait_for(timeout=30000)
        anticipation.first.click()
        page.get_by_label('35 minutos antes', exact=True).last.click()
        active = page.get_by_role('switch').first
        if active.get_attribute('aria-checked') == 'false':
            action = active
        else:
            action = button(re.compile('Guardar anticipaci.n'))
        reveal(action)
        with page.expect_response(lambda r: '/suscripcion' in r.url and r.request.method == 'POST') as subscription:
            action.click()
        assert subscription.value.status == 204, subscription.value.text()
        current = next(r for r in request('rutas') if r['id'] == route['id'])
        assert current['minutosAntes'] == 35
        page.wait_for_timeout(1500)
        shot('antelacion-ruta-mobile')
        assert not errors, errors
        browser.close()
    print('OK: preferencias persistidas y anticipacion de 35 minutos guardada desde Flutter, sin errores JS.')
finally:
    request('perfil', 'PUT', editable)
    if route['suscrito']:
        request(f"rutas/{route['id']}/suscripcion", 'POST', {'minutosAntes': route['minutosAntes']})
    else:
        request(f"rutas/{route['id']}/suscripcion", 'DELETE')
