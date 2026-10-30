# Build log

Written on Windows without Xcode. **The Swift code hasn't been compiled or
run yet.** The first build on the Mac is the real check, so expect a few
compile fixes. The layouts and the deal algorithm were checked by running the
same logic in Node (see below).

| ID | date | status | missing | harder than expected |
| --- | --- | --- | --- | --- |
| shell | 2026-10-30 | done (unbuilt) | — | — |
| engine | 2026-10-30 | done (unbuilt, logic checked in Node) | special tiles, Bomb | Twin Peaks first started with only 2 free tiles, so its stacks were flattened |
| S01 Home | 2026-10-30 | done (unbuilt) | — | — |
| S02 Game | 2026-10-30 | done (unbuilt) | — | — |
| iPad | 2026-10-30 | done (unbuilt) | — | menus, bars and cards are capped at phone-like widths; the board grows to fill the screen (tiles up to 130 pt); iPad rotates to any orientation, iPhone stays portrait |
| S03 Daily | 2026-10-30 | done (unbuilt) | — | — |
| S04 Win | 2026-10-30 | done (unbuilt) | — | — |
| S05 Stuck | 2026-10-30 | done (unbuilt) | — | a shuffle can't always help (two matching tiles stacked on each other), so the card falls back to Undo and Restart |
| S06 Pause | 2026-10-30 | done (unbuilt) | — | — |
| S07/S08 Settings and scenes | 2026-10-30 | done (unbuilt) | — | — |

## Layout check (Node port of `Engine/`)

Tile size on a 358 × 560 pt board area (iPhone 15 portrait), and the share of
random deal attempts that finish (the app retries up to 80 times):

| layout | tiles | grid | tile width | free at start | deals that finish |
| --- | --- | --- | --- | --- | --- |
| Seedling | 20 | 4 × 4 | 87 pt | 12 | 89% |
| Lotus | 28 | 6 × 6 | 58 pt | 16 | 94% |
| Clover | 30 | 5 × 5 | 70 pt | 16 | 90% |
| Sunflower | 40 | 6 × 6 | 57 pt | 24 | 84% |
| Butterfly | 44 | 8 × 5 | 44 pt | 17 | 98% |
| Twin Peaks | 44 | 4 × 9 | 47 pt | 20 | 84% |
| River | 50 | 7.5 × 8 | 47 pt | 16 | 100% |
| Pyramid | 56 | 6 × 6 | 57 pt | 24 | 84% |
| Lantern | 66 | 6 × 8 | 52 pt | 34 | 77% |
| Fortress | 82 | 8 × 6 | 43 pt | 26 | 87% |
| Terraces | 122 | 6 × 8 | 52 pt | 10 | 99% |
| Old Oak | 144 | 8 × 9 | 43 pt | 24 | 100% |

## Check on the Mac

1. ⌘U: the engine tests replay every level's own solution for levels 1 to 40.
2. Play level 1. Tap a blocked (dimmed) tile: it shakes. Match two pairs quickly: "Good!" and the combo meter.
3. Match 5 pairs inside 4 s each: "Amazing!" with rays and a petal shower.
4. Clear the board: the headline, stars popping in one by one, confetti, chimes.
5. Finish level 3: the Misty Forest scene unlocks and fades in.
6. Watch the scene on an older iPhone (XS / 11) for frame drops. If needed, lower the particle counts in `Scenery.palette` or the `TimelineView` rate.
7. Silent switch on: no sound. Music playing in another app: it keeps playing.
8. On an iPad simulator, in portrait and landscape: the board fills the screen, and menus and cards stay centred at phone width.
