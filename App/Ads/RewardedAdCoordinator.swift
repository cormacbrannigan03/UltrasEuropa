import GoogleMobileAds
import UIKit

/// Loads and shows a single rewarded ad at a time — backs the Full Time
/// screen's "Watch Ad to Double XP" button (`MatchDayCutsceneView`),
/// which decides what the reward actually is (doubling that match's XP
/// via `CharacterStore.grantBonusXP`); this coordinator only knows how to
/// load and present the ad itself.
@MainActor
@Observable
final class RewardedAdCoordinator: NSObject {
    private var rewardedAd: RewardedAd?

    var isReady: Bool { rewardedAd != nil }

    func load() async {
        do {
            rewardedAd = try await RewardedAd.load(with: AdsManager.AdUnitID.rewarded, request: Request())
            rewardedAd?.fullScreenContentDelegate = self
        } catch {
            rewardedAd = nil
        }
    }

    /// Shows the loaded rewarded ad if one's ready, calling `onReward`
    /// only once the player actually watches it through to completion —
    /// a no-op (no reward) if nothing's loaded yet.
    func show(onReward: @escaping () -> Void) {
        guard let rewardedAd, let presenter = AdsManager.topViewController else { return }
        rewardedAd.present(from: presenter) {
            onReward()
        }
    }
}

extension RewardedAdCoordinator: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        rewardedAd = nil
        Task { await load() }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardedAd = nil
    }
}
