import Foundation
import UltrasEuropaCore

/// All bundled, static reference content — leagues, clubs, the player's
/// generic chant/tifo/inventory/achievement/task catalogs — plus every
/// league's full season schedule, generated once at load time rather than
/// shipped as static data (see `SeasonScheduleGenerator`). Loaded once from
/// the app bundle's JSON files (see `App/Resources/Content/`) and treated
/// as read-only for the lifetime of the app.
struct ContentRepository {
    let leagues: [League]
    let clubs: [Club]
    let chants: [Chant]
    let tifoPhotos: [TifoPhoto]
    let inventoryCatalog: [InventoryItem]
    let achievementCatalog: [Achievement]
    let tasks: [ChallengeTask]
    let crewMembers: [CrewMember]
    /// Each league's full generated double round-robin season, keyed by league id.
    let matchesByLeagueId: [String: [Match]]

    static func loadFromBundle(_ bundle: Bundle = .main, today: Date = .now) -> ContentRepository {
        let leagues = load([League].self, "leagues", bundle: bundle)
        let clubs = load([Club].self, "clubs", bundle: bundle)

        var matchesByLeagueId: [String: [Match]] = [:]
        for league in leagues {
            let leagueClubs = clubs.filter { $0.leagueId == league.id }
            matchesByLeagueId[league.id] = SeasonScheduleGenerator.generateSeason(
                league: league, clubs: leagueClubs, today: today
            )
        }

        return ContentRepository(
            leagues: leagues,
            clubs: clubs,
            chants: load([Chant].self, "chants", bundle: bundle),
            tifoPhotos: load([TifoPhoto].self, "tifo_photos", bundle: bundle),
            inventoryCatalog: load([InventoryItem].self, "inventory_catalog", bundle: bundle),
            achievementCatalog: load([Achievement].self, "achievements_catalog", bundle: bundle),
            tasks: load([ChallengeTask].self, "tasks", bundle: bundle),
            crewMembers: load([CrewMember].self, "crew_members", bundle: bundle),
            matchesByLeagueId: matchesByLeagueId
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

    func matchesInLeague(_ leagueId: String) -> [Match] {
        matchesByLeagueId[leagueId] ?? []
    }

    func matchesForClub(_ clubId: String) -> [Match] {
        guard let club = club(id: clubId) else { return [] }
        return matchesInLeague(club.leagueId).filter { $0.homeClubId == clubId || $0.awayClubId == clubId }
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
}
