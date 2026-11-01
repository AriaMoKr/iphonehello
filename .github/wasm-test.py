# Opens hello_qt's web page in the runner's Google Chrome (headless, driven by Playwright), waits until the
# page has started the app (it hides #loading), and saves a screenshot of the app's screen (#screen), which
# OCR then reads. It prints the browser's version, and the page's console messages, with its errors and
# warnings as annotations, which can be read without a GitHub login.
#
#   python .github/wasm-test.py http://localhost:8000/ screen.png
import sys

from playwright.sync_api import sync_playwright

url, png = sys.argv[1], sys.argv[2]
started = True
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
        started = False
        print(f"::error::The page didn't start hello_qt within a minute ({type(e).__name__}); it says: "
              f"{page.inner_text('#status')}", flush=True)
    page.locator('#screen').screenshot(path=png)
    browser.close()
sys.exit(0 if started else 1)
