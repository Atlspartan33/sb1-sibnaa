const { chromium } = require('playwright');
const pages = require(process.argv[2]);
(async () => {
  const b = await chromium.launch();
  for (const [html, png, w, h] of pages) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    await p.goto('file://' + html);
    await p.waitForFunction(() => document.body.dataset.done, null, { timeout: 15000 }).catch(() => {});
    await p.screenshot({ path: png, omitBackground: true }); await p.close();
  }
  await b.close();
})();
