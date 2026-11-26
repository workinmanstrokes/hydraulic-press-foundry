# Hydraulic Press & Foundry

**Crush scrap, melt it, cast it, sell it.**

An Android shop simulation in Godot 4 (GDScript). You run a small workshop:
buy scrap, crush it in the hydraulic press, melt it in the furnace, cast it
into a finished product, sell it to a customer, earn coins, and upgrade the
press and furnace. Melting and casting are not optional — every sale depends
on the foundry. That is what makes this different from a Hydraulic Press
Pocket clone, where pressing alone is the whole game.

This build is the greybox prototype ordered after the game tester scored
the previous build 2.0/10 (F): one press, one furnace, five starter
materials, one shop sale, and one documented loop — no extra machines,
modes, factory automation, visuals, or monetization yet.

## The loop (one page)

```
Customer order → Buy scrap → Press it → Melt it → Cast product
    → Sell it → Earn coins → Upgrade press / furnace → Next order
```

1. **Customer order** — The Orders tab shows a customer, the product they
   want, and the payout before any work starts. Accepting an order locks
   that product in as the goal. Only one active order at a time in the
   prototype.
2. **Buy scrap** — The Scrap Market lists scrap by material and cost.
   Tap a material to buy one unit if you can afford it. It goes into
   inventory.
3. **Press** — Load one unit of scrap into the press and tap PRESS.
   The press runs a timed cycle with a visible progress bar. When it
   finishes, the scrap becomes crushed scrap.
4. **Melt** — Move the crushed scrap to the furnace and tap MELT. The
   furnace runs a timed cycle. When it finishes, you have molten metal.
5. **Cast** — Tap CAST to pour the molten metal into the finished product
   the customer ordered. Casting is instant once melting is done, but it
   only works if the molten metal matches the ordered product.
6. **Sell** — The Shop tab sells the finished product for coins and
   completes the order. Coins are added immediately and the next order
   appears.
7. **Upgrade** — Spend coins in Upgrades to cut press/furnace cycle time
   (press level) or increase output value (furnace level). Upgrades apply
   to every later job.

Save: coins, inventory, orders, and upgrade levels persist locally
between sessions (Godot `user://save.json`).

## First 10 minutes — exact timings and prices

Start: **100 coins**, press level 1, furnace level 1, no inventory.
Starter materials in the prototype: Scrap Iron, Scrap Copper,
Scrap Aluminum, Scrap Steel, Scrap Brass. Full v1 list: `data/content.csv`
(14 materials/products, locked before art is added).

| Time | What happens | Coins |
| --- | --- | --- |
| 0:00–0:30 | First order arrives: 1× Iron Ingot, payout 25. Read the order. | 100 |
| 0:30–1:00 | Buy 1× Scrap Iron in the Scrap Market. | 100 → 90 |
| 1:00–1:04 | Press Scrap Iron (4 s at level 1) → crushed scrap. | 90 |
| 1:04–1:10 | Melt crushed scrap in the furnace (6 s at level 1) → molten iron. | 90 |
| 1:10–1:15 | Cast molten iron → 1× Iron Ingot. Tap Sell. | 90 → 115 |
| 1:15–2:00 | Second order: 1× Copper Ingot, payout 35. Buy Scrap Copper (15). | 115 → 100 |
| 2:00–2:05 | Press Scrap Copper (5 s) → crushed copper. | 100 |
| 2:05–2:12 | Melt (7 s) → molten copper. Cast → Copper Ingot. Sell. | 100 → 135 |
| 2:12–3:30 | Third order: 1× Aluminum Ingot, payout 28. Buy Scrap Aluminum (12), press (3 s), melt (5 s), cast, sell. | 135 → 151 |
| 3:30–5:00 | Fourth order: 1× Steel Beam, payout 50. Buy Scrap Steel (20), press (6 s), melt (8 s), cast, sell. | 151 → 181 |
| 5:00–6:30 | Fifth order: 1× Brass Gear, payout 45. Buy Scrap Brass (18), press (5 s), melt (7 s), cast, sell. | 181 → 208 |
| 6:30–8:00 | Sixth order: Iron Ingot again (25). Repeat the iron cycle. | 208 → 223 |
| 8:00–9:00 | Upgrade press to level 2 (cost 75): press time ×0.85 on all later jobs. | 223 → 148 |
| 9:00–10:00 | Seventh order: Copper Ingot (35). Press now ~4 s, melt 7 s. Sell. | 148 → 168 |

Net after 10 minutes: **168 coins, press level 2, furnace level 1**,
seven orders completed, no ads, no IAP, no paywall — monetization is
defined only after this loop retains in playtesting.

Unlocks: completing the 2nd order unlocks Scrap Tin in the market, and
every 2 completed orders after that unlocks the next material from
`data/content.csv`, up to all 14. Orders also grow with the market — a
newly unlocked material's product can be the next customer order.

Upgrade costs (v1): press level 2 = 75, level 3 = 150, level 4 = 300
(each level: press time ×0.85). Furnace level 2 = 100, level 3 = 200,
level 4 = 400 (each level: +10% sell price on cast products).

## Progression — unlocks and the reason to return

The prototype's replay hook is material unlocks, not just bigger numbers:

- **New scrap every 2 completed orders** — the market starts with the
  five starter materials and grows one row at a time (Scrap Tin,
  Scrap Zinc, Scrap Lead, Scrap Nickel, Scrap Bronze, Scrap Silver,
  Scrap Gold, Scrap Titanium, Scrap Wire) until all 14 are open.
