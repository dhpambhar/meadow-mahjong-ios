# Architecture: working name "Meadow Mahjong"

A rebuild of the core loop shared by Vita Mahjong, Match Mahjong and Vigor
Mahjong (see `recon.md`), with an animated nature background. The name is a
placeholder until `/replica-brand`. Native iOS, offline, no server, no
third-party SDKs. Same setup as GeoStamp: an XcodeGen spec, written on Windows,
built on the Mac.

## Stack

| layer | choice | why |
| --- | --- | --- |
| language / UI | Swift 5 mode, SwiftUI, iOS 17, iPhone and iPad (one universal app) | `@Observable`, `phaseAnimator`, animation completions. All three originals are phone games with simple 2D boards, so SwiftUI is enough and SpriteKit isn't needed |
| background | SwiftUI `Canvas` inside `TimelineView(.animation)` at 30 fps | one draw call per frame for sky, hills, trees, grass, petals, butterflies and fireflies. No image assets, so nothing is copied and the app stays small (the original is 431 MB) |
| tiles | drawn in code (`TileView`, `TileGlyph`): dots and bamboo in `Canvas`, CJK numerals as text, nature tiles as SF Symbols | the originals' tile art is theirs. Classic mahjong symbols are public domain |
| sound | `AVAudioEngine` with bell tones synthesised at runtime, `.ambient` session | no audio files to license. Respects the silent switch and doesn't stop the user's music |
| haptics | `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator` | — |
| storage | `UserDefaults` via `PlayerProgress` | level, stars, solved days, settings. Small enough that SwiftData would be overkill |
| randomness | SplitMix64 seeded generator | level N and day D always deal the same board, so Restart replays the same puzzle |
| tests | Swift Testing | engine rules, solvability, layouts |

## Game engine (`Engine/`)

- **Slot** `(x, y, z)` in half-tile units. A tile covers 2 × 2 half units, so
  layouts can stagger by half a tile.
- **Free rule**: no tile on any higher layer overlaps it (|dx| < 2 and |dy| < 2),
  and the left side **or** the right side has no tile on the same layer
  (dx = ±2, |dy| < 2). Neighbour lists are worked out once per board.
- **Solvable deals**: starting from the full board, pick two random free tiles,
  give them the same face and remove them, and repeat. That removal order is
  a real play order, so every deal can be cleared. It's kept in
  `Board.solution` so the tests can replay it. If it gets stuck, it retries.
- **Shuffle** uses the same algorithm on the tiles that are left, with the
  faces they already have, so a shuffled board can always be finished too.
  (When even that can't work, for example two matching tiles stacked on each
  other, the stuck card offers Undo and Restart instead.)
- **Levels**: 12 handcrafted layouts sized for portrait (8 tiles wide at most,
  from 20 to 144 tiles) in order of size. After level 12, a seeded pick from
  the larger ones. The number of different faces grows with the level
  (`4 + level`, capped at 42), so early levels are easy to scan.
- **Daily**: the seed is the date, played on one of the large layouts with 30 faces.

## Appreciation system

| trigger | effect |
| --- | --- |
| any match | the pair flies together, sparkle and leaf burst, a chime that climbs a pentatonic scale with the combo |
| match within 4 s of the last one | combo + 1, combo meter refills |
| combo 2 / 3 / 4 / 5 / 6 / 7+ | "Good!" / "Great!" / "Excellent!" / "Amazing!" / "Fantastic!" / "Unbelievable!" with a spring pop, gradient lettering, rays from tier 4, petal shower from tier 5 |
| half the tiles cleared (no combo praise at that moment) | "Halfway there!" |
| board cleared | random headline ("Brilliant!", "Wonderful!", …), stars pop in one by one, petal confetti, an arpeggio, a note when a new scene unlocks |
| tap a blocked tile | the tile shakes, soft low tone |

## Screens

`RootView` keeps one `NatureBackground` behind everything, so the animation
never restarts, and switches between Home (S01), Daily (S03) and Game (S02).
Win (S04), stuck (S05) and pause (S06) are overlays on the game. Settings and
scenes (S07, S08) are a sheet.

## Out of v1

Ads, Remove Ads, subscriptions, leaderboard, special tiles, Bomb
tool. See `features.csv`.
