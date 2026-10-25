// Pushes every script under src/ into the place open in Roblox Studio (Edit mode), matching the
// Rojo tree in default.project.json, so a change can be play-tested without reopening the file.
// Usage: node tools/studio/sync-scripts.mjs   (Studio open, Studio MCP server enabled, not playing)
import { readFileSync, readdirSync, statSync, writeFileSync, mkdirSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { join, relative } from "node:path";

const ROOTS = {
	"src/shared": ["ReplicatedStorage", "Shared"],
	"src/server": ["ServerScriptService", "Server"],
	"src/client": ["StarterPlayer", "StarterPlayerScripts", "Client"],
};

function walk(dir) {
	return readdirSync(dir).flatMap((n) => {
		const p = join(dir, n);
		return statSync(p).isDirectory() ? walk(p) : [p];
	});
}

const lines = ["local done = {}"];
for (const [root, base] of Object.entries(ROOTS)) {
	for (const file of walk(root).filter((f) => f.endsWith(".luau"))) {
		const rel = relative(root, file).replaceAll("\\", "/").split("/");
		const leaf = rel.pop();
		const [, name, kind] = leaf.match(/^(.*?)(?:\.(server|client))?\.luau$/);
		const cls = kind === "server" ? "Script" : kind === "client" ? "LocalScript" : "ModuleScript";
		const path = [...base, ...rel];
		lines.push("do");
		lines.push(`local parent = game:GetService(${JSON.stringify(path[0])})`);
		for (const seg of path.slice(1)) {
			lines.push(`parent = parent:FindFirstChild(${JSON.stringify(seg)}) or (function() local f = Instance.new("Folder") f.Name = ${JSON.stringify(seg)} f.Parent = parent return f end)()`);
		}
		lines.push(`local s = parent:FindFirstChild(${JSON.stringify(name)})`);
		lines.push(`if not s or s.ClassName ~= ${JSON.stringify(cls)} then if s then s:Destroy() end s = Instance.new(${JSON.stringify(cls)}) s.Name = ${JSON.stringify(name)} s.Parent = parent end`);
		lines.push(`s.Source = ${JSON.stringify(readFileSync(file, "utf8"))}`);
		lines.push(`table.insert(done, ${JSON.stringify(path.join(".") + "." + name)})`);
		lines.push("end");
	}
}
lines.push('return #done .. " scripts synced"');
mkdirSync("tools/studio/.out", { recursive: true });
writeFileSync("tools/studio/.out/sync.luau", lines.join("\n"));
console.log(execFileSync("node", ["tools/studio/studio.mjs", "luau", "tools/studio/.out/sync.luau", "Edit"], { encoding: "utf8", maxBuffer: 1 << 24 }).trim());
