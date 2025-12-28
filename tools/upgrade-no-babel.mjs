import { readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";

const ROOT = process.cwd();

function removeFirstBabelBlock(html) {
  const marker = '<script type="text/babel"';
  const start = html.indexOf(marker);
  if (start < 0) return html;
  const end = html.indexOf("</script>", start);
  if (end < 0) throw new Error("Missing </script> for text/babel block");
  return html.slice(0, start) + html.slice(end + "</script>".length);
}

function ensureScriptAfter(html, afterNeedle, scriptTag) {
  if (html.includes(scriptTag)) return html;
  const idx = html.indexOf(afterNeedle);
  if (idx < 0) throw new Error(`Could not find insertion point: ${afterNeedle}`);
  const insertAt = idx + afterNeedle.length;
  return html.slice(0, insertAt) + "\n  " + scriptTag + html.slice(insertAt);
}

function replaceRootPlaceholder(html) {
  const simple = '<div id="root"></div>';
  const placeholder =
    '<div id="root" class="min-h-screen flex items-center justify-center">' +
    '\n    <div class="text-sm text-slate-600">Loading…</div>' +
    '\n    <noscript><div class="mt-3 text-xs text-slate-500">This site requires JavaScript enabled.</div></noscript>' +
    "\n  </div>";
  return html.includes(simple) ? html.replace(simple, placeholder) : html;
}

function removeBabelStandalone(html) {
  return html.replace(
    /\s*<!-- Babel Standalone for JSX transpilation -->\s*\r?\n\s*<script src="https:\/\/unpkg\.com\/@babel\/standalone\/babel\.min\.js"><\/script>\s*\r?\n?/,
    "\n"
  );
}

async function upgradeOne({ file, bundle }) {
  const path = join(ROOT, file);
  let html = await readFile(path, "utf8");
  html = removeBabelStandalone(html);
  html = replaceRootPlaceholder(html);
  html = removeFirstBabelBlock(html);
  html = ensureScriptAfter(
    html,
    '<script defer src="supabase-config.js"></script>',
    `<script defer src="${bundle}"></script>`
  );
  await writeFile(path, html, "utf8");
  process.stdout.write(`updated ${file} to use ${bundle}\n`);
}

async function main() {
  await upgradeOne({ file: "index.html", bundle: "customer.js" });
  await upgradeOne({ file: "owner.html", bundle: "owner.js" });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

