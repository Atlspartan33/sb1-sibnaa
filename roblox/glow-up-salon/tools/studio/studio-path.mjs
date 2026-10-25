import { readdirSync, statSync } from "node:fs";
import { join } from "node:path";

// Newest StudioMCP.exe under %LOCALAPPDATA%\Roblox\Versions.
export function findStudioMcp() {
	const root = join(process.env.LOCALAPPDATA, "Roblox", "Versions");
	const exes = readdirSync(root)
		.map((d) => join(root, d, "StudioMCP.exe"))
		.filter((p) => {
			try {
				return statSync(p).isFile();
			} catch {
				return false;
			}
		})
		.sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs);
	if (!exes.length) throw new Error("StudioMCP.exe not found — is Roblox Studio installed?");
	return exes[0];
}
