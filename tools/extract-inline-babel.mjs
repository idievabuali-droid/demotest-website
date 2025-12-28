import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";

const ROOT = process.cwd();

function extractBabelScript(html) {
  const marker = '<script type="text/babel"';
  const startTag = html.indexOf(marker);
  if (startTag < 0) throw new Error("No text/babel script tag found");
  const startContent = html.indexOf(">", startTag);
  if (startContent < 0) throw new Error("Malformed script tag");
  const endTag = html.indexOf("</script>", startContent);
  if (endTag < 0) throw new Error("Missing </script>");
  return html.slice(startContent + 1, endTag);
}

async function main() {
  const files = [
    { html: "index.html", out: "src/customer.jsx" },
    { html: "owner.html", out: "src/owner.jsx" },
  ];

  for (const f of files) {
    const htmlPath = join(ROOT, f.html);
    const outPath = join(ROOT, f.out);
    const html = await readFile(htmlPath, "utf8");
    const script = extractBabelScript(html);
    await mkdir(dirname(outPath), { recursive: true });
    await writeFile(outPath, script.trimStart(), "utf8");
    process.stdout.write(`extracted ${f.html} -> ${f.out}\n`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

