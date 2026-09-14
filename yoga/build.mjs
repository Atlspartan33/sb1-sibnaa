/* Wraps the artifact-shaped source (mat.html has no doctype/html/head/body,
   because the Artifact host supplies them) into a standalone page you can
   open from the filesystem or host anywhere. */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";

const src = readFileSync(new URL("./mat.html", import.meta.url), "utf8");
const title = (src.match(/<title>([^<]*)<\/title>/) || [, "Four-Minute Floor"])[1];

mkdirSync(new URL("./dist/", import.meta.url), { recursive: true });
writeFileSync(new URL("./dist/index.html", import.meta.url), `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="description" content="${title} — a four-minute floor for restarting a yoga and meditation practice.">
<style>:root{color-scheme:light dark}body{margin:0;font:14px system-ui}img{max-width:100%}[hidden]{display:none!important}</style>
</head>
<body>
${src}
</body>
</html>
`);
console.log("wrote yoga/dist/index.html");