- **New products and payouts** — each unlocked material casts a new
  product with its own sell price, so later orders pay more (Gold Bar
  sells for 180, against Iron Ingot's 25).
- **Press and furnace tiers** — four levels each, with the costs above.
  Press tiers cut cycle time; furnace tiers raise sell prices.
- **Orders completed is saved** — unlocks, coins, inventory, and upgrade
  levels all persist in `user://save.json`, so progress survives
  closing the app.

## Crush and melt feedback (greybox)

This genre lives or dies on crush/melt feedback, so the prototype
already gives each cycle a visible payoff, before any art or sound:

- **Press/melt progress bars** with a percentage readout while a cycle
  runs, so the player always sees the job state.
- **Completion flash** — when a press or melt cycle finishes, its bar
  flashes bright and fades back (`pulse_bar` in `scripts/workshop.gd`).
- **Status line** narrating every step ("Pressed! Crushed Scrap Iron
  is ready for the furnace.") so a stall always has a next action.
- **Large tap targets** — PRESS / MELT / CAST / SELL are full-width
  buttons; the market is a tap-to-buy list with the price on the row.
- **Sound design (to be added after the greybox playtest, not faked
  here):** a low crush thud on press completion, a melt hiss while the
  furnace runs, and a metallic clink on cast. No audio files ship in
  this build — the visual flash is the feedback until the sounds are
  recorded and the loop is proven to retain.

## Features

- Customer order queue showing the required product and payout before work starts
- Scrap market to buy scrap with coins, with per-material cost shown
- Hydraulic press that crushes loaded scrap on a timed cycle with visible progress
- Furnace that melts crushed scrap into molten metal on a timed cycle
- Casting that pours molten metal into a finished product matching a customer order
- Shop sale that sells the finished cast product for coins and completes the order
- Press and furnace upgrades that spend coins to reduce cycle time or increase output
- Material unlocks: every 2 completed orders opens the next material from the locked v1 list, up to all 14
- Crush/melt completion flash on the station progress bars, plus a status line narrating each step
- Locked v1 content of 14 materials and products with fixed cost, sell price, press time, and foundry time (`data/content.csv`)
- Local save persisting coins, inventory, orders, and upgrade levels between sessions
- Greybox workshop UI with clear timers, large tap targets, and job states — no extra machines, modes, or automation

## How to run

Requires Godot 4.x (4.2 or later) and, for Android, the Godot Android
export templates.

1. Open `project.godot` in Godot 4.
2. Press F5 (or the Play button) to run the greybox prototype on desktop.
3. For Android: install the export templates, then
   Project → Export → Android → Export Project, and install the APK on
   the playtest phone.

## Playtest checklist (low-end Android phone)

Record before adding visuals or monetization (use the blank recording
sheet in `docs/playtest-log.md` — no results are claimed yet):

- Load time from tap to workshop visible (target: under 5 s)
- Frame drops during press / melt cycles
- Tap failures (taps that did nothing, or the wrong button)
- Where players stall: which step they stop at, and for how long
- Whether the first 10-minute loop above completes without confusion

Fix the loop first. Only after it retains, define monetization
(paid vs free, ads, IAP upgrade pricing tied to `data/content.csv`).

## Performance, devices, and stability (Android)

- **Offline-first:** the game makes no network calls. Coins, inventory,
  orders, unlocks, and upgrades live in a local `user://save.json`; it
  plays fully offline and never stalls waiting on a server.
- **Low-end target:** `gl_compatibility` renderer, 720×1280 portrait
  viewport, greybox panels only — no textures, particles, or shaders in
  the prototype, so frame drops should come from logic, not rendering,
  and are easy to find in the playtest log.
- **Build settings:** Android export targets min SDK 21 / target SDK 34,
  arm64-v8a only (`export_presets.cfg`); package
  `com.workinmanstrokes.hydraulicpressfoundry`, version 0.1.0.
- **Stability:** one press and one furnace, one active order, no
  background services or timers outside the two job cycles; a cycle can
  never run twice (press/melt buttons ignore taps while running).
- **Playtest device:** still to be named — the specific low-end Android
  phone and Android version go in `docs/playtest-log.md` before the run.

## Monetization — decided only after the loop retains

No price, ads, or IAP are set in this build, on purpose. The decision
gate is the playtest: if the first-10-minutes loop retains, the options
below are priced against the economy in `data/content.csv` — not before.

- **Free with ads:** interstitial only between orders, never during a
  press/melt cycle; rewarded ad for a coin bonus.
- **Paid (no ads):** one-time price, decided against the 10-minute coin
  curve (a player earns ~68 net coins in 10 minutes from 100 start).
- **IAP upgrade packs:** priced against upgrade costs, not invented —
  e.g. a pack that buys a press tier (75 / 150 / 300 coins) or a furnace
  tier (100 / 200 / 400 coins) must cost less in real money than the
  grind it skips, or it is not worth selling.

## Project layout

- `scenes/workshop.tscn` — greybox workshop scene (press, furnace, casting station, shop UI)
- `scripts/workshop.gd` — workshop controller for the order → buy → press → melt → cast → sell loop, plus unlocks and crush/melt feedback
- `scripts/economy.gd` — costs, sell prices, timers, coins, press/furnace upgrades
- `data/content.csv` — locked v1 content list (14 materials/products)
- `docs/playtest-log.md` — blank low-end Android playtest recording sheet (load time, frame drops, tap failures, stalls)
- `export_presets.cfg` — Android export preset for APK testing

## Open questions

- What engine/codebase is the existing Android project built in — continue it, or rebuild the greybox in Godot 4? (This prototype assumes Godot 4.)
- Which specific low-end Android phone and Android version is the playtest target?
- Is v1 free with ads and IAP or paid? To be decided only after the prototype retains in playtesting.
