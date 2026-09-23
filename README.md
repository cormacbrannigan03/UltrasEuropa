# UltrasEuropa

A native iOS app for European football ultras fan culture. Create a character
and rise through the ranks — from a regular fan to Capo — by attending
matches, standing in the ultras section, running pyro displays, learning
your crew's chants, contributing to your crew's tifo displays, and building
relationships with your crew's members.

## Project layout

```
UltrasEuropa/
├── project.yml        XcodeGen spec — generates UltrasEuropa.xcodeproj (not committed)
├── Core/               Local Swift package: pure models + progression logic (no SwiftUI/SwiftData)
│   ├── Sources/UltrasEuropaCore/
│   │   ├── Models/         Club, League, Match, Rank, CharacterStats, Chant, TifoPhoto, CrewMember, ...
│   │   ├── Progression/    XP/rank/achievement rules
│   │   ├── Scheduling/     SeasonScheduleGenerator (see below)
│   │   └── Crew/           CrewInteractionEngine (see below)
│   └── Tests/UltrasEuropaCoreTests/
└── App/                 The iOS app target: SwiftUI views, SwiftData persistence, bundled content
    ├── Persistence/
    ├── Resources/Content/   Bundled JSON: leagues, clubs, chants, tifo, crew members, catalogs
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

First, install [Xcode 15+](https://developer.apple.com/xcode/) from the App
Store if you haven't already — everything below assumes it's installed.

### Easiest: double-click `Open in Xcode.command`

In Finder, double-click **`Open in Xcode.command`** at the repo root. It
opens Terminal and does everything for you: pulls the latest changes from
GitHub with plain `git pull` (no Xcode account/sign-in involved at all —
see below), installs [XcodeGen](https://github.com/yonaskolb/XcodeGen) via
Homebrew if it's missing, generates `UltrasEuropa.xcodeproj` from
`project.yml`, and opens it in Xcode. (If you don't have Homebrew
installed, it'll tell you and point you to https://brew.sh — that's the
one thing it can't install for you.)

Once Xcode opens, select an iPhone Simulator (iOS 17+) in the scheme
selector and press Cmd+R.

**Every time there's a new update, just double-click this file again** —
don't use Xcode's own Source Control → Pull. Xcode's Source Control needs
its own separate GitHub sign-in (Xcode → Settings → Accounts) and can fail
in confusing ways ("the repository could not be found") that have nothing
to do with whether your actual git checkout is fine. This project never
needs that sign-in — `git pull` over plain HTTPS from the command line
works with no login needed, and the `.command` script always uses that.

### Manual alternative (Terminal)

Equivalent to what the script above does, if you'd rather run it yourself:

1. Pull the latest changes:
   ```sh
   git pull
   ```
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen):
   ```sh
   brew install xcodegen
   ```
3. Generate the Xcode project (this regenerates `UltrasEuropa.xcodeproj` from
   `project.yml` — the `.xcodeproj` itself is gitignored, not committed):
   ```sh
   xcodegen generate
   ```
4. Open it and run:
   ```sh
   open UltrasEuropa.xcodeproj
   ```
   Select an iPhone Simulator (iOS 17+) and press Cmd+R.

Re-run `xcodegen generate` (or double-click the `.command` file again) any
time files are added/removed under `App/` or `Core/`, or `project.yml`
changes.

## Running Core's tests

The progression/rank/schedule logic is plain Swift and can be tested
independently of Xcode:

```sh
cd Core
swift test
```

This also runs in CI on every push via `.github/workflows/core-tests.yml`.

## Save slots — up to three fans at once

The app supports up to `SaveSlotStore.maxSlots` (3) independent saves, so
more than one fan's career can exist side by side without overwriting each
other — each is a separate `CharacterEntity` tagged with a `slotIndex`
(0, 1, or 2).

- **`SaveSlotStore`** (`App/ViewModels/SaveSlotStore.swift`) owns which
  slot is active and the summaries (name, club, rank) shown for all three
  slots on the picker. `CharacterStore` still owns everything about the
  character *within* the active slot — the two don't overlap.
- **Continuing on relaunch** is automatic: the active slot index is
  remembered in `UserDefaults` (a per-device UI preference, not game data,
  so it isn't part of the SwiftData model), and `RootView` loads that
  slot's character before the first frame renders. Force-quitting and
  reopening the app drops you back into the same save with no extra tap.
- **`SaveSlotsView`** (`App/Views/Onboarding/SaveSlotsView.swift`) is the
  picker: three rows, each either an existing save (tap to continue, or
  the trash icon to permanently delete it) or an empty slot (tap to start
  character creation into it). It's shown on first launch (no slot
  remembered yet) and whenever a slot is cleared.
- **"Switch Save"** — the icon button in the Dashboard's toolbar — backs
  out to `SaveSlotsView` without deleting anything, so you can hop between
  saves at any time; picking a different occupied slot loads that fan
  immediately.
- Deleting a save cascades through every relationship on that
  `CharacterEntity` (inventory, achievements, attendance log, crew
  relationships, designed clothing — the same cascade rules used
  everywhere else) and frees the slot for a new fan.

## Manual verification checklist (run through this on a Simulator)

- [ ] First launch shows the save-slot picker with all 3 slots empty; tapping one shows character creation (name, crew name, favorite club — searchable across all 20 leagues)
- [ ] After creating a character, the app goes straight to the Dashboard for that slot
- [ ] Force-quit and relaunch the app — it resumes directly into the same save, no picker shown
- [ ] From the Dashboard, tap "Switch Save" (top-right icon) — it returns to the picker showing the first save's real name/club/rank plus two empty slots
- [ ] Create a second save in an empty slot, switch back to the first via the picker, and confirm each save's stats are independent of the other
- [ ] Delete a save from the picker (trash icon) and confirm it's gone and its slot shows "New Save" again
- [ ] After creating a character, Dashboard shows rank "Regular", 0 XP, all stats at their base value, and the crew name
- [ ] The Dashboard's stats grid shows a fifth "Away Loyalty" tile alongside Loyalty/Knowledge/Influence/Notoriety, and its number rises after a successful away-ticket request (win or lose — see below) rather than staying at 0
- [ ] Dashboard shows a Season Clock card with today's in-game date; "+1 Day"/"+1 Week" advance it and reveal more matches' results
- [ ] Dashboard's "Season Calendar" link shows the favorite club's fixtures grouped by month; "Fast Forward to Next Match" jumps the season clock straight to the next unplayed fixture's date
- [ ] A match more than 30 days out (by the season clock) shows a "Tickets Not Yet On Sale" card instead of the attendance flow; simulating forward past that date unlocks it
- [ ] A home match's attendance card opens a schematic stadium map with four tappable sections, each showing a success percentage (or "Guaranteed" for the Ultras Section with a season ticket); tapping one resolves immediately and locks in — a denied section shows "Denied" on the map and can't be retapped, but a different section can still be tried
- [ ] The Ultras Section's chance is meaningfully lower than the other three sections; Behind the Goal (drawn alongside it as the same end of the ground) is also noticeably harder than the Main Stand or Family Section, though still easier than the Ultras Section itself; a bigger/more prestigious favorite club lowers every section's chance further
- [ ] Confirming attendance (home seat, granted away ticket, or the neutral toggle) launches the full-screen match-day cutscene instead of an instant alert — arrival, a security search (hide the pyro, then a chance of getting caught) only if pyro was toggled, then (if the season clock hasn't reached the match date yet) a "Fast Forward to Kickoff" prompt before the live-watch beat
- [ ] Tapping "Fast Forward to Kickoff" actually advances the season clock and reveals the match as played, instead of silently doing nothing; the same goes for "Fast Forward to Next Match" on the Season Calendar
- [ ] A small X button in the top-right corner of the match-day cutscene closes it at any beat, without needing to reach the end
- [ ] Right at kickoff, the live-watch beat asks how you're supporting today (Sing Non-Stop/Watch Quietly/Wind Up the Away End/Film for Socials) before showing the scoreboard; "Continue Watching" now stops at 15-minute checkpoints in addition to goals, each appending a line to a visible diary on the live-match card
- [ ] At a checkpoint, the current scoreline is shown with a choice to keep the stance going or stop; stopping ends check-ins for the rest of that match (later checkpoints pass with no more prompts) and forfeits the full-time sustain bonus, while keeping it up the whole 90 minutes earns it
- [ ] Keeping "Wind Up the Away End" or "Film for Socials" going for several checkpoints visibly raises heat toward a warning/ejection, same as bad goal reactions — try stacking one with a bad reaction and confirm they combine toward the same ejection/ban outcome
- [ ] Every match's detail screen and every match list row shows a "Category 1/2/3" label; Category 1/2 fixtures show a confrontation beat right after arrival in the cutscene, Category 3 fixtures skip straight to the security/live-match beats with no confrontation opportunity
- [ ] In the confrontation beat, "Start Something" is disabled below Lead Ultra rank and enabled at Lead Ultra or above; "Get Involved" is always available but visibly riskier — try it a few times at a Category 1 fixture and confirm police intervention happens noticeably more often than at Category 3
- [ ] A police intervention cuts straight to a "Pulled Aside By Police" summary (skipping the rest of the beats, including base attendance — `matchesAttended` should NOT increase for that match) and applies a 30-day stadium ban, separate from and longer than a stewards' ejection's 14-day ban
- [ ] Reopening a match already attempted for a confrontation shows the locked-in result on the confrontation beat instead of offering to roll again
- [ ] Each goal during the live-watch beat stops for a Mild/Moderate/Strong/Extreme reaction choice; choosing bigger reactions repeatedly eventually triggers a security warning, then an ejection that cuts straight to a "Thrown Out" summary (skipping chant/tifo/pyro), and eventually an ejection + stadium ban that blocks attending any match until the season clock reaches the ban's end date
- [ ] After the live-watch beat resolves normally (no ejection), the cutscene continues to a chant to join in, a tifo beat only on matches marked "Planned" in the Gallery, a pyro beat only if pyro was toggled and it made it through security, then a Full Time summary with total XP and a Match Stats card (possession/shots/shots on target/corners, as comparison bars)
- [ ] The live-watch feed shows goal scorer names (generic fictional names, e.g. "J. Marsh"), not just "Goal!"; some matches also show yellow/red card entries mixed into the same chronological feed
- [ ] A card during the live-watch beat pauses it for the same Mild/Moderate/Strong/Extreme reaction choice as a goal, and reacting to it can raise heat toward a warning/ejection the same way a goal reaction does
- [ ] Any already-played match's detail screen (`MatchDetailView`) shows a Match Stats card and a "Match Events" list of goal scorers and cards, even for matches you didn't personally attend
- [ ] The Gallery tab is reference-only (no XP button) — greys out tifo displays with no upcoming match "Planned", and taps through to that match on ones that are; there's no standalone Chants tab any more
- [ ] Requesting an away ticket resolves once and locks in — reopening that same match shows the granted or denied result, never a fresh roll
- [ ] Completing a challenge/task awards XP
- [ ] Rank only advances once XP **and** the rank's gating requirements (activity variety / achievements — see below) are met — it should NOT be possible to reach Capo quickly by repeating one action
- [ ] A couple of matches' worth of activities no longer blows past the Young Ultra threshold on their own — progress should feel noticeably slower than before this pass
- [ ] A single Extreme goal reaction gets you ejected from the match on its own; two in the same match draw a stadium ban, not just an ejection
- [ ] The Dashboard's rank-progress card shows a difficulty note (harder/easier) when the favorite club's prestige tier isn't 3, and a club's detail screen shows its prestige stars
- [ ] Achievements unlock and appear under Achievements once their criteria are met
- [ ] Inventory items appear as they're earned
- [ ] Force-quit and relaunch the app — character, stats, rank, inventory, achievements, and the season clock all persist
- [ ] Dashboard's "Crew Members" link shows 15 members grouped by rank (Capo first); each has a relationship label that starts at "Stranger"
- [ ] Interacting with a member shows an outcome (which can go either way), moves their relationship level up or down accordingly, and also awards a little XP — force-quit and relaunch to confirm the relationship persists
- [ ] Tapping "Chat" on a crew member opens a scrolling chat screen (not an alert) with 5 topic chips along the bottom; tapping one adds the player's line and the crew member's reply as chat bubbles, and repeated taps on the same topic mostly avoid repeating the immediately previous reply
- [ ] Chatting with a Lead Ultra/Capo-tier member below the required rank shows the same flat rejection reply every time instead of one of the 100 generic lines
- [ ] A Lead Ultra- or Capo-tier crew member shows a "won't really acknowledge you" note and every interaction with them is a flat rejection capped at Stranger, until the player's own rank catches up (Ultra Group for a Lead Ultra-tier member, Lead Ultra for a Capo-tier one)
- [ ] Dashboard's "Youth Group" link shows "Start your own following" before founding; founding it starts the stage at "Just Founded" with 1 member and shows the main ultras group's (initially indifferent) reaction text
- [ ] Recruiting fails far more often than it succeeds, and the shown success percentage visibly drops as the member count climbs; the main ultras reaction text escalates in tone at 5, 15, and 30 members
- [ ] At 50 members, the recruit button is replaced by a Merge/Take Over choice, each behind a confirmation dialog; choosing either shows a permanent result card and recruiting stops being available
- [ ] Clubs tab lists all 20 leagues; drilling into one shows its real clubs; a club's detail screen shows its generated fixtures/results
- [ ] "Table" tab (replacing the old Chants tab) lists all 20 leagues; drilling into one shows a live standings table (P/W/D/L/GD/Pts) with the favorite club's row highlighted; tapping any row opens that club's detail screen
- [ ] On any club that isn't the favorite club, "Propose Ultras Friendship" shows an acceptance percentage, and resolves immediately to either an accepted friendship (unlocking Chat/Collaborate) or a locked-in decline (button disappears, can't retry that club)
- [ ] Once friends with a club, "Chat with the [Club] Ultras" opens a working chat screen; "Collaborate on a Joint Tifo" awards XP; attending any match involving that friend club (home, away, or as a neutral spectator) shows a bonus on top of the normal attendance XP
- [ ] Matches tab shows only the favorite club's own fixtures/results (browse any other club's schedule from the Clubs tab instead)
- [ ] Buttons, badges, progress bars, and the tab bar tint match the favorite club's primary color; creating a second save with a different club and switching to it via "Switch Save" changes all of those immediately; button text stays readable even for a club with a very light primary color
- [ ] Dashboard's toolbar shows a flag emblem (🇬🇧 by default); tapping it opens a dropdown of all 27 languages with a checkmark on the current one; picking another immediately relabels the tab bar and the "Season Calendar"/"Store" Dashboard links in that language; force-quit and relaunch — the chosen language is still selected
- [ ] Dashboard shows a "Next Match" card right under the Season Clock with the favorite club's soonest unplayed fixture (opponent, home/away, date); tapping it goes straight to that match's detail screen, same as tapping it from the Season Calendar; once every fixture is played, the card reads "No fixtures left this season" instead

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
for any fixture on or before a given date) **on the fly** — nothing is
persisted. It's seeded deterministically off stable ids, so the same inputs
always produce the same schedule; nothing changes between launches just from
recomputing it. Scores are synthetic — clearly a game placeholder, never a
claim about a real result.

That "given date" is no longer the device's real clock — it's each save's own
`CharacterStore.simulatedDate` (see "Season simulation" below), so
`ContentRepository.matchesInLeague(_:asOf:)`/`matchesForClub(_:asOf:)`
regenerate a league's schedule fresh from that date every time they're
called rather than caching it once at app launch.

## Season simulation — the game clock is player-driven, not real-time

Earlier, which fixtures had results was purely a function of the device's
actual calendar date — leave the app closed for a week and matches would
just silently resolve themselves in the background, with no way to speed
that up or see it happen. Now each save carries its own
`CharacterEntity.simulatedDate`, starting at the real date when that
character was created, and the Dashboard's Season Clock card (`SeasonClockCard`)
is the only thing that moves it forward, one day or one week at a time
(`CharacterStore.simulateDays`). Nothing else — real-world activity pacing
like the daily loyalty streak still runs off the device's actual clock,
deliberately kept separate from the season clock.

Because match schedules, ticket sale windows, and tifo/chant assignments are
all generated fresh from this one value, simulating forward is enough to
reveal new results, open up tickets for a previously-locked match, and
change what's showing as "next up" — there's no separate "advance the
season" system to keep in sync with it.

## Season Calendar — fast forward to a match, not just blindly forward

The Dashboard's Season Clock card is a quick nudge (+1 day/week); the
**Season Calendar** (`App/Views/Matches/SeasonCalendarView.swift`, linked
from the Dashboard) is the intended way to actually get somewhere: it lists
the favorite club's fixtures grouped by month, and its "Fast Forward to
Next Match" button calls `CharacterStore.simulateForward(to:)` to jump the
season clock straight to the next unplayed fixture's date — no need to
mash "+1 Day" dozens of times to close a three-week gap between matches.
Every row also shows whether that fixture is upcoming, already played (with
its score), or is today's match.

## Watching a match live — a paced reveal of an already-fixed result

Attending a match no longer just hands you an instant final score. Once
the match-day cutscene reaches its live-match beat, one of two things
happens:

- **If the season clock hasn't reached kickoff yet** (you bought a ticket
  up to 30 days early and went straight into the cutscene without using
  the calendar), it prompts you to fast forward to the match date right
  there — you can't watch a match that hasn't happened.
- **Once it has**, tapping "Continue Watching" advances the clock to
  whichever comes first — the next goal, or the next 15-minute stance
  checkpoint (see "Picking how you support" below) — one stop at a time,
  rather than a real-time animation, because both goals and checkpoints
  need your input before the match can move on.

Nothing about the actual result changes based on watching — the final
score was already fixed the moment the season clock reached that match's
date (`SeasonScheduleGenerator.deterministicScore`), exactly as before.
`MatchDayContentPlanner.goalEvents(matchId:homeGoals:awayGoals:)`
(`Core/Sources/UltrasEuropaCore/MatchDay/`) just derives a deterministic
minute for each of those already-fixed goals (a seeded shuffle of 1–90, so
the same match always plays out the same way), purely to pace how it's
*revealed* — the same principle as the deterministic score itself, applied
to how it unfolds rather than just what it ends up being.

**Fixed bug:** "Fast Forward to Kickoff" (and the Season Calendar's "Fast
Forward to Next Match", which shares the same code path) could silently do
nothing. `CharacterStore.simulateForward(to:)` was computing the number of
days to advance from the raw, exact-time difference between the season
clock and the target date — but `simulatedDate` carries whatever
time-of-day the character happened to be created at, while every generated
`Match.date` lands at midnight, so going from e.g. "9 Oct, 15:45" to
"10 Oct, 00:00" is under 24 hours and `dateComponents([.day], ...)` came
out 0, which `simulateDays` then silently no-ops on. It now normalizes
both dates to the start of their calendar day before computing the
difference, so it correctly advances a full day (or more) regardless of
what time the season clock happens to read. The match-day cutscene also
gained a small X button (top-right, at every beat) so it can be closed
without needing to reach the summary — there was previously no way out of
it at all.

## Picking how you support — the live-watch beat isn't just goal popups

Before, the live-match beat only ever stopped for goals — a quiet 0-0
could feel like two taps and it's over. Right at kickoff, the player now
picks a `MatchStance`
(`Core/Sources/UltrasEuropaCore/MatchDay/MatchStance.swift`) for how
they're spending the full 90 minutes: Sing Non-Stop, Watch Quietly, Wind
Up the Away End, or Film for Socials. From then on, "Continue Watching"
stops at **every 15-minute checkpoint** (15, 30, 45, 60, 75, 90) as well
as at goals, and each checkpoint that's kept up appends a line to a
running "diary" shown right on the live-match card — a stance-flavored
moment pulled from `MatchStanceConstants`' pool of 15 lines per stance
(60 total), so a full, uninterrupted match builds up six lines of texture
instead of staying silent between goals.

**You can stop if it's not going well.** Every checkpoint is also a
check-in: the current scoreline is shown, and the player can either keep
the stance going or ease off for the rest of the match — e.g. dropping
"Wind Up the Away End" if the favorite club is getting beaten and it
doesn't feel worth the trouble any more. Once stopped, there's no going
back to that stance for the rest of the match — later checkpoints pass by
silently with no more check-ins. Keeping a stance up for the entire 90
minutes without easing off earns a one-off reward at full time (its own
`ActivityType`, e.g. `.sustainSingNonStop`); stopping early forfeits it,
which is the whole trade-off — commit and it pays off, bail and it's safe
but nets nothing extra.

The two more demonstrative stances carry real risk, not just flavor:
Wind Up the Away End adds 8 heat per checkpoint it's kept up, Film for
Socials adds 2 — the exact same stadium-security "heat" goal reactions
already add (see below), sharing one running total and one
`SecurityIncidentEngine` outcome check
(`MatchDayCutsceneView.applyHeat(_:)`, refactored out of the goal-reaction
code so both sources funnel through the same ejection/ban logic). Singing
or watching quietly the whole match adds no heat at all. A sustained
provocative stance alone tops out at "warned" over a full match, but
stacked with even one bad goal reaction it can easily tip into an
ejection or a ban — the two systems compound rather than living side by
side.

## Reacting to goals, security searches, and the risk of getting thrown out

Every goal during the live-watch beat stops the match and asks how the
player reacts — `ReactionSeverity` (`Core/Sources/UltrasEuropaCore/MatchDay/`)
runs from Mild through Moderate and Strong to Extreme. Each is its own
`ActivityType` (`reactMildly`...`reactExtremely`) with its own fixed reward
in `ProgressionConstants.activityRewards` — bigger reactions earn more XP
and notoriety, exactly the trade-off a real ultra faces: staying quiet is
safe but forgettable, going off is what actually builds a reputation.

That reward isn't free. Every reaction (beyond the safest, Mild) adds
"heat" for the rest of that match — `SecurityIncidentEngine` compares
accumulated heat against three thresholds and is deliberately deterministic
rather than a hidden dice roll, so the risk is something the player can see
coming and manage, not luck:

| Heat | Outcome |
| --- | --- |
| < 30 | Nothing |
| ≥ 30 | Warned — security starts watching you |
| ≥ 55 | Ejected — the cutscene cuts straight to a "Thrown Out" summary, skipping the chant/tifo/pyro beats entirely |
| ≥ 85 | Ejected **and banned** — `CharacterStore.applyStadiumBan` sets `CharacterEntity.stadiumBanUntilDate` 14 days out from the season clock, and `MatchDetailView` blocks attendance at *any* match (home, away, or neutral) until the season clock reaches that date |

(These thresholds were tightened from their original 40/70/100 — see "A difficulty pass" under Progression design below.)

Separately, bringing pyro means passing a security search on the way in —
before the security beat, if `didPyro` is set, the player picks a
`PyroHidingSpot` (jacket lining, scarf, taped to a leg, a sock), each with
its own chance of getting through (`SecurityCheckEngine.resolvePyroSearch`).
Getting caught confiscates the pyro for that match (no pyro beat, and the
`.doPyroChallenge` reward isn't earned) but doesn't block getting into the
ground — only a *bad reaction*, not a failed search, gets you ejected.

## Match stats, goal scorer names, and reactable cards

The match screen and live-watch beat now read more like a real match
report instead of just a scoreline:

- **Basic stats** — possession, shots, shots on target, and corners —
  come from `MatchStatsEngine.generate(matchId:homeGoals:awayGoals:)`
  (`Core/Sources/UltrasEuropaCore/MatchDay/MatchStatsEngine.swift`), the
  same deterministic-seeded-hash technique as everything else in
  `MatchDay/`: the same match always shows the same stats, and they're
  biased toward whichever side actually won (more shots, more corners,
  more possession) without ever contradicting the real score. Shots on
  target are always at least the number of goals scored and never more
  than total shots; home and away possession always sum to 100. A shared
  `MatchStatsCard` (`App/Views/Matches/MatchStatsCard.swift`) renders these
  as side-by-side comparison bars, and appears both in `MatchDetailView`
  for any already-played match and in the cutscene's full-time summary.
- **Goal scorers** — every `GoalEvent` now carries a `scorerName`, and
  every card carries a `playerName`. Both are drawn from
  `MatchPlayerNames`, a pool of ~30 clearly-generic, fictional names (e.g.
  "J. Marsh", "D. Okafor") — never real footballers. This follows the same
  honesty policy already applied to invented crew, chants, and tifo
  content: real clubs and leagues are used, but nothing invented is
  attributed to a real person.
- **Cards** — `MatchDayContentPlanner.cardEvents(matchId:)` deterministically
  generates 0–4 cards per match (yellow, or red roughly 1 in 10 times), each
  with its own minute, side, and player. The live-watch feed merges goals
  and cards into one chronological list (`MatchDayCutsceneView.FeedEntry`),
  and `MatchDetailView` shows the same list as a "Match Events" summary for
  any played match.

**Cards are reactable, just like goals.** A card pauses the live-watch beat
exactly the way a goal does, prompting the same Mild/Moderate/Strong/Extreme
`ReactionSeverity` choice, earning the same `reactMildly`...`reactExtremely`
rewards, and adding the same stadium-security heat — reusing the existing
system rather than inventing a parallel one, since "how do you react in the
stands" doesn't really change based on what triggered it. When a goal and a
card land on the same minute, goals take priority, then cards, then a
stance checkpoint (`MatchDayCutsceneView.advanceWithinLiveMatch()`), so
nothing gets silently skipped.

## Match categories and police presence: a pre-match risk, separate from in-stadium security

Every fixture now carries a `MatchCategory` (Category 1, 2, or 3 — the
same three-tier scale English football policing actually uses, without
claiming to be an accurate real-world source), shown on the match detail
screen and in every match list row.
`MatchProfileEngine.category(matchId:homeClubPrestigeTier:awayClubPrestigeTier:)`
(`Core/Sources/UltrasEuropaCore/MatchDay/`) derives it deterministically
from both clubs' combined `prestigeTier`, bumped by a per-match seeded
factor so it isn't purely "biggest clubs always Category 1" — a smaller
local rivalry can occasionally flare up into one too. Category 1 means a
heavy police presence and rival firms expected; Category 3 is too
low-key for any of this to come up at all.

For a Category 1 or 2 fixture, the match-day cutscene gets a new beat
right after arrival — before the security search or kickoff — where a
rival firm has been spotted. The player picks one of three options:

- **Start Something** — instigating it outright, gated behind
  `UltraViolenceEngine.minimumRankToInstigate` (Lead Ultra): calling the
  shots takes standing in the group, not something a new fan can just
  decide to do. Organized firms plan around the police, so this carries
  the *lower* of the two risk levels.
- **Get Involved** — piling in on something already happening, open to
  any rank, but with no control over it and no planning around the
  police — so it's *more* likely to end in police intervention than
  instigating.
- **Stay Out of It** — the safe default; nothing happens.

`UltraViolenceEngine.interventionChance(role:category:)` combines a base
chance per role (20% instigator / 40% participant) with a per-category
bump (up to +25% at Category 1), so the biggest, most heavily-policed
fixtures are also the riskiest ones to get involved at. Getting away with
it awards a `.startUltraViolence`/`.joinUltraViolence` activity (XP,
influence, and a meaningful notoriety bump — bigger for instigating).
Police intervention instead applies a 30-day stadium ban (longer than a
stewards' ejection's 14 days — this is a police matter, not just being
thrown out) and skips straight to the cutscene's "Pulled Aside By Police"
summary: the player never actually gets into the ground, so no
attendance credit for that match either. Like away tickets and home
seats, each match's attempt locks in the first time — no re-rolling a
police intervention into a clean getaway.

This system is deliberately abstracted — a resolved outcome plus
consequences (XP, notoriety, a ban), never a blow-by-blow account of
what happens — same principle as the ejection/security-ban system it
sits alongside.

## Chants, tifo, and inventory belong to the player's crew, not a real club

Once club data is real, inventing specific chants, tifo displays, or a named
"ultras group" and attributing them to an actual real club or fan group would
misrepresent that real fan culture. So those features aren't tied to any
club at all: at creation the player names their own crew, and the generic
chants/tifo/inventory catalogs in `App/Resources/Content/` (`chants.json`,
`tifo_photos.json`, `inventory_catalog.json`) belong to that crew regardless
of which real club they follow. Swap in your own chants/tifo captions freely
— they're intentionally generic, not real.

## Crew members and relationships

`App/Resources/Content/crew_members.json` is a small fictional roster (3 per
rank, `crew_members.json`'s `rank` field matches `Rank`'s raw value 0-4) that
becomes visible on the Dashboard ("Crew Members") once a character exists —
these are entirely made-up NPCs belonging to the player's own crew, same
reasoning as the chants/tifo above.

Tapping a member opens a detail screen with five interactions (Chat, Invite
to a Match, Share a Chant, Stand Up for Them, Tease Them), each with its own
success chance and point range — see
`Core/Sources/UltrasEuropaCore/Crew/CrewInteractionConstants.swift`. Every
interaction can go either way: `CrewInteractionEngine.resolve` (pure,
seeded-RNG-testable) rolls the outcome and returns a bond-score delta that
can be positive (relationship improves) or negative (it sours) — persisted
per member in a `CrewRelationshipEntity`, clamped to -100...100 and labeled
by `RelationshipLevel` (Rival through Bonded for Life). Each interaction also
records a `.socializeWithCrew` activity, so it earns a little XP the same
way every other activity does — but it's deliberately left out of the
activity-diversity rank gate, so it's a bonus on top of the existing ladder,
not a new required step.

### Chat is a real conversation screen, not a single tap

"Chat" is the one interaction that opens somewhere different: instead of
an instant alert, it pushes into `CrewChatView` — a scrolling chat-bubble
screen with quick-reply chips along the bottom (Last Match, Next Match,
How's Life, The Club, Banter) standing in for free-text input. Tapping
one sends the player's line as a bubble, then the crew member replies
with one of `CrewChatConstants`'s 100 generic lines (20 per topic,
picked at random and never repeating the immediately previous line for
that topic). Under the hood it still runs the exact same
`CrewInteractionEngine.resolve(interaction: .chat, ...)` roll as before
(bond score, XP) — a small "Relationship +N" caption appears under the
reply when it's nonzero — so the underlying mechanics are unchanged, only
richer to actually read through. A crew member who doesn't acknowledge
the player yet (see the rank-gating note above) replies with the same
flat rejection line instead of a generic one, so the chat screen doesn't
contradict that gate.

## Founding your own youth group — a slow, hostile rival path

Alongside the favorite club's existing ultras group, the Dashboard's
"Youth Group" link (`YouthGroupView`) lets the player found and grow a
breakaway group of their own — a genuine alternative power base, not just
flavor text.

- **Founding** (`CharacterStore.foundYouthGroup`) is a one-time action that
  starts the group at 1 member (the player). From there,
  **`YouthGroupStage`** tracks its size against fixed thresholds — Just
  Founded (1) → Small Following (5) → Growing Crew (15) → Established
  Rival (30) → Empire Built (50) — each with its own
  `mainUltrasReaction` text shown right on the screen, escalating from
  total indifference to open hostility as the group grows. The main
  ultras group is never happy about it, and says so.
- **Recruiting** (`CharacterStore.recruitToYouthGroup`) is deliberately
  brutal: `YouthGroupEngine.recruitChance` starts at just 30% for the very
  first member and drops by half a percentage point per existing member,
  down to a 5% floor — poaching people away from an already-established
  following only gets harder the bigger the rival group gets. There's no
  guaranteed-success threshold like the away-ticket or home-seat systems
  have; every attempt is a coin flip stacked against the player.
- **Reaching 50 members** ("Empire Built") unlocks a one-time, mutually
  exclusive ending: **merge** peacefully with the main ultras group
  (`mergeYouthGroupWithMainUltras`) or **take over** outright
  (`takeOverMainUltrasGroup`), both gated behind a confirmation dialog
  since neither can be undone. Both award a large one-off XP/influence
  reward reflecting how big a moment it is, and `YouthGroupOutcome` (Core)
  persists which ending was chosen so the screen shows a permanent result
  card afterward instead of the recruiting flow.

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

### A difficulty pass: progress was too fast, setbacks too rare

Playtesting flagged rank progress as remarkably fast — a couple of matches
with the full spread of match-day activities (attend, sit in the Ultras
Section, pyro, chant, tifo, several goal reactions) was piling up XP much
faster than the rank ladder's steep-threshold design intended. Retuned in
three places:

- **Lower per-activity XP.** Every activity in
  `ProgressionConstants.activityRewards` pays roughly 20-30% less XP than
  before (e.g. attending a match: 50 → 38 XP; a Mild goal reaction: 5 → 4
  XP), and diminishing returns now bite from the *second* occurrence of an
  activity in a day instead of the third, decaying faster once they start.
- **Higher rank thresholds.** Young Ultra through Capo all need
  meaningfully more XP than before (Young Ultra: 300 → 420; Ultra Group:
  900 → 1,400; Lead Ultra: 2,200 → 3,400; Capo: 4,500 → 6,800) — on top of
  the unchanged matches-attended/activity-diversity/achievement gates.
- **Harsher security setbacks.** Every `ReactionSeverity` now carries more
  heat (a once-"free" Mild reaction now draws a little attention too, not
  zero), and `SecurityIncidentEngine`'s warning/ejection/ban thresholds are
  all lower — a single Extreme reaction alone is now enough to get ejected,
  and two are enough to draw a stadium ban, where before it took several
  reactions stacked together to escalate that far.

### Top ultras don't know who you are yet

Every `CrewMember` already carries its own `rank` (Regular through Capo),
representing how senior they are within the player's crew. That tier now
gates how far a relationship can go:
`CrewInteractionConstants.acknowledges(memberRank:playerRank:)` returns
false whenever the player's own rank hasn't yet reached the rank just
below that crew member's — so a Capo-tier member won't take a newcomer
seriously until the player is themselves a Lead Ultra, a Lead Ultra-tier
member needs the player to be Ultra Group, and so on. Regular and Young
Ultra-tier members are peers and always acknowledge the player.

Interacting with a crew member who doesn't acknowledge you yet still
"happens" (so there's no dead button and no crash), but
`CrewInteractionEngine.resolve` forces the outcome to a flat rejection —
zero bond change, capped at "Stranger" (bond ≤ 15) regardless of how high
it already was — with a message naming the rank the player still needs to
reach. `CrewMemberDetailView` also shows this as a standing note under the
relationship card, so it's clear before every attempt, not just after a
failed one.

## The real-money store — and the trade-off it makes

`StoreView` (reachable from the Dashboard) sells four permanent,
non-consumable entitlements via real StoreKit 2 (`App/Store/PurchaseManager.swift`):

| Product | Price | What it does |
| --- | --- | --- |
| Unlock All Cosmetics | $2.99 | Instantly owns every `inventory_catalog.json` item (scarves, flags, banners, pins, jerseys), regardless of its normal unlock criteria |
| Rise to the Top | $9.99 | Instantly sets rank to Capo, overriding the earned rank everywhere it's read |
| Any Home Section Seat | $0.99 | Instantly grants a standing season ticket in the favorite club's ultras section, bypassing the loyalty threshold |
| Unlimited Away Access | $0.99 | Every away-ticket request succeeds, bypassing `AwayTicketAllocationEngine` entirely |

This is a deliberate departure from every other system in this app: the
whole point of the progression design above (steep XP curves, prestige
scaling, activity-diversity gates, loyalty grinds) is that ranking up
*shouldn't* be easy — these four purchases exist specifically to let a
player pay to skip that, at the player's choice. `StoreProductKind`
(`Core/Sources/UltrasEuropaCore/Store/StoreProductKind.swift`) keeps this
short and explicit rather than open-ended, and each entitlement is a
simple persisted flag on `CharacterEntity` that the relevant
`CharacterStore` property already checks first (see `rank`,
`ownedItemIDs`, `hasUltrasSeasonTicket`, `awayTicketChance`,
`attemptAwayTicket`) — none of it touches or recalculates the underlying
earned progress, so a refund or a bug in the entitlement flag can't erase
real progress underneath it.

**Getting real purchases working requires two things this environment
can't do:** registering these four product identifiers
(`StoreProductKind.productID`, e.g.
`com.cormacbrannigan03.UltrasEuropa.store.riseToTop`) as non-consumable
In-App Purchases in App Store Connect, and setting their pricing/tax/banking
details there — both need an Apple Developer account and the App Store
Connect web UI, neither of which is reachable from this sandbox. Until
that's done, `Product.products(for:)` returns nothing and `StoreView` shows
its "no products found" message.

For local testing before that setup exists, `App/StoreKit/Configuration.storekit`
defines the same four products with sandbox prices, and `project.yml`
wires it into the `UltrasEuropa` scheme's run configuration
(`storeKitConfiguration`) — running the app in the iOS Simulator from Xcode
should let you buy, cancel, and restore all four products against Apple's
local StoreKit testing environment with no App Store Connect account or
network connection needed. That local configuration is just for testing;
it has no effect on a real device or a TestFlight/App Store build; those
still need the real App Store Connect products described above.

## Every club has an ultras group — but it's a generic label, not invented lore

Every club's ultras group is surfaced as `Club.ultrasGroupName`
(`"{Club} Ultras"`) rather than a specific, made-up name, chant catalog, or
history attributed to that club's actual fan culture — same reasoning as the
chants/tifo/crew content above. What *is* real is the relationship arc: the
group notices and invites the player as they climb the existing rank ladder.
`UltrasGroupMembershipStage`
(`Core/Sources/UltrasEuropaCore/Models/UltrasGroupMembershipStage.swift`)
maps directly onto `Rank` — no new thresholds to tune or desync from the
progression design above:

| Stage | Rank(s) |
| --- | --- |
| Not noticed | Regular, Young Ultra |
| Invited to home games | Ultra Group |
| Invited to away games | Lead Ultra |
| Full member | Capo |

`CharacterStore.ultrasGroupMembershipStage` derives this live from the
player's current rank, and `UltrasGroupStatusCard` (shown on the Dashboard
and on the player's favorite club's detail page) surfaces the current stage
alongside season-ticket and away-ticket progress.

## Home season tickets: loyalty-gated, and harder for bigger clubs

Sitting in the Ultras Section every so often isn't enough to make it a
season ticket — that has to be *earned* with loyalty, and the bigger the
club, the more it takes. `ProgressionConstants.seasonTicketLoyaltyThreshold`
scales by the club's existing `prestigeTier` (40 loyalty for a tier-1 club
up to 280 for a tier-5 giant), and `CharacterStore.hasUltrasSeasonTicket`
compares the player's accumulated `loyalty` stat against that threshold.
Loyalty accrues the same slow way every other stat does (see Progression
design above), so there's no separate grind system to learn — just a
harder bar for the biggest clubs' ultras sections, reusing the prestige
scaling that already governs XP. A season-ticket holder is guaranteed a
spot in the Ultras Section from then on (see the stadium map below)
instead of rolling for it every match.

### The stadium map: applying for a section is a chance, not a pick

Attending a home match no longer means instantly picking a seat — it means
opening a schematic stadium map (`StadiumMapView`, reachable from
`MatchDetailView`'s "Open Stadium Map" button) with the four stands
(`SeatCategory`: Main Stand, Family Section, Behind the Goal, Ultras
Section) arranged around a pitch, each showing its current chance of
success. `HomeSeatRequestEngine`
(`Core/Sources/UltrasEuropaCore/Tickets/HomeSeatRequestEngine.swift`) gives
each section its own base chance, and it isn't just the Ultras Section
itself that's hard: Behind the Goal is drawn right alongside it as the
same end of the ground, and its chance (50%) is deliberately well below
the Main Stand (75%) and Family Section (95%) on the other side of the
pitch, to reflect overflow demand from fans who couldn't get into the
Ultras Section spilling into the rest of that end. The Ultras Section
itself stays the hardest of all at just 30%. Every section's odds then
scale down further for a more prestigious club
(`prestigeDifficultyMultiplier`, 1.15× easier for a tier-1 club down to
0.65× for a tier-5 giant).

Tapping a section rolls it immediately and locks in the result for that
(match, section) pair — `CharacterStore.requestHomeSeat`, mirroring how
away tickets already lock in a first attempt so a denial can't be
re-rolled into a win. Unlike away tickets, though, a denial for one
section doesn't block the match entirely: the player can reopen the map
and try a different, easier section instead, they just can't retry the
exact section they were already denied for. Once any section succeeds,
that's the seat for the match and the map won't reopen.

## Away tickets: a loyalty-driven chance, not a guarantee — and locked in once rolled

Away matches are scarcer, so showing up doesn't guarantee a ticket.
`AwayTicketAllocationEngine`
(`Core/Sources/UltrasEuropaCore/Tickets/AwayTicketAllocationEngine.swift`)
rolls a chance that starts at a 30% base
(`ProgressionConstants.awayTicketBaseChance`) and rises toward guaranteed as
the player's separate `awayLoyaltyPoints` stat approaches
`awayTicketGuaranteedThresholdByTier` — again scaled by the club's prestige
tier, so away tickets to a big club's biggest games stay competitive for
longer. Every attempt moves the needle: a successful ticket earns more away
loyalty than a miss, so even being turned down builds toward the next
attempt. This is deliberately a separate stat from home loyalty — being a
regular at home doesn't buy you an away seat.

The result is locked in the first time you request a ticket for a given
match — `AwayTicketAttemptEntity` persists the outcome per `matchId`, and
`CharacterStore.attemptAwayTicket` returns that stored result instead of
rolling again on a later visit. Without this, reopening a match after a
denial and tapping "Request" again would let you re-roll a bad outcome for
free, defeating the whole point of it being a chance rather than a
guarantee.

## Tickets go on sale a month out, not the moment a fixture exists

A fixture existing in the generated schedule doesn't mean tickets for it are
available yet — `TicketSaleWindow`
(`Core/Sources/UltrasEuropaCore/Tickets/TicketSaleWindow.swift`) opens sales
`daysBeforeMatch` (30) days before kickoff, checked against the season
clock via `CharacterStore.ticketsAreOnSale(for:)`. `MatchDetailView` shows a
locked "Tickets Not Yet On Sale" card with the exact sale date in place of
the seat-picker/away-ticket/neutral-attend flow until then — this applies
uniformly across home, away, and neutral matches.

## Away travel: bus or train, decided with the crew

Once a player has an away ticket, `TravelMode` (`bus` or `train`) is chosen
through a lightweight "discussion" with the crew rather than a silent
picker — each crew member has a fixed, deterministic preference
(`TravelMode.preferred(byMemberId:)`), so the same crew always leans the
same way, giving the choice some texture without needing a full group-chat
system. Traveling by bus carries a small loyalty bonus
(`ProgressionConstants.busTravelAwayLoyaltyBonus`), reflecting the
lower-key, more communal way most ultras groups actually travel to away
games, without inventing any specifics about a real club's real away days.

## The match-day cutscene: chants and tifo happen at the game, not in a menu

Joining a chant or contributing to a tifo used to be a standalone button —
reachable from a menu at any time, with no connection to an actual match.
`MatchDayCutsceneView` (`App/Views/Matches/MatchDayCutsceneView.swift`)
replaces that: once attendance is locked in (a home seat picked, an away
ticket granted, or the neutral toggle confirmed), `MatchDetailView`
presents a full-screen sequence — a travel beat first for an away day (a
bus or train scene based on the chosen `TravelMode`), arriving at the
ground, joining in the match's chant, raising a tifo if one's prepared for
this specific fixture, a pyro beat if that was toggled, and a closing
"Full Time" summary totting up all the XP earned along the way.
`.participateInChant` and `.contributeToTifo` are only ever recorded from
inside this flow now.

Every match gets a chant (`ContentRepository.chantOfTheDay`, a stable
hash-pick from `chants.json` so the same match always sings the same one),
but only roughly 1 in 4 get a tifo (`MatchDayContentPlanner.isTifoPrepared`)
— tifos are an occasional, planned production, not something a crew puts on
every week the way a chant happens every game. `TifoGalleryView`/
`TifoDetailView` (the Gallery tab) is a read-only reference screen marking
which displays are "Planned" for one of the favorite club's upcoming
matches (tapping one takes you to that match, where raising it actually
happens) versus not currently planned for anything upcoming. There's no
standalone chants-library screen any more — see "League Table" below for
what replaced that tab.

## League Table: replaces the old Chants tab

The tab bar's fourth slot is now "Table" (`LeagueTableView`), not
Chants — since chants/tifo happen at the match itself (see above), a
standalone chants-library tab had nothing left to do. Tapping the tab
lists all 20 real top-flight leagues (same list `ClubDirectoryView`
shows); tapping one opens `LeagueStandingsView`, a live-computed table —
position, P/W/D/L, goal difference, and points — for every club in that
league.

Nothing about the table is stored: `LeagueTableEngine.standings(matches:clubIds:)`
(`Core/Sources/UltrasEuropaCore/Standings/`) is a pure function that
recomputes it from that league's already-generated fixtures
(`SeasonScheduleGenerator`) every time the screen is opened, sorted by the
standard football order (points, then goal difference, then goals
scored). The favorite club's row is highlighted in the accent color.
Tapping any row — not just the favorite club's — opens that club's
`ClubDetailView`, which is also where the new "browse every club, not
just your own" affordance below hooks in.

## Ultras friendships with other clubs' groups

From any club's detail screen (reached via the League Table or the Clubs
tab) other than the favorite club, an "Ultras Friendship" card offers to
propose that the player's own crew and that club's ultras group become
friends. Proposing isn't guaranteed to work —
`ClubFriendshipEngine.chance(playerRank:sameLeague:)`
(`Core/Sources/UltrasEuropaCore/Friendship/`) starts at a 55% base, adds
20% for a club in the same league (easier to coordinate away days and
meetups with), and a further 5% per rank above Regular (more standing
makes another group take the proposal more seriously). Like away
tickets, home seats, and confrontations, each club's proposal locks in
the first time — a decline can't be re-rolled, though there's nothing
stopping the player from proposing to a different club instead.

Once accepted, three things open up on that club's detail screen:

- **Chat** — `ClubFriendChatView` reuses the exact same bubble-and-chips
  screen and 100-line generic response pool `CrewChatView` uses for crew
  members (see "Chat is a real conversation screen" above) — the same
  generic lines read just as naturally coming from another club's group.
  Purely social; no XP for chatting.
- **Collaborate** — `CharacterStore.collaborateWithFriendClub` arranges a
  joint tifo/chant exchange, a one-tap action awarding its own XP/
  influence via the `.collaborateWithFriendClub` activity.
- **Attend each other's games** — every match attended (home, away, or
  neutral) that involves a friend club on either side now also earns a
  `.attendFriendClubMatch` bonus, wired into
  `MatchDayCutsceneView.recordBaseActivities()` alongside the usual
  attendance recording — showing up for a friendly group's game earns
  something, not just your own club's.

## Wardrobe and player-launched clothing ranges

`WardrobeView` lets the player equip one item per slot (`ClothingSlot`:
top, scarf, hat) from the bundled generic starter catalog
(`App/Resources/Content/clothing_items.json`) — plain, non-club-specific
items like a classic jersey or a retro scarf, in keeping with the
generic-content rule used everywhere else. There's no avatar renderer in
this app (everything is card/list-based), so "dressing your character" is a
selection system: equipped items are tracked per slot on `CharacterEntity`
and shown with a checkmark, not painted onto a graphic.

Reaching **Capo** unlocks something further: launching your own clothing
range and selling it to your crew (`CharacterStore.launchClothingRange`).
This creates a new `DesignedClothingItemEntity`, immediately equips it,
gives every crew member's relationship a small bond bump (reusing the
existing relationship system above), and records a `.launchClothingRange`
activity for a burst of XP and notoriety — reusing the same
`ProgressionEngine`/`CharacterStore.apply()` pipeline as every other
activity, and left out of the activity-diversity gate for the same reason
`.socializeWithCrew` is: it's a capstone reward for reaching the top rank,
not a required step to get there.

## The UI retheme to the favorite club's colors

`Theme.accent` (buttons, badges, progress bars, the tab bar tint — every
highlight color across the app) isn't a fixed constant: it follows
whichever club the active save supports. `CharacterStore` calls
`Theme.applyClubColors(primaryHex:secondaryHex:)` any time the active
character changes (`loadCharacter`, `createCharacter`) and
`Theme.resetToDefaultColors()` when there isn't one (the save-slot picker,
or before a character's created) — both read straight from that club's
existing `primaryColorHex`/`secondaryColorHex` in `clubs.json`, no new
content needed. `background`, `cardBackground`, and the text colors stay
fixed regardless of club, so contrast and readability never depend on
which team's colors happen to be in play.

Implementation-wise, `Theme` itself didn't need to change shape to callers
— `Theme.accent` was already a global constant read directly (no
`@Environment` plumbing) from around 50 call sites across the app, so
making it retheme-able without touching every one of them meant backing
it with a small `@Observable` singleton (`ThemeState`, private to
`DesignSystem.swift`) instead of a `static let`. Reading any `@Observable`
instance's properties during a view's `body` registers as a normal
Observation dependency regardless of how the instance was obtained, so
every existing `Theme.accent` reference still updates live the moment the
active club changes — no per-file changes required.

One real wrinkle real club colors create: some clubs' primary color is
very light (near-white or pale yellow), which would make hardcoded white
button text unreadable. `Theme.accentForeground` picks white or black
based on the accent color's relative luminance, and every place in the app
that draws text or an icon directly on an `accent`-colored background uses
it instead of a hardcoded `.white`.

## Language picker — the interface, not (yet) the full text

A flag emblem sits in the Dashboard's toolbar, showing the currently
selected language (🇬🇧 by default, for English). Tapping it opens a
dropdown (`Menu`) listing all 27 supported languages — every official
language of the European Union, plus Norwegian, Turkish, and Serbian so
every nation with a league in `leagues.json` is covered too — each shown
with its own flag and name written in that language, with a checkmark on
whichever one is active. Picking one calls
`LocalizationManager.shared.setLanguage(_:)` and the choice is remembered
across launches via `UserDefaults`, the same way the active save slot is
— it's a per-device preference, not something tied to a save.

`AppLanguage` (Core) lists the 27 languages with their ISO code, flag
emoji, and native name. `LocalizationManager` (App) is a small
`@Observable` singleton — the same trick `ThemeState` uses for club
colors — so anywhere in the app that reads
`LocalizationManager.shared.string(_:)` during its `body` updates live the
moment the language changes, with no `@Environment` plumbing needed.

**Honest scope note:** the picker and the full 27-language list work today
— pick any language and the tab bar (Dashboard/Clubs/Matches/Table/
Gallery) and the "Season Calendar"/"Store" Dashboard links relabel
immediately, translated by hand into all 27 languages. The rest of the
app's text — match descriptions, activity prompts, achievement copy, crew
dialogue, and everything else, several hundred strings across roughly 30
files — stays in English regardless of the picked language. Translating
all of that accurately into 27 languages is a large task that deserves
native-speaker review, which this pass didn't have; rather than paper over
that with machine-translated flavor text, `LocalizedStrings.swift` covers
only the `L10nKey` cases the interface chrome actually uses today
(`tabDashboard`, `tabClubs`, `tabMatches`, `tabTable`, `tabGallery`,
`seasonCalendar`, `store`, `language`). Extending coverage to more screens
is just a matter of adding new `L10nKey` cases and translation rows to
that same table — the infrastructure (the language list, the picker, the
persistence, the live-update mechanism) is already built for it.
