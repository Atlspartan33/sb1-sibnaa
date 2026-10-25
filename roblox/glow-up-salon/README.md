# ✨ 5 Minute Glow Up Salon (Roblox)

Tori's dress-up game. Every round has a theme (Superhero, Pirate, Under the Sea, Princess Ball...). You get 5 minutes to walk around the **Dressing Hall** in **your own Roblox avatar** (your own skin and body) and style yourself at six stations: hair, makeup, an outfit, costume pieces from the avatar shop (wings, capes, masks, tails, hats, shoulder buddies), a pet to walk with you, and a runway pose and effect. Then everyone struts the runway in a model's catwalk walk, votes with hearts, and the judges pick the winners.

Playing alone or with one friend? **Style Bots** (🤖 Kiki, Zara and friends) fill the hall up to 3 players: they hang out on the dance floor, walk to the stations and dress for the theme, walk the runway and vote kindly. Anyone can switch them off with the **Style Bots** button on the lobby card. Between rounds the hall has a disco ball, string lights, balloons, a dance floor and a **photo booth** (stand on the gold pad for a 3-2-1 and a polaroid of your look).

- **How the game works and how it makes money:** [GAME_DESIGN.md](GAME_DESIGN.md)
- **What it looks like:** [docs/face-preview.jpg](docs/face-preview.jpg) and the screenshots in [docs/screens](docs/screens)

Everything is built with code: the salon, runway, screens, faces, pets and effects. Hair and costume pieces are real avatar-shop items, loaded by ID when the game starts (the `asset = ...` items in `Catalog`; hairstyles lose their texture so any hair color works). You don't need to upload any images or models.

---

## 1. Play it in Roblox Studio (5 minutes)

