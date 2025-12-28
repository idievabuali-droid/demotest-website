import { spawn } from "node:child_process";

async function esbuild(args) {
  const isWin = process.platform === "win32";
  const bin = isWin ? "npx.cmd" : "npx";

  await new Promise((resolve, reject) => {
    const child = spawn(bin, ["--yes", "esbuild", ...args], {
      stdio: "inherit",
      windowsHide: true,
      shell: isWin,
    });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`esbuild exited with code ${code}`));
    });
  });
}

async function main() {
  const common = [
    "--format=iife",
    "--target=es2018",
    "--jsx=transform",
    "--jsx-factory=React.createElement",
    "--jsx-fragment=React.Fragment",
    "--minify",
  ];

  await esbuild(["src/customer.jsx", "--outfile=customer.js", ...common]);
  await esbuild(["src/owner.jsx", "--outfile=owner.js", ...common]);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
