# 5 Minute Glow Up Salon: Game Design

**Pitch:** Customers walk into your salon straight from their jobs at the shop, covered in grease, mud, paint and frosting. You get **5 minutes** to wash their face, do their hair, makeup and nails, and dress them for the fashion show. Then they walk the runway, everyone cheers, and the best stylist wins.

**Made for:** girls around 6–10. That means few words, big buttons, lots of happy feedback, and nothing that shames a player in front of others.

![Looks](docs/face-preview.jpg)

| Washing | Makeup | Nails |
|---|---|---|
| ![](docs/screens/01-wash.jpg) | ![](docs/screens/02-makeup.jpg) | ![](docs/screens/03-nails.jpg) |
| **Outfit colors & patterns** | **Halloween items** | **On a phone** |
| ![](docs/screens/04-outfit-colors.jpg) | ![](docs/screens/05-halloween-items.jpg) | ![](docs/screens/06-phone.jpg) |
| **Runway (camera follows)** | **Halloween runway** | **Christmas runway** |
| ![](docs/screens/07-runway.jpg) | ![](docs/screens/08-halloween.jpg) | ![](docs/screens/09-christmas.jpg) |
| **Podium** | **Results** | **Gift calendar** |
| ![](docs/screens/10-podium.jpg) | ![](docs/screens/11-results.jpg) | ![](docs/screens/12-gift-calendar.jpg) |
| **Look Book** | **Shop** | |
| ![](docs/screens/13-lookbook.jpg) | ![](docs/screens/14-shop.jpg) | |

*These pictures come from the play-test tool (`tools/playtest`), not Roblox Studio. In Roblox, lighting, fonts and 3D look a little different.*

## Tori's ideas → game features

| Tori said | In the game |
|---|---|
| Makeup game | 💄 Makeup tab: eyeshadow, lashes, blush, lipstick. Plus a 💅 Nails station with polish and nail art |
| Do their hair / you get to do their hair too | 💇 11 hairstyles and 20 hair colors (some only during holidays). Clients show up with **messy** hair you have to fix |
| They come in from the shop dirty, so they have to wash their face | Every client says where they've been ("I fixed cars at the auto shop all day. I'm SO greasy! 😫"). Rub the splats off with 🧽 Soap (✨ pops), then 🚿 Rinse the bubbles. The game switches tools for you |
| Pay to get extra stuff | Coins you earn unlock looks for free. Robux packs add extra looks and fun effects. Nothing paid is needed to win |
| Then you do a fashion show | Clients walk a 3D runway under a balloon arch. The camera follows them, photographers flash, and everyone taps emoji cheers and hearts |
| You only get 5 minutes to do everything | A "5 minutes! GO! 💨" splash, then one timer for the whole makeover. It turns red and pulses in the last 30 seconds |

## What makes it fun (and easy for little kids)

- **The client reacts.** Their mouth goes from a frown 😫 (dirty) to a smile, then a big grin 😁. They talk ("That tickles!", "Perfect for Halloween Party! 😍"). The **Happy 💖💖💖🤍🤍** meter fills up as the look gets better.
- **⭐ theme stars** mark items that match the show's theme, so kids don't need to read. Every theme can be matched with free items (the play-test checks this).
- **A glowing "do this next" tab**, plus a checklist that can be tapped.
- **Every card is a preview:** the client's own face wearing that item.
- **🎨 Pick your own outfit color** (20 colors) and a pattern (dots, stripes, hearts, stars, flowers).
- **💅 Nails:** the left panel turns into the client's hand. Each nail sparkles as it's painted.
- **Kind by design:**
  - Votes are 💖 / 💖💖 / 💖💖💖, so nobody can give 1 star.
  - Everyone's client is shown washed and smiling on the big screen and podium. The judges' tips are private.
  - Results list the top 3 plus your own look, never a public last place.
- **Safe social play:** emoji cheers and heart votes only. There's no typing.
- **Something to do while waiting:** "🌸 Spritz perfume!" makes the client giggle.

## Reasons to come back

