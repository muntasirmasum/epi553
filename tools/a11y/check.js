// Run axe-core (WCAG 2.0/2.1 A and AA) on site pages in light and dark mode,
// at desktop and 320 px widths. Usage: node run-axe.js <baseURL> <page> [<page> ...]
const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");

const axeSource = fs.readFileSync(
  path.join(__dirname, "node_modules/axe-core/axe.min.js"), "utf8");
const [base, ...pages] = process.argv.slice(2);

const configs = [
  { name: "light-desktop", scheme: "light", width: 1280, height: 900 },
  { name: "dark-desktop",  scheme: "dark",  width: 1280, height: 900 },
  { name: "light-320",     scheme: "light", width: 320,  height: 720 },
  { name: "dark-320",      scheme: "dark",  width: 320,  height: 720 },
];

(async () => {
  const browser = await chromium.launch({ channel: "chrome", headless: true });
  let total = 0;
  for (const page of pages) {
    for (const cfg of configs) {
      const ctx = await browser.newContext({
        colorScheme: cfg.scheme,
        viewport: { width: cfg.width, height: cfg.height },
      });
      const p = await ctx.newPage();
      await p.goto(base + page, { waitUntil: "networkidle" });
      await p.waitForTimeout(1500); // MathJax and widgets settle
      await p.addScriptTag({ content: axeSource });
      const res = await p.evaluate(async () =>
        await axe.run(document, {
          runOnly: { type: "tag", values: ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"] },
        }));
      // Reflow check at 320 px: page should not need horizontal scrolling.
      let reflow = "";
      if (cfg.width === 320) {
        const sw = await p.evaluate(() => document.documentElement.scrollWidth);
        reflow = sw > 320 ? ` | horizontal overflow: scrollWidth=${sw}` : " | reflow ok";
      }
      console.log(`\n== ${page} [${cfg.name}] violations: ${res.violations.length}${reflow}`);
      for (const v of res.violations) {
        total += 1;
        console.log(`- ${v.id} (${v.impact}): ${v.help} [${v.nodes.length} nodes]`);
        for (const n of v.nodes.slice(0, 4)) {
          console.log(`    ${n.target.join(" ")} :: ${(n.failureSummary || "").split("\n").slice(1, 2).join(" ").trim().slice(0, 180)}`);
        }
      }
      await ctx.close();
    }
  }
  await browser.close();
  console.log(`\nTOTAL violation groups: ${total}`);
})();
