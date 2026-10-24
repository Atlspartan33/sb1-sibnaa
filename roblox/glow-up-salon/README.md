# ✨ 5 Minute Glow Up Salon (Roblox)

Tori's makeover game. Clients come in dirty from the shop. You wash their face, do their hair and makeup, dress them up, and send them down the runway. You get 5 minutes to do it all.

- **How the game works and how it makes money:** [GAME_DESIGN.md](GAME_DESIGN.md)
- **What it looks like:** [docs/face-preview.jpg](docs/face-preview.jpg) and the screenshots in [docs/screens](docs/screens)

Everything is built with code: the salon, runway, screens and faces. You don't need to upload any images or models.

---

## 1. Play it in Roblox Studio (5 minutes)

1. Install **Roblox Studio** (free): https://create.roblox.com
2. Download **`GlowUpSalon.rbxlx`** from this folder and double-click it (or use Studio's **File → Open from File**).
3. Press **▶ Play** (F5).

The salon and runway build themselves when the game starts. In Studio you automatically own every Game Pass, so you can try the VIP items (turn this off with `STUDIO_OWNS_ALL_PASSES` in `Config`).

**Test with friends inside Studio:** Test tab → Clients and Servers → pick 2–3 players → Start. Each window is a different player, so you can try the voting.

**Coins look high in Studio?** Studio pretends you own the 2x Coins pass too, so coins double.

**Want the round shorter while testing?** Open `ReplicatedStorage > Shared > Config` and change `MAKEOVER_SECONDS` (it's `5 * 60`).

## 2. Put it on Roblox so anyone can play

On Roblox, nobody "downloads" a game. Once it's **public**, anyone can find it and play on phone, tablet, computer or Xbox.

1. In Studio: **File → Publish to Roblox**. Give it a name, description and icon.
   - **Use a parent's account** (or a Roblox Group the parent owns). Robux earnings and payouts go to the account owner. Roblox may ask that account to verify its email, phone or ID before the game can be public or sell things.
2. **Game Settings → Security → turn on "Enable Studio Access to API Services".** This lets coins and unlocks save.
3. At **create.roblox.com → your game**, fill out the **Maturity & Compliance questionnaire**. Roblox requires it before the game can be public.
4. Set the game to **Public**.

## 3. Turn on Robux sales

1. At **create.roblox.com → your game → Monetization**, create these.

   **Passes** (one-time purchases that last forever):

   | Name | Suggested price |
   |---|---|
   | VIP Glam Kit | 199 |
   | 2x Coins | 149 |
   | Runway Star | 99 |

   **Developer Products** (can be bought again and again):

   | Name | Suggested price |
   |---|---|
   | Super Soap | 15 |
   | 500 Coins | 49 |
   | 2000 Coins | 149 |

2. Copy each item's **ID number** into `ReplicatedStorage > Shared > Config` (`Config.GamePasses` and `Config.DevProducts`).
3. **File → Publish to Roblox** again.

Until an ID is filled in, that item shows **"Soon!"** in the shop, so it's safe to publish before setting these up.

## 4. Add sounds and music (optional)

The game is quiet until you pick sounds. In Studio, open **Toolbox → Audio** (or the Creator Store), find sounds you like, then right-click → **Copy Asset ID**. Paste each one into `Config.Sounds`:

```lua
Config.Sounds = {
	Click = "rbxassetid://1234567",   -- tapping buttons
	Sparkle = "rbxassetid://...",     -- dirt comes off
	Cheer = "rbxassetid://...",       -- winning, level up, daily gift
	MakeoverMusic = "rbxassetid://...",
	RunwayMusic = "rbxassetid://...",
	-- also: Pop, Scrub, Camera
}
```

Empty ones are skipped.

## 5. Change the game

All the code is in Studio under:

| Where | What it does |
|---|---|
| `ReplicatedStorage > Shared > Config` | Timer, coin rewards, Game Pass / product IDs |
| `ReplicatedStorage > Shared > Catalog` | **Every hairstyle, color, makeup, outfit and theme.** Add new ones here: name, color, price, tags |
| `ReplicatedStorage > Shared > Clients` | Customer names, skin tones, and "came from the shop" stories |
| `ReplicatedStorage > Shared > LookRenderer` | How faces, hair and outfits are drawn |
| `ReplicatedStorage > Shared > Scoring` | How the judges give stars |
| `ServerScriptService > Server` | Round timer, fashion show, saving, shop |
| `StarterPlayer > StarterPlayerScripts > Client` | All the screens players see |

**Easy first change:** add a new lipstick. In `Catalog`, copy a line like

```lua
item({ id = "lip_coral", name = "Coral", color = rgb(255, 120, 90), tags = { "bright" } }),
```

and change the `id`, `name` and color. Add `price = 50` to make it cost coins, or `pass = "VIP"` to make it VIP-only.

### For developers (optional): edit with VS Code + Rojo

The source files live in `src/` and are synced into Studio with [Rojo](https://rojo.space) 7.

```bash
rojo serve                                  # live-sync into Studio (install the Rojo Studio plugin)
rojo build -o GlowUpSalon.rbxlx             # rebuild the place file after changing src/
```

If you edit scripts directly in Studio instead, save from Studio. `GlowUpSalon.rbxlx` here won't update by itself.

### Play-test without Studio (optional)

`tools/playtest/run.sh` runs the real game scripts in a small fake Roblox engine: a server and two players, a full round (wash, styling, shop, runway, voting, results), purchases, leaving and rejoining, and 15 minutes of rounds. It fails if any script errors. `./run.sh --screens` also saves screenshots and 3D renders (needs Node + Playwright). It's a safety net, not a replacement for pressing Play in Studio.
