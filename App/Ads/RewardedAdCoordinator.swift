import GoogleMobileAds
import UIKit

/// Loads and shows a single rewarded ad at a time — backs the Dashboard's
/// "Watch Ad for Bonus XP" button. `CharacterStore` is what actually
/// decides whether the player's earned (and already granted) today's
/// bonus (see `canWatchRewardedAdToday`/`grantRewardedAdBonus`); this
/// coordinator only knows how to load and present the ad itself.
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