- **🎁 7-day gift calendar:** coins on days 1–6 and a special accessory on day 7 (Golden Bow, Rainbow Headband, Pearl Earrings). Missing a day **pauses** it and never resets it.
- **🎯 Weekly goal:** play 5 shows in a week to win a hair clip (🍀 🦄 🌈 🍓).
- **⭐ Stylist levels** (every 5 stars). Some levels unlock items: Butterfly Clip (Lv 2), Cotton Candy hair (Lv 3), Bubblegum Gloss (Lv 4), Star Dress (Lv 5), Rainbow Shimmer (Lv 6), Star Halo (Lv 8). Titles go from Newbie Stylist to Legendary Stylist.
- **💞 Regular clients:** clients you've styled come back ("Hi again! It's me, Amara!"). Their 3rd, 5th and 10th visits make them best friends and give bonus coins.
- **📖 Look Book:** your last 24 finished looks are saved, like a photo album.
- **🎃 🍂 🎄 Holiday events** (turn on by date):

  | Event | Dates |
  |---|---|
  | Halloween | Oct 10 – Nov 2 |
  | Harvest Festival | Nov 3 – 30 |
  | Christmas | Dec 1 – 31 |

  Each event brings:
  - a holiday fashion-show theme (about half the rounds)
  - about 12 limited items: some free, some for coins, and VIP gowns
  - holiday client stories (pumpkin goo, pie flour, gingerbread)
  - decorations and lighting: pumpkins, bats and ghosts; autumn trees and hay bales; Christmas trees, presents and falling snow

  Items a player unlocked during an event are theirs to keep.

## Round loop (everyone in the server plays together)

1. **Intermission (20s):** next theme, event banner, weekly goal and a 5-step how-to card. Players can open the Shop or Look Book.
2. **Makeover (5:00):** each player gets their own dirty client, with tabs 🧼 Wash, 💇 Hair, 💄 Makeup, 💅 Nails, 👗 Outfit, ✨ Extras. If every stylist taps **I'm Done!**, the show starts early.
3. **Fashion Show (~9s per look):** the client walks the runway and twirls. Other players vote with hearts (+2 coins for voting), and anyone can tap emoji cheers.
4. **Results (15s):** the top 3 stand on the podium. Each player gets a private card with their stars, coins and judge tips, plus a confetti pop-up.

## Scoring (out of 5 stars)

| Part | Points |
|---|---|
| Face washed (all dirt gone) | 1 |
| Hair styled (not messy) | 0.75 |
| Hair color matches theme | 0.5 |
| Makeup applied (4 kinds) | 1 |
| Makeup colors match theme | 0.75 |
| Outfit chosen / outfit or 🎨 color matches theme | 0.5 / 0.5 |
| Bonus: nails painted / nails match, face art, accessory, accessory matches | up to 1.25 |

Forgot to rinse the bubbles? −0.2. The final score is the average of the judges and the players' heart votes, or the judges alone if nobody voted.

## Coins

- Start with 100. The gift calendar gives 30–80 coins a day.
- Every show: 20 + 10 per star, +10 for a spotless wash.
- Placing (2+ players): 1st +50, 2nd +30, 3rd +15.
- +2 for each look you vote on. +25 when a regular becomes a best friend.

About 170 items: 72 everyday items are free, 58 cost 30–150 coins, 21 come in Robux packs, and 35 are holiday items that come and go.

## Monetization (kid-friendly, follows Roblox rules)

No loot boxes or random paid items. Every purchase shows exactly what you get, nothing paid speeds up or skips play, and every theme can be matched with free items.

| Type | Item | What it does | Suggested price |
|---|---|---|---|
| Game Pass | 👑 VIP Glam Kit | Rainbow & Galaxy hair, Royal Updo, Mermaid Waves, Galaxy Glitter, Starry Lashes, Golden Glam lips, Rainbow Chrome nails, Rhinestones, Royal Crown, Golden Gala & Galaxy gowns, holiday VIP gowns (Midnight Witch, Sugar Plum Fairy, Candy Cane hair), VIP badge on the runway | 199 R$ |
| Game Pass | 👸 Princess Pack | Ice Ball Gown, Rose Gown, Princess Curls, Rose Gold hair, Princess Tiara, Pink Gems | 149 R$ |
| Game Pass | 🪙 2x Coins | Double coins every show | 149 R$ |
| Game Pass | 🌟 Runway Star | Confetti cannons + sparkles when your client walks | 99 R$ |
| Game Pass | 🫧 Rainbow Bubbles | Washing makes rainbow bubbles (just for fun) | 49 R$ |
| Dev Product | 💰 500 Coins | Coins | 49 R$ |

New packs are easy to add: give items `pass = "PackName"` in `Catalog` and add the pass ID to `Config.GamePasses`. Good next packs are Mermaid Lagoon, Winter Princess and Halloween Costumes. Private servers (free or cheap) are great for sleepovers.

## Ideas for version 2

- Co-op "Best Friend Mode": two stylists on one client
- Your own salon to decorate with coins
- Real 3D hair and dresses on the runway models (needs uploaded meshes)
- Voice clips for the client ("Ewww!", "I LOVE it!") for kids who can't read yet
- Photo mode: save a picture card with frames
- Client of the Day requests ("Make me look like a mermaid!")
