const { chromium } = require('playwright');
const path = require('path');
const pages = require(process.argv[2]);
const THREE_DIR = process.env.THREE_DIR || path.join(__dirname, '.cache', 'three', 'node_modules', 'three');
(async () => {
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  for (const [html, png, w, h] of pages) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    p.on('pageerror', e => console.log('pageerror:', e.message));
    await p.route('https://unpkg.com/three@0.160.0/**', route => {
      const rel = route.request().url().split('three@0.160.0/')[1];
      route.fulfill({ path: path.join(THREE_DIR, rel), contentType: 'application/javascript' });
    });
    await p.goto('file://' + html);
    await p.waitForFunction(() => document.body.dataset.done, null, { timeout: 30000 }).catch(() => console.log('timeout', html));
    await p.screenshot({ path: png }); await p.close();
  }
  await b.close();
})();
