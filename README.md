# UltrasEuropa

A native iOS app for European football ultras fan culture. Create a character
and rise through the ranks — from a regular fan to Capo — by attending
matches, standing in the ultras section, running pyro displays, learning
chants, and contributing to tifo displays.

## Project layout

```
UltrasEuropa/
├── project.yml        XcodeGen spec — generates UltrasEuropa.xcodeproj (not committed)
├── Core/               Local Swift package: pure models + progression logic (no SwiftUI/SwiftData)
│   ├── Sources/UltrasEuropaCore/
│   └── Tests/UltrasEuropaCoreTests/
└── App/                 The iOS app target: SwiftUI views, SwiftData persistence, bundled content
    ├── Persistence/
    ├── Resources/Content/   Bundled JSON: clubs, groups, matches, chants, tifo, catalogs
    ├── ViewModels/
    ├── Views/
    └── Support/
```

`Core/` has zero dependency on SwiftUI/SwiftData/UIKit, so it builds and
tests on any machine with the Swift toolchain — including Linux, no Xcode
required. All rank/XP/progression math and JSON content decoding lives there
and is unit tested. The `App/` target is a thin SwiftUI + SwiftData layer on
top of it, and requires Xcode/macOS to build and run.

## Building and running (on a Mac)

1. Install [Xcode 15+](https://developer.apple.com/xcode/) and
   [XcodeGen](https://github.com/yonaskolb/XcodeGen):
   ```sh
   brew install xcodegen
   ```
2. Generate the Xcode project (this regenerates `UltrasEuropa.xcodeproj` from
   `project.yml` — the `.xcodeproj` itself is gitignored, not committed):
   ```sh
   xcodegen generate
   ```
3. Open it and run:
   ```sh
   open UltrasEuropa.xcodeproj
   ```
   Select an iPhone Simulator (iOS 17+) and press Cmd+R.

Re-run `xcodegen generate` any time files are added/removed under `App/` or
`Core/`, or `project.yml` changes.

## Running Core's tests

The progression/rank logic is plain Swift and can be tested independently of
Xcode:

```sh
cd Core
swift test
```

This also runs in CI on every push via `.github/workflows/core-tests.yml`.

## Manual verification checklist (run through this on a Simulator)

- [ ] First launch shows character creation (name + favorite club)
- [ ] After creating a character, Dashboard shows rank "Regular", 0 XP, all stats at their base value
- [ ] Attending a match (with "Sit in Ultras Stand" / "Do Pyro" toggled) increases XP and the relevant stats
- [ ] Participating in a chant and contributing to a tifo each award XP/stats
- [ ] Completing a challenge/task awards XP
- [ ] Rank only advances once XP **and** the rank's gating requirements (activity variety / achievements — see below) are met — it should NOT be possible to reach Capo quickly by repeating one action
- [ ] Achievements unlock and appear under Achievements once their criteria are met
- [ ] Inventory items appear as they're earned
- [ ] Force-quit and relaunch the app — character, stats, rank, inventory and achievements all persist
- [ ] Club directory, match schedule/results, chants library, and tifo gallery all display the 5 bundled placeholder clubs correctly

## Replacing the placeholder content

All club/group/match/chant/tifo/catalog data lives as JSON under
`App/Resources/Content/`. The 5 clubs shipped in this repo (Rotstadt,
Portovento, Nordhavn, Cantera, Zvijezda) are **intentionally fictional
placeholders** — swap in real clubs/data by editing those JSON files; no
Swift code changes are required as long as the shape of each entry matches
the existing fields (see `Core/Sources/UltrasEuropaCore/Models/`).

A couple of things to keep in mind when adding real content:
- Real club/competition names are just facts and are fine to use.
- Crests/logos, official color trademarks, and chant lyrics are often owned
  by the club or fan groups — make sure you have the rights to use anything
  you add (images, audio, text) before shipping.
- `crestAssetName` / `imageAssetName` fields can be left `null` — the app
  renders a themed placeholder (a gradient in the club's colors) when no
  asset is provided, so the app works before any real images are added. Add
  real images to `Images.xcassets` and set the matching asset name once you
  have them.

## Progression design

Ranking up is intentionally **not** fast — see
`Core/Sources/UltrasEuropaCore/Progression/ProgressionConstants.swift` for
the full, tunable design: XP costs rise steeply per rank, higher ranks also
require a minimum spread of activity types (not just repeating one action)
and specific achievements to be unlocked, and each activity's XP has a daily
diminishing-returns cap so grinding a single action can't shortcut the
climb.
