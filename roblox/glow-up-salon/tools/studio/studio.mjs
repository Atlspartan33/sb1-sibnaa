// Minimal MCP client for Roblox Studio's built-in server (StudioMCP.exe).
// Usage:
//   node tools/studio.mjs list                      → tool names
//   node tools/studio.mjs call <tool> '<json args>'  → result text
//   node tools/studio.mjs luau <file.luau>           → execute_luau with that file's source
// studio_id is filled in automatically from list_roblox_studios when omitted.

import { spawn } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { findStudioMcp } from "./studio-path.mjs";

function session() {
	const proc = spawn(findStudioMcp(), ["--stdio"], { stdio: ["pipe", "pipe", "pipe"] });
	let buf = "";
	let nextId = 1;
	const waiting = new Map();
	proc.stdout.on("data", (chunk) => {
		buf += chunk;
		let nl;
		while ((nl = buf.indexOf("\n")) >= 0) {
			const line = buf.slice(0, nl).trim();
			buf = buf.slice(nl + 1);
			if (!line) continue;
			let msg;
			try {
				msg = JSON.parse(line);
			} catch {
				continue;
			}
			if (msg.id && waiting.has(msg.id)) {
				waiting.get(msg.id)(msg);
				waiting.delete(msg.id);
			}
		}
	});
	let stderr = "";
	proc.stderr.on("data", (c) => (stderr += c));
	const send = (obj) => proc.stdin.write(JSON.stringify(obj) + "\n");
	const request = (method, params, timeoutMs = 120000) =>
		new Promise((resolve, reject) => {
			const id = nextId++;
			const t = setTimeout(() => reject(new Error(`timeout on ${method}\n${stderr}`)), timeoutMs);
			waiting.set(id, (msg) => {
				clearTimeout(t);
				msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result);
			});
			send({ jsonrpc: "2.0", id, method, params });
		});
	return {
		async init() {
			await request("initialize", { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "glow-up-salon", version: "1" } });
			send({ jsonrpc: "2.0", method: "notifications/initialized" });
		},
		request,
		close: () => proc.kill(),
	};
}

const text = (result) =>
	(result.content ?? [])
		.map((c, i) => {
			if (c.type === "text") return c.text;
			if (c.type === "image") {
				const file = `tools/studio/.shot-${Date.now()}-${i}.png`;
				writeFileSync(file, Buffer.from(c.data, "base64"));
				return `[image saved: ${file}]`;
			}
			return JSON.stringify(c);
		})
		.join("\n");

const [cmd, a, b] = process.argv.slice(2);
const s = session();
try {
	await s.init();
	if (cmd === "list") {
		const r = await s.request("tools/list", {});
		for (const t of r.tools) console.log(`${t.name}: ${JSON.stringify(t.inputSchema?.properties ?? {})}`);
	} else {
		let tool = a;
		let args = b && cmd !== "luau" ? JSON.parse(b) : {};
		if (cmd === "luau") {
			// node tools/studio.mjs luau <file.luau> [Edit|Server|Client]
			tool = "execute_luau";
			args = { code: readFileSync(a, "utf8"), datamodel_type: b ?? "Edit" };
		}
		if (tool !== "list_roblox_studios" && !args.studio_id) {
			// Studio dials in to the bridge on its own schedule; give it up to a minute.
			let studios = "";
			for (let i = 0; i < 20; i++) {
				studios = text(await s.request("tools/call", { name: "list_roblox_studios", arguments: {} }));
				if (!/"studios":\[\]/.test(studios)) break;
				await new Promise((r) => setTimeout(r, 3000));
			}
			// Refuse to guess between windows: sync deletes Workspace.Course in whichever one it picks.
			let count = 0;
			try {
				count = (JSON.parse(studios).studios ?? []).length;
			} catch {}
			if (count > 1) throw new Error(`${count} Studio windows are connected; close the extras or pass studio_id.\n${studios}`);
			const m = studios.match(/"?studio_id"?\s*[:=]\s*"?([\w-]+)/i) ?? studios.match(/([0-9a-f]{8}-[0-9a-f-]{27,})/i);
			if (m) args.studio_id = m[1];
			else throw new Error("No Studio connected to the MCP bridge:\n" + studios);
		}
		const r = await s.request("tools/call", { name: tool, arguments: args }, 300000);
		console.log(text(r));
		if (r.isError) process.exitCode = 1;
	}
} catch (e) {
	console.error(e.message);
	process.exitCode = 1;
} finally {
	s.close();
}
