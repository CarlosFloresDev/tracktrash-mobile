"""QA opcional de mapa, reportes, avisos, suscripciones y atención operativa.

Mismos requisitos locales que smoke_web.py; crea una incidencia de prueba.
"""
import re
from pathlib import Path
from playwright.sync_api import sync_playwright

out = Path(__file__).resolve().parents[1] / 'docs' / 'screenshots'
out.mkdir(parents=True, exist_ok=True)
with sync_playwright() as p:
    browser = p.chromium.launch(channel='msedge', headless=True)
    page = browser.new_page(viewport={'width': 1280, 'height': 1000})
    errors = []
    page.on('pageerror', lambda e: errors.append(str(e)))

    def button(name):
        return page.get_by_role('button', name=name, exact=True)

    def show(target):
        for _ in range(8):
            if target.count() and target.first.is_visible():
                return
            page.mouse.move(900, 700)
            page.mouse.wheel(0, 350)
            page.wait_for_timeout(500)
        target.first.wait_for()

    def shot(name):
        page.mouse.move(0, 0)
        page.wait_for_timeout(1600)
        page.screenshot(path=str(out / f'{name}.png'))

    def login(name):
        button(name).click(timeout=60000)
        button(re.compile('Cerrar sesi.n')).wait_for(timeout=60000)

    def enter(value):
        field = page.get_by_role('textbox')
        field.click()
        page.wait_for_timeout(250)
        page.keyboard.type(value, delay=15)

    page.goto('http://localhost:5300')
    page.locator('flt-semantics-placeholder').evaluate('(e)=>e.click()')
    login('Probar como vecino')
    button('Explorar mi zona').click()
    button('Actualizar mapa').wait_for(timeout=30000)
    button(re.compile('^Plaza de referencia')).first.click()
    button('Reportar un problema').click()
    enter('Prueba E2E: se requiere revisar el contenedor de demostracion.')
    with page.expect_response(lambda r: r.url.endswith('/incidencias') and r.request.method == 'POST') as report:
        button('Enviar reporte').click()
    assert report.value.status == 200, report.value.text()
    issue_id = report.value.json()['id']
    shot('reporte-vecino')
    page.go_back()
    button('Notificaciones').click()
    page.wait_for_timeout(1200)
    shot('notificaciones-desktop')
    page.go_back()
    button(re.compile('^Inicio')).click()
    schedules = button(re.compile('^Horarios de recolecci.n'))
    show(schedules)
    schedules.click()
    reminder = page.get_by_role('switch').first
    reminder.wait_for(timeout=30000)
    if reminder.get_attribute('aria-checked') == 'false':
        with page.expect_response(lambda r: '/suscripcion' in r.url and r.request.method == 'POST') as subscription:
            reminder.click()
        assert subscription.value.status == 204
    shot('horarios-desktop')
    page.go_back()
    button(re.compile('Cerrar sesi.n')).click()
    login('Explorar como operador')
    button(re.compile('Abrir panel de operaci.n')).click()
    button('Gestionar incidencias').wait_for(timeout=30000)
    shot('panel-operacion')
    button('Gestionar incidencias').click()
    attend = button(re.compile('Tomar atenci.n'))
    show(attend)
    with page.expect_response(lambda r: '/atencion' in r.url and r.request.method == 'POST') as attention:
        attend.first.click()
    assert attention.value.status == 204, attention.value.text()
    assert issue_id in attention.value.url
    resolve = button('Resolver incidencia')
    show(resolve)
    resolve.first.click()
    enter('Prueba E2E: contenedor revisado y atencion de demostracion concluida.')
    with page.expect_response(lambda r: '/resolucion' in r.url and r.request.method == 'POST') as resolution:
        button('Guardar').click()
    assert resolution.value.status == 204, resolution.value.text()
    assert issue_id in resolution.value.url
    shot('incidencia-resuelta')
    assert not errors, errors
    print('OK: mapa, reporte ciudadano, bandeja, suscripcion y resolucion operativa sin errores JS.')
    browser.close()
