import Foundation
import UltrasEuropaCore

/// All bundled, static reference content — leagues, clubs, the player's
/// generic chant/tifo/inventory/achievement/task catalogs. Loaded once from
/// the app bundle's JSON files (see `App/Resources/Content/`) and treated
/// as read-only for the lifetime of the app.
///
/// Match schedules are deliberately NOT part of this static content — see
/// `matchesInLeague(_:asOf:)`. Each league's full season is generated fresh
/// on demand from an `asOf` date, because that date is now a per-save,
/// player-advanced "season clock" (`CharacterStore.simulatedDate`), not a
/// single value fixed at app launch — see `CharacterStore.simulateDays`.
struct ContentRepository {
    let leagues: [League]
    let clubs: [Club]
    let chants: [Chant]
    let tifoPhotos: [TifoPhoto]
    let inventoryCatalog: [InventoryItem]
    let achievementCatalog: [Achievement]
    let tasks: [ChallengeTask]
    let crewMembers: [CrewMember]
    let clothingItems: [ClothingItem]
    let storeProducts: [StoreProduct]

    static func loadFromBundle(_ bundle: Bundle = .main) -> ContentRepository {
        ContentRepository(
            leagues: load([League].self, "leagues", bundle: bundle),
            clubs: load([Club].self, "clubs", bundle: bundle),
            chants: load([Chant].self, "chants", bundle: bundle),
            tifoPhotos: load([TifoPhoto].self, "tifo_photos", bundle: bundle),
            inventoryCatalog: load([InventoryItem].self, "inventory_catalog", bundle: bundle),
            achievementCatalog: load([Achievement].self, "achievements_catalog", bundle: bundle),
            tasks: load([ChallengeTask].self, "tasks", bundle: bundle),
            crewMembers: load([CrewMember].self, "crew_members", bundle: bundle),
            clothingItems: load([ClothingItem].self, "clothing_items", bundle: bundle),
            storeProducts: load([StoreProduct].self, "store_products", bundle: bundle)
        )
    }

    private static func load<T: Decodable>(_ type: T.Type, _ filename: String, bundle: Bundle) -> T {
        // Try a "Content" subdirectory first (folder reference), then the
        // bundle root (plain group membership) — XcodeGen/Xcode can lay the
        // bundled files out either way depending on how the folder is added.
        let url = bundle.url(forResource: filename, withExtension: "json", subdirectory: "Content")
            ?? bundle.url(forResource: filename, withExtension: "json")

        guard let url else {
            fatalError("Missing bundled content file: \(filename).json")
        }

        do {
            let data = try Data(contentsOf: url)
            return try ContentDecoding.decode(T.self, from: data)
        } catch {
            fatalError("Failed to decode \(filename).json: \(error)")
        }
    }

    // MARK: - Lookups

    func league(id: String) -> League? {
        leagues.first { $0.id == id }
    }

    func club(id: String) -> Club? {
        clubs.first { $0.id == id }
    }

    func clubsInLeague(_ leagueId: String) -> [Club] {
        clubs.filter { $0.leagueId == leagueId }.sorted { $0.name < $1.name }
    }

    /// Generates `leagueId`'s full season fresh, as of `date` — see the
    /// type-level doc comment for why this isn't cached.
    func matchesInLeague(_ leagueId: String, asOf date: Date, calendar: Calendar = .current) -> [Match] {
        guard let league = league(id: leagueId) else { return [] }
        return SeasonScheduleGenerator.generateSeason(
            league: league, clubs: clubsInLeague(leagueId), today: date, calendar: calendar
        )
    }

    func matchesForClub(_ clubId: String, asOf date: Date, calendar: Calendar = .current) -> [Match] {
        guard let club = club(id: clubId) else { return [] }
        return matchesInLeague(club.leagueId, asOf: date, calendar: calendar)
            .filter { $0.homeClubId == clubId || $0.awayClubId == clubId }
    }

    func inventoryItem(id: String) -> InventoryItem? {
        inventoryCatalog.first { $0.id == id }
    }

    func achievement(id: String) -> Achievement? {
        achievementCatalog.first { $0.id == id }
    }

    func task(id: String) -> ChallengeTask? {
        tasks.first { $0.id == id }
    }

    func crewMember(id: String) -> CrewMember? {
        crewMembers.first { $0.id == id }
    }

    func crewMembersInRank(_ rank: Rank) -> [CrewMember] {
        crewMembers.filter { $0.rank == rank }
    }

    func clothingItem(id: String) -> ClothingItem? {
        clothingItems.first { $0.id == id }
    }

    func clothingItemsInSlot(_ slot: ClothingSlot) -> [ClothingItem] {
        clothingItems.filter { $0.slot == slot }
    }

    func storeProduct(kind: StoreProductKind) -> StoreProduct? {
        storeProducts.first { $0.kind == kind }
    }

    // MARK: - Match day

    /// The chant the crew sings at `matchId` — every match gets one,
    /// deterministically picked so it's stable across app launches (see
    /// `MatchDayContentPlanner`). Used by the match-day cutscene, not the
    /// standalone chant library.
    func chantOfTheDay(matchId: String) -> Chant? {
        guard let index = MatchDayContentPlanner.chantIndex(matchId: matchId, catalogCount: chants.count) else {
            return nil
        }
        return chants[index]
    }

    /// The tifo display prepared for `matchId`, or `nil` if this particular
    /// match doesn't have one — unlike chants, only some matches get a
    /// prepared tifo (see `MatchDayContentPlanner.isTifoPrepared`).
    func preparedTifo(matchId: String) -> TifoPhoto? {
        guard let index = MatchDayContentPlanner.tifoIndex(matchId: matchId, catalogCount: tifoPhotos.count) else {
            return nil
        }
        return tifoPhotos[index]
    }
}
