# Meadow Mahjong (working name)

Native SwiftUI iOS game for iPhone and iPad: classic mahjong solitaire in the style of Vita
Mahjong, Match Mahjong and Vigor Mahjong, set in an animated nature scene,
with combo praise ("Good!" … "Unbelievable!") on quick matches. Planning docs
are in `replica/`.

## Open it on the Mac

```bash
brew install xcodegen
cd MeadowMahjong
xcodegen generate
open MeadowMahjong.xcodeproj
```

Then in Xcode: pick your team in **Signing & Capabilities**, change the
bundle ID from `com.example.MeadowMahjong` (in `project.yml`, so it survives
regeneration), and run on an iPhone, an iPad or a simulator. Run the tests with ⌘U.

## What's where

| folder | what |
| --- | --- |
| `Engine/` | tiles, free rule, solvable deals, shuffle, the 12 layouts, level and daily configs. No UI |
| `Game/` | `GameModel` (taps, combo, praise, hint, shuffle, undo, win), the board, tile art, game screen and its overlays |
| `Effects/` | the appreciation effects: match burst, praise word, sun rays, confetti, combo meter |
| `Nature/` | the six animated scenes, drawn in one `Canvas` |
| `Home/`, `Daily/` | home screen, settings and scene picker, Daily Challenge calendar |
| `Services/` | saved progress (UserDefaults), sound (synthesised chimes) and haptics |

No image or audio assets: tiles, scenes and sounds are all made in code.
