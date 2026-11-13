// List the outermost elements that stick out of a 320 px wide viewport.
// Usage: NODE_PATH=$(npm root -g) node tools/a11y/overflow.js <url>
const { chromium } = require("playwright");
(async () => {
  const b = await chromium.launch({ channel: "chrome", headless: true });
  const p = await (await b.newContext({ viewport: { width: 320, height: 720 } })).newPage();
  await p.goto(process.argv[2], { waitUntil: "networkidle" });
  await p.waitForTimeout(1500);
  const out = await p.evaluate(() => {
    const res = [];
    for (const el of document.querySelectorAll("body *")) {
      const r = el.getBoundingClientRect();
      if (r.right > 322 && r.width > 0) {
        const pr = el.parentElement.getBoundingClientRect();
        if (pr.right <= 322) {
          const txt = (el.textContent || "").trim().slice(0, 60).replace(/\s+/g, " ");
          res.push(`${el.tagName.toLowerCase()}.${[...el.classList].join(".")} right=${Math.round(r.right)} parent=${el.parentElement.tagName.toLowerCase()}.${[...el.parentElement.classList].join(".")} :: ${txt}`);
        }
      }
    }
    return res.slice(0, 12);
  });
  console.log(out.join("\n"));
  await b.close();
})();
