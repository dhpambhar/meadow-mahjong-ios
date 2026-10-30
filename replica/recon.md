# Recon map: Vita Mahjong + Match Mahjong + Vigor Mahjong (iOS)

Scope: the core loop that all three share: classic mahjong solitaire (match two
identical free tiles until the board is clear), with level progression, Daily
Challenge, hint, shuffle and undo, combo praise, and a themed background. The
clone's twist is an animated nature background.
For: the user's own App Store game (working name "Meadow Mahjong" until `/replica-brand`).
Date: 2026-10-30

## Sources

| # | source | URL | notes |
| --- | --- | --- | --- |
| 1 | App Store: Vita Mahjong (Vita Studio) | https://apps.apple.com/us/app/vita-mahjong/id6468921495 | 4.9 from 1.8M ratings. Large tiles, Super Combo, free hints, undo and shuffle, Daily Challenge with trophies, offline, special tiles, "Active Mind" levels, no timer. Ads, Remove Ads $5.99, subscriptions $2.99 a week, $5.99 a month, $19.99 a year |
| 2 | App Store: Match Mahjong (WinPlus Games) | https://apps.apple.com/us/app/match-mahjong-tile-game/id6742874143 | 5.0 from 29K ratings. Pair solitaire for seniors, no timer, soft colours, hints, shuffle, Bomb tool, travel themes, puzzle-piece rewards, Win Streak leaderboard, tile skins |
| 3 | App Store: Vigor Mahjong (Doodle Mobile) | https://apps.apple.com/us/app/vigor-mahjong/id6478847787 | 4.8 from 293K ratings. Over 20,000 levels, optional score, no timer, combos for consecutive matches, bonus points for solving without help, daily challenges, several backgrounds and themes |
| 4 | Vita Mahjong review summary (aggregator, low reliability) | https://kimola.com/reports/vita-mahjong-feedback-analysis-master-user-engagement-google-play-en-gb-154911 | players like how relaxing it is and dislike how often ads show |
| 5 | BlueStacks listing for Vigor Mahjong | https://www.bluestacks.com/campaign/com.godlike.vigormahjong/en/ | hints and shuffle, extra points without help, daily challenges |

The App Store screenshots load as images with no captions, so the screen list
below comes from the listings' feature text plus the genre's standard
layout. Rows marked "guess" in the states column weren't seen directly.

## Core loop

Tap two identical **free** tiles (nothing on top, and the left or right side
open) to remove them. Clearing the board finishes the level, then you play the
next one. Quick matches in a row build a combo with praise.

## Screens

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S01 | Home | app launch | start the next level, open Daily | animated background, big "Level N" play button, Daily card, settings button, theme picker | first launch (Level 1), returning, daily already done |
| S02 | Game board | S01 Play, or S03 day | play a level | top bar (back, level label, tiles left), layered tile board, tool bar (Hint, Shuffle, Undo with counts), combo meter, praise text | playing, tile selected, hint showing, no moves left, paused |
| S03 | Daily Challenge | S01 Daily card | one puzzle per day, trophy for each solved day | month calendar, trophy count, Play button | today unsolved, today solved, past day, future day (locked) |
| S04 | Level complete | S02 board cleared | celebrate, show stars, continue | praise headline, stars, stats, Next and Home buttons, confetti | 1, 2 or 3 stars, daily variant (trophy) |
| S05 | No moves left | S02 when no free pair exists | recover | modal with Shuffle (free) and Restart | guess: auto-offered shuffle |
| S06 | Pause / menu | S02 back or pause button | leave or restart | modal: Resume, Restart, Home | — |
| S07 | Settings | S01 gear, S06 | preferences | toggles: sound, haptics, dim blocked tiles, large tiles; background theme | — |
| S08 | Themes / backgrounds | S07 or S01 | pick a background scene | grid of scenes, locked until a level | locked, unlocked, selected |

## Flows

```
F01 Play the next level (the core loop)
    S01 -> S02 -> (match until clear) -> S04 -> Next -> S02
    happy path taps: 1 to start, 2 per match, 1 for Next
    edge: tap a blocked tile (shake, no select), tap a non-matching free tile (selection moves),
          no free pairs left (S05), leave mid-level (progress on that level is not kept)

F02 Use help
    S02 Hint -> two matching free tiles glow
    S02 Shuffle -> remaining tiles re-dealt, still solvable
    S02 Undo -> last pair comes back
    edge: counts hit zero (button disabled, guess: the originals sell more or show an ad)

F03 Daily Challenge
    S01 -> S03 -> Play -> S02 -> S04 (trophy) -> S03 with today ticked
    edge: day already solved (replay allowed, no new trophy), past days playable, future days locked

F04 Combo and praise
    S02 match within a short window of the last one -> combo + 1 -> praise word grows
    ("Good", "Great", "Excellent", "Amazing", "Unbelievable") with a sparkle burst
    edge: a slow match resets the combo, undo doesn't count

F05 Change background
    S01 -> S07/S08 -> pick scene -> S01 background changes
```

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| Tile | characters, bamboo, dots, winds, dragons, nature (flowers, seasons) | free, blocked (dimmed), selected, hinted, matching (flying out), shaking | S02 |
| Tool button | hint, shuffle, undo | enabled with count badge, disabled | S02 |
| Primary button (pill) | large, medium | default, pressed | S01, S03, S04, S05, S06 |
| Praise banner | 5 tiers | entering, idle, leaving | S02, S04 |
| Combo meter | — | counting down, reset | S02 |
| Modal card | pause, no moves, settings | — | S05, S06, S07 |
| Calendar day cell | solved (trophy), today, past, future | — | S03 |
| Stars | 1 to 3 | animating in | S04 |
| Animated nature background | dawn meadow, forest, sunset lake, blossom, night fireflies | — | all |

## Inferred data model

```
TileFace     suit (characters | bamboo | dots | wind | dragon | flower | season), rank
             evidence: classic mahjong set; Vigor "close to the original" tile designs
             confidence: high
Tile         id, face, x, y, z (layer), removed
             evidence: layered layouts on S02
             confidence: high
Layout       name, slots [(x, y, z)], tile count (even)
             evidence: "classic layouts", "hundreds/thousands of boards"
             confidence: high
LevelProgress currentLevel, stars per level, hints, shuffles, undos left
             evidence: level label on S01, help counts on S02
             confidence: medium
DailyRecord  date, solved, best time
             evidence: "Daily Challenge with trophies"
             confidence: medium
Settings     sound, haptics, dimBlocked, theme
             evidence: "multiple backgrounds, sounds and themes"
             confidence: medium
```

Relationships: Layout 1-n Tile (per deal), Level uses one Layout + seed, DailyRecord per date.

## Feature matrix

See `features.csv`. Must: 16, should: 10, could: 5, skip: 5.

## Out of scope (cannot or should not be cloned)

- The Kung Fu Panda collab (licensed DreamWorks IP) and any partner event art.
- The originals' tile art, backgrounds, sounds and names. The clone draws its own tiles and scenes in code.
- Ads, subscriptions and the Remove Ads purchase: business choices for `/replica-launch`, not v1 gameplay.
- Leaderboards and accounts (Win Streak leaderboard needs a server and players).
- "20,000 levels": the clone generates levels from a set of layouts plus a seed, so the count is unlimited but layouts repeat.

## Size

Screens 8, flows 5, entities 6. Hard parts: deals that are always solvable
(including after a shuffle), the 3D tile stack's free rule and hit-testing, and
smooth animation (background + particles + match fly-outs) on older iPhones.
Size: M (a few weeks to polish; the core is a weekend).
