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
- [ ] Dashboard shows a Season Clock card with today's in-game date; "+1 Day"/"+1 Week" advance it and reveal more matches' results
- [ ] A match more than 30 days out (by the season clock) shows a "Tickets Not Yet On Sale" card instead of the attendance flow; simulating forward past that date unlocks it
- [ ] Confirming attendance (home seat, granted away ticket, or the neutral toggle) launches the full-screen match-day cutscene instead of an instant alert — arrival, a chant to join in, a tifo beat only on matches marked "Planned" in the Gallery, a pyro beat only if pyro was toggled, then a Full Time summary with total XP
- [ ] Chants/Gallery tabs are reference-only now (no XP button) — Gallery greys out tifo displays with no upcoming match "Planned", and taps through to that match on ones that are
- [ ] Requesting an away ticket resolves once and locks in — reopening that same match shows the granted or denied result, never a fresh roll
- [ ] Completing a challenge/task awards XP
- [ ] Rank only advances once XP **and** the rank's gating requirements (activity variety / achievements — see below) are met — it should NOT be possible to reach Capo quickly by repeating one action
- [ ] The Dashboard's rank-progress card shows a difficulty note (harder/easier) when the favorite club's prestige tier isn't 3, and a club's detail screen shows its prestige stars
- [ ] Achievements unlock and appear under Achievements once their criteria are met
- [ ] Inventory items appear as they're earned
- [ ] Force-quit and relaunch the app — character, stats, rank, inventory, achievements, and the season clock all persist
- [ ] Dashboard's "Crew Members" link shows 15 members grouped by rank (Capo first); each has a relationship label that starts at "Stranger"
- [ ] Interacting with a member shows an outcome (which can go either way), moves their relationship level up or down accordingly, and also awards a little XP — force-quit and relaunch to confirm the relationship persists
- [ ] Clubs tab lists all 20 leagues; drilling into one shows its real clubs; a club's detail screen shows its generated fixtures/results
- [ ] Matches tab shows only the favorite club's own fixtures/results (browse any other club's schedule from the Clubs tab instead)

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

Attending a home match now means picking a seat (`SeatCategory`: Main
Stand, Family Section, Behind the Goal, or Ultras Section) via
`MatchDetailView`'s home-attendance flow. Sitting in the Ultras Section
every so often isn't enough to make it a season ticket — that has to be
*earned* with loyalty, and the bigger the club, the more it takes.
`ProgressionConstants.seasonTicketLoyaltyThreshold` scales by the club's
existing `prestigeTier` (40 loyalty for a tier-1 club up to 280 for a
tier-5 giant), and `CharacterStore.hasUltrasSeasonTicket` compares the
player's accumulated `loyalty` stat against that threshold. Loyalty accrues
the same slow way every other stat does (see Progression design above), so
there's no separate grind system to learn — just a harder bar for the
biggest clubs' ultras sections, reusing the prestige scaling that already
governs XP.

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
reachable from the Chants/Gallery tabs at any time, with no connection to
an actual match. `MatchDayCutsceneView`
(`App/Views/Matches/MatchDayCutsceneView.swift`) replaces that: once
attendance is locked in (a home seat picked, an away ticket granted, or the
neutral toggle confirmed), `MatchDetailView` presents a full-screen sequence
— a travel beat first for an away day (a bus or train scene based on the
chosen `TravelMode`), arriving at the ground, joining in the match's chant,
raising a tifo if one's prepared for this specific fixture, a pyro beat if
that was toggled, and a closing "Full Time" summary totting up all the XP
earned along the way. `.participateInChant` and `.contributeToTifo` are
only ever recorded from inside this flow now.

Every match gets a chant (`ContentRepository.chantOfTheDay`, a stable
hash-pick from `chants.json` so the same match always sings the same one),
but only roughly 1 in 4 get a tifo (`MatchDayContentPlanner.isTifoPrepared`)
— tifos are an occasional, planned production, not something a crew puts on
every week the way a chant happens every game. `ChantDetailView` and
`TifoGalleryView`/`TifoDetailView` are now read-only reference screens: the
Chants tab is just a lyrics library, and the Gallery marks which displays
are "Planned" for one of the favorite club's upcoming matches (tapping one
takes you to that match, where raising it actually happens) versus not
currently planned for anything upcoming.

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
