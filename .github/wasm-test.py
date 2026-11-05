# Opens hello_qt's web page in the runner's Google Chrome (headless, driven by Playwright), waits until the
# page has started the app (it hides #loading), checks that the window's title bar, which Qt draws, shows
# the app's icon (hello_qt.cpp), and saves a screenshot of the app's screen (#screen), which OCR then reads.
# It prints the browser's version and the icon's size, and the page's console messages, with its errors and
# warnings as annotations, which can be read without a GitHub login.
#
#   python .github/wasm-test.py http://localhost:8000/ screen.png
import base64
import struct
import sys

from playwright.sync_api import sync_playwright

url, png = sys.argv[1], sys.argv[2]
ok = True
with sync_playwright() as p:
    browser = p.chromium.launch(channel='chrome')
    print('browser: Google Chrome', browser.version, flush=True)
    # Twice the pixels, as on a phone or a Mac with a Retina screen, so that the text is big enough for OCR
    page = browser.new_page(viewport={'width': 800, 'height': 600}, device_scale_factor=2)
    page.on('console', lambda m: print(('::warning title=Console::' if m.type in ('error', 'warning') else
                                        'console: ') + f'{m.type}: {m.text}', flush=True))
    page.on('pageerror', lambda e: print(f'::error title=Page error::{e}', flush=True))
    page.goto(url)
    try:
        page.wait_for_selector('#loading', state='hidden', timeout=60000)
        page.wait_for_timeout(3000)  # for Qt to draw the window
    except Exception as e:
        ok = False
        print(f"::error::The page didn't start hello_qt within a minute ({type(e).__name__}); it says: "
              f"{page.inner_text('#status')}", flush=True)
    if ok:
        # The title bar's first image: the window's icon, as a PNG, or else Qt's logo, an SVG. Playwright's
        # CSS selectors also look into the shadow DOM, where Qt puts its windows.
        try:
            icon = page.locator('.qt-decorated-window .title-bar .image-button img').first.get_attribute(
                'src', timeout=10000)
        except Exception as e:
            icon = f'no image ({type(e).__name__})'
        if icon and icon.startswith('data:image/png;base64,'):
            width, height = struct.unpack('>2I', base64.b64decode(icon.split(',', 1)[1])[16:24])
            print(f"window icon: the app's, {width}x{height} pixels in the title bar", flush=True)
        else:
            ok = False
            print(f"::error::The window's title bar doesn't show the app's icon, but {(icon or '')[:40]}",
                  flush=True)
    page.locator('#screen').screenshot(path=png)
    browser.close()
sys.exit(0 if ok else 1)