1. Install **Roblox Studio** (free): https://create.roblox.com
2. Download **`GlowUpSalon.rbxlx`** from this folder and double-click it (or use Studio's **File → Open from File**).
3. Press **▶ Play** (F5).

The salon and runway build themselves when the game starts. In Studio you automatically own every Game Pass, so you can try the VIP items (turn this off with `STUDIO_OWNS_ALL_PASSES` in `Config`).

**Test with friends inside Studio:** Test tab → Clients and Servers → pick 2–3 players → Start. Each window is a different player, so you can try the voting.

**Coins look high in Studio?** Studio pretends you own the 2x Coins pass too, so coins double.

**Want to see the Halloween, Harvest Festival or Christmas event before its date?** Set `Config.FORCE_EVENT = "halloween"` (or `"thanksgiving"`, `"christmas"`) and press Play. This only works in Studio. In the live game, events always turn on by date.

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

   | Name | Config key | Suggested price | What's in it |
   |---|---|---|---|
   | VIP Glam Kit | `VIP` | 199 | Starlight Royal Gown, Rainbow Sequin Dress, Royal Updo, Mermaid Waves, Rainbow Wings, crown, galaxy and rainbow hair, gold makeup |
   | Princess Pack | `Princess` | 149 | Pastel Summer Gown, Enchanted Rainbow Gown, Princess Curls, Rose Gold hair, tiara, pink gems, Unicorn pet |
   | Fashion Week Pack | `FashionWeek` | 99 | 6 real outfits: Pink Ribbon, Pink Ruffle, Rainbow Heart, Snow Crystal, Pastel Dream, Designer Puffer |
   | Pet Palace | `PetPalace` | 149 | Winged Bunny, Glitter Kitty, Baby Pegasus, Bubble Turtle |
   | 2x Coins | `DoubleCoins` | 149 | Double coins after every show |
   | Runway Star | `RunwayStar` | 99 | Confetti cannons and sparkles on your runway walk |

   **Developer Products** (can be bought again and again):

   | Name | Config key | Suggested price |
   |---|---|---|
   | 500 Coins | `CoinsSmall` | 49 |
   | 1,500 Coins | `CoinsMedium` | 99 |
   | 4,000 Coins | `CoinsLarge` | 199 |

   **Free players get plenty:** every theme and every Judge's Wish can be done with free items, the 11-piece free Real Clothes closet covers every theme, and 13 big dream outfits (350 to 1,000 coins) are earned by playing. Pack items show a 🔒 badge; tapping one mid-round only says "ask a grown-up in the Shop after the show", so there is never a Robux prompt during a round.

2. Copy each item's **ID number** into `ReplicatedStorage > Shared > Config` (`Config.GamePasses` and `Config.DevProducts`).
3. **File → Publish to Roblox** again.

Until an ID is filled in, that item shows **"Soon!"** in the shop, so it's safe to publish before setting these up.

## 4. Add sounds and music (optional)

Sound makes a big difference for young kids. The game already plays music while styling and on the runway, a chime when dirt comes off and when speech bubbles pop up, a soft splash when rinsing, and a jingle for celebrations. These are free sounds from Roblox's own audio tutorials, plus the splash that's built into every Roblox player. Buttons make a soft tap and the photo booth and runway use Roblox's own camera shutter. Change how loud each one is in `Config.SoundVolumes`. Only scrubbing is still silent: pick free sounds from the Creator Store, which has thousands of sounds and licensed music any game may use.

| Config key | Search the Toolbox for |
|---|---|
| `Click` | "pop", "bubble pop" |
| `Pop` | "cute pop", "boing" |
| `Scrub` | "scrub", "bubbles" |
| `Sparkle` | "sparkle", "chime", "twinkle" |
| `Cheer` | "kids cheer", "yay", "applause" |
| `Camera` | "camera shutter" |
| `MakeoverMusic` | music: "happy", "pop", "cute" |
| `RunwayMusic` | music: "fashion", "runway", "dance" |

 In Studio, open **Toolbox → Audio** (or the Creator Store), find sounds you like, then right-click → **Copy Asset ID**. Paste each one into `Config.Sounds`:

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

Empty ones are skipped. If a sound doesn't play in Studio, check the Output window. Replace any sound Roblox says can't be loaded.

## 5. Change the game

All the code is in Studio under:

| Where | What it does |
|---|---|
| `ReplicatedStorage > Shared > Config` | Timer, coin rewards, Game Pass / product IDs |
| `ReplicatedStorage > Shared > Catalog` | **Every hairstyle, skin tone, makeup, outfit, costume piece, pet, pose, effect and theme.** Add new ones here: name, color, price, tags. A costume piece is any avatar-shop accessory: add `asset = <its ID>` |
| `ReplicatedStorage > Shared > Avatar` | Builds the 3D character: body, avatar-shop hair (recolored), the face, outfit, skirt, costume pieces, effects and poses |
| `ReplicatedStorage > Shared > Stations` | Where the six Dressing Hall stations are and which menu each opens |
| `ReplicatedStorage > Shared > Pets` | The pets (Bean the Boston terrier, kitty, bunny, dino, dragon, unicorn), built from shapes |
| `ReplicatedStorage > Shared > Clients` | Your name and skin tone for each round (plus the old salon customers, kept for a future salon mode) |
| `ReplicatedStorage > Shared > Events` | Holiday event dates (Halloween, Harvest Festival, Christmas) |
| `ReplicatedStorage > Shared > LookRenderer` | How faces, hair and outfits are drawn |
| `ReplicatedStorage > Shared > Scoring` | How the judges give stars |
| `ServerScriptService > Server` | Round timer, fashion show, saving, shop |
| `StarterPlayer > StarterPlayerScripts > Client` | All the screens players see |

**Easy first change:** add a new lipstick. In `Catalog`, copy a line like

```lua
item({ id = "lip_coral", name = "Coral", color = rgb(255, 120, 90), tags = { "bright" } }),
```

and change the `id`, `name` and color. Then add one of these if you want:

- `price = 50` to make it cost coins
- `pass = "VIP"` to make it VIP-only
- `level = 4` to unlock it at stylist level 4
- `event = "christmas"` to make it a holiday item

### For developers (optional): edit with VS Code + Rojo

The source files live in `src/` and are synced into Studio with [Rojo](https://rojo.space) 7.

```bash
rojo serve                                  # live-sync into Studio (install the Rojo Studio plugin)
rojo build -o GlowUpSalon.rbxlx             # rebuild the place file after changing src/
```

If you edit scripts directly in Studio instead, save from Studio. `GlowUpSalon.rbxlx` here won't update by itself.

### Play-test without Studio (optional)

`tools/playtest/run.sh` runs the real game scripts in a small fake Roblox engine: a server and two players, a full round (wash, styling, nails, shop, runway, voting, results), purchases, cheating attempts, leaving and rejoining, all three holiday events, the weekly goal, and half an hour of rounds. Then four "monkey" players tap random buttons and rub random spots for an hour of game time, to catch anything that breaks when kids do unexpected things. It also checks that every theme can be matched with free items. It fails if any script errors. `./run.sh --screens` also saves screenshots and 3D renders (needs Node + Playwright). It's a safety net, not a replacement for pressing Play in Studio.
