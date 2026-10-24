"""Recorrido local real: Flutter web -> API -> PostgreSQL.

Requiere Python + playwright y Edge instalado. Iniciar API demo en 5080 y
servir build/web en 5300. Crea una entrega de prueba; no borra datos existentes.
Ejecutar: python tools/smoke_web.py
"""
import json
import re
from pathlib import Path
from playwright.sync_api import sync_playwright

OUT = Path(__file__).resolve().parents[1] / 'docs' / 'screenshots'
OUT.mkdir(parents=True, exist_ok=True)

with sync_playwright() as p:
    browser = p.chromium.launch(channel='msedge', headless=True)
    page = browser.new_page(viewport={'width': 430, 'height': 932})
    errors = []
    page.on('pageerror', lambda e: errors.append(str(e)))

    def button(name):
        return page.get_by_role('button', name=name, exact=True)

    def shot(name):
        page.mouse.move(0, 0)
        page.wait_for_timeout(1400)
        page.screenshot(path=str(OUT / f'{name}.png'), full_page=True)

    def login(role):
        button(role).click(timeout=60000)
        button(re.compile('Cerrar sesi.n')).wait_for(timeout=60000)
        page.wait_for_timeout(1200)

    def logout():
        button(re.compile('Cerrar sesi.n')).click()
        button('Probar como vecino').wait_for()

    def type_field(field, value):
        field.click()
        page.wait_for_timeout(250)
        page.keyboard.press('ControlOrMeta+A')
        page.keyboard.type(value, delay=15)

    def pickup_action(label, states):
        # Respeta el orden real del listado y otros recojos preexistentes.
        result = page.request.get('http://localhost:5080/api/v1/solicitudes?pagina=1',
                                  headers={'Authorization': 'Bearer demo-reciclador'})
        items = [x for x in result.json() if x['estado'] in states]
        index = next(i for i, x in enumerate(items) if x['id'] == pickup['id'])
        button(label).nth(index).click()

    page.goto('http://localhost:5300')
    page.locator('flt-semantics-placeholder').evaluate('(e)=>e.click()')
    button('Probar como vecino').wait_for(timeout=60000)
    shot('bienvenida-mobile')
    login('Probar como vecino')
    shot('inicio-mobile')
    button('Solicitar un recojo').click()
    fields = page.get_by_role('textbox')
    type_field(fields.nth(0), '2.5')
    type_field(fields.nth(1), 'Prueba automatizada E2E, Arequipa 123')
    button('Usar punto de prueba de Arequipa').click()
    page.get_by_role('switch').click()
    with page.expect_response(lambda r: r.request.method == 'POST' and r.url.endswith('/solicitudes')) as created:
        button('Confirmar solicitud').click()
    response = created.value
    assert response.status in (200, 201), response.text()
    pickup = response.json()
    code = pickup['codigoConfirmacion']
    assert response.request.post_data_json['autoAsignar'], 'No se solicito asignacion automatica'
    logout()
    login('Probar como reciclador')
    page.get_by_role('tab').nth(2).click()
    with page.expect_response(lambda r: '/aceptacion' in r.url and r.request.method == 'POST') as accepted:
        pickup_action('Aceptar recojo', ['Pendiente'])
    assert accepted.value.status == 200, accepted.value.text()
    assert accepted.value.json()['id'] == pickup['id']
    page.wait_for_timeout(1200)
    with page.expect_response(lambda r: '/viaje' in r.url and r.request.method == 'POST') as travelling:
        pickup_action('Iniciar viaje', ['Aceptada'])
    assert travelling.value.status == 200, travelling.value.text()
    assert travelling.value.json()['id'] == pickup['id']
    page.wait_for_timeout(1200)
    pickup_action(re.compile('Confirmar con c.digo'), ['Aceptada', 'EnCamino'])
    type_field(page.get_by_role('textbox'), code)
    with page.expect_response(lambda r: '/confirmacion' in r.url and r.request.method == 'POST') as confirmed:
        button('Confirmar').click()
    assert pickup['id'] in confirmed.value.url, confirmed.value.url
    assert confirmed.value.request.post_data_json['codigo'] == code, 'El teclado no ingreso el codigo completo'
    assert confirmed.value.status == 200, confirmed.value.text()
    shot('recojos-reciclador')
    logout()
    login('Probar como vecino')
    page.get_by_role('tab').nth(3).click()
    shot('impacto-mobile')
    for _ in range(6):
        if button('Canjear beneficio').count():
            break
        page.mouse.move(200, 650)
        page.mouse.wheel(0, 420)
        page.wait_for_timeout(700)
    button('Canjear beneficio').first.click()
    with page.expect_response(lambda r: r.url.endswith('/canjes') and r.request.method == 'POST') as redeemed:
        button('Canjear').last.click()
    assert redeemed.value.status in (200, 201), redeemed.value.text()
    page.get_by_role('tab').nth(1).click()
    button('Actualizar mapa').wait_for(timeout=30000)
    shot('mapa-mobile')
    page.get_by_role('tab').nth(4).click()
    shot('perfil-mobile')
    page.set_viewport_size({'width': 1280, 'height': 900})
    page.wait_for_timeout(1200)
    button(re.compile('^Inicio')).click()
    shot('inicio-desktop')
    page.set_viewport_size({'width': 360, 'height': 800})
    shot('inicio-360')
    logout()
    login('Explorar como operador')
    shot('operador-inicio')
    assert not errors, json.dumps(errors, ensure_ascii=False)
    print('OK: crear/asignar/aceptar/viajar/confirmar/canjear, mapa, perfil, tres tamanos y cambio de roles sin errores JS.')
    browser.close()
