# UltrasEuropa

A native iOS app for European football ultras fan culture. Create a character
and rise through the ranks — from a regular fan to Capo — by attending
matches, standing in the ultras section, running pyro displays, learning
your crew's chants, and contributing to your crew's tifo displays.

## Project layout

```
UltrasEuropa/
├── project.yml        XcodeGen spec — generates UltrasEuropa.xcodeproj (not committed)
├── Core/               Local Swift package: pure models + progression logic (no SwiftUI/SwiftData)
│   ├── Sources/UltrasEuropaCore/
│   │   ├── Models/         Club, League, Match, Rank, CharacterStats, Chant, TifoPhoto, ...
│   │   ├── Progression/    XP/rank/achievement rules
│   │   └── Scheduling/     SeasonScheduleGenerator (see below)
│   └── Tests/UltrasEuropaCoreTests/
└── App/                 The iOS app target: SwiftUI views, SwiftData persistence, bundled content
    ├── Persistence/
    ├── Resources/Content/   Bundled JSON: leagues, clubs, chants, tifo, catalogs
    ├── ViewModels/
    ├── Views/
    └── Support/
```

`Core/` has zero dependency on SwiftUI/SwiftData/UIKit, so it builds and
tests on any machine with the Swift toolchain — including Linux, no Xcode
required. All rank/XP/progression math, the season schedule generator, and
JSON content decoding lives there and is unit tested. The `App/` target is a
thin SwiftUI + SwiftData layer on top of it, and requires Xcode/macOS to
build and run.

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

The progression/rank/schedule logic is plain Swift and can be tested
independently of Xcode:

```sh
cd Core
swift test
```

This also runs in CI on every push via `.github/workflows/core-tests.yml`.

## Manual verification checklist (run through this on a Simulator)

- [ ] First launch shows character creation (name, crew name, favorite club — searchable across all 20 leagues)
- [ ] After creating a character, Dashboard shows rank "Regular", 0 XP, all stats at their base value, and the crew name
- [ ] Attending a match (with "Sit in Ultras Stand" / "Do Pyro" toggled) increases XP and the relevant stats
- [ ] Participating in a chant and contributing to a tifo (Chants/Gallery tabs — these are your crew's, not tied to any real club) each award XP/stats
- [ ] Completing a challenge/task awards XP
- [ ] Rank only advances once XP **and** the rank's gating requirements (activity variety / achievements — see below) are met — it should NOT be possible to reach Capo quickly by repeating one action
- [ ] The Dashboard's rank-progress card shows a difficulty note (harder/easier) when the favorite club's prestige tier isn't 3, and a club's detail screen shows its prestige stars
- [ ] Achievements unlock and appear under Achievements once their criteria are met
- [ ] Inventory items appear as they're earned
- [ ] Force-quit and relaunch the app — character, stats, rank, inventory and achievements all persist
- [ ] Clubs tab lists all 20 leagues; drilling into one shows its real clubs; a club's detail screen shows its generated fixtures/results
- [ ] Matches tab lists the same 20 leagues; drilling into one shows its full generated season

## The club/league data — real, but not live-verified

`App/Resources/Content/leagues.json` and `clubs.json` cover the top-flight
division of the top 20 UEFA-ranked nations (~316 real clubs) — England,
Spain, Italy, Germany, France, Netherlands, Portugal, Belgium, Turkey,
Austria, Switzerland, Czechia, Greece, Norway, Scotland, Denmark, Israel,
Cyprus, Croatia, and Serbia.

This was compiled from the model's own knowledge, **not fetched live** —
this environment's web access was blocked for the reference sites that
would normally verify it (UEFA coefficient rankings, current top-flight
rosters). Club names/leagues should be broadly right, but treat founding
years, stadium names, and especially *this season's exact promoted/relegated
clubs* as best-effort, not verified fact — spot-check before shipping
anything public. `crestAssetName` is `null` everywhere (renders a themed
placeholder — see below) and `history` is `null` for nearly every club
rather than inventing narrative text at this scale; add real crests/history
once you've sourced them, or replace any club's row entirely.

A couple of things to keep in mind when editing this data:
- Real club/competition names are just facts and are fine to use.
- Crests/logos and official color trademarks are often owned by the club —
  make sure you have the rights to use any image you add before shipping.
- `crestAssetName` fields can stay `null` — the app renders a themed
  placeholder (a gradient in the club's listed colors) when no asset is
  provided. Add real images to `Images.xcassets` and set the matching asset
  name once you have them.

## Why matches are generated, not stored

A double round-robin season across ~20 clubs is already ~380 fixtures; across
all 20 leagues that's roughly 4,800 — far too much to hand-author or ship as
static JSON, and there's no real fixture list to source for a game. So
`Core/Sources/UltrasEuropaCore/Scheduling/SeasonScheduleGenerator.swift`
derives each league's full season (pairings, dates, and a placeholder score
for any fixture whose date has passed) **on the fly** from just the club list
and today's date — nothing is persisted. It's seeded deterministically off
stable ids, so the same inputs always produce the same schedule; nothing
changes between launches just from recomputing it. Scores are synthetic —
clearly a game placeholder, never a claim about a real result.

## Chants, tifo, and inventory belong to the player's crew, not a real club

Once club data is real, inventing specific chants, tifo displays, or a named
"ultras group" and attributing them to an actual real club or fan group would
misrepresent that real fan culture. So those features aren't tied to any
club at all: at creation the player names their own crew, and the generic
chants/tifo/inventory catalogs in `App/Resources/Content/` (`chants.json`,
`tifo_photos.json`, `inventory_catalog.json`) belong to that crew regardless
of which real club they follow. Swap in your own chants/tifo captions freely
— they're intentionally generic, not real.

## Progression design

Ranking up is intentionally **not** fast — see
`Core/Sources/UltrasEuropaCore/Progression/ProgressionConstants.swift` for
the full, tunable design: XP costs rise steeply per rank, higher ranks also
require a minimum spread of activity types (not just repeating one action)
and specific achievements to be unlocked, and each activity's XP has a daily
diminishing-returns cap so grinding a single action can't shortcut the
climb.

On top of that, every club carries a `prestigeTier` (1-5, see `clubs.json`)
that scales how much XP its fans need for each rank —
`ProgressionConstants.xpMultiplier(forPrestigeTier:)` maps tier 1 (a small
club) to 0.7× the base XP thresholds and tier 5 (a global giant) to 1.6×, so
a Real Madrid or Manchester United fan needs well over twice the XP a
smaller club's fan needs to reach the same rank. This only scales the XP
threshold — matches attended, activity variety, streaks, and achievement
gates are the same for every club. Tiers were assigned by a per-league
baseline (bigger leagues start higher) plus a bonus for each league's
traditionally dominant clubs — see `prestigeTier` in `clubs.json` and treat
it the same as the rest of the club data: a reasonable starting point, not
a precisely researched ranking.
