import GoogleMobileAds
import UIKit

/// Loads and shows a single interstitial ad at a time — used at the one
/// natural break point in the match-day flow (the Full Time summary; see
/// `MatchDayCutsceneView`), which also decides how often it actually
/// shows one (not every match — see that view's frequency cap) so this
/// coordinator only ever has to answer "is one ready, and show it."
@MainActor
@Observable
final class InterstitialAdCoordinator: NSObject {
    private var interstitial: InterstitialAd?

    func load() async {
        do {
            interstitial = try await InterstitialAd.load(with: AdsManager.AdUnitID.interstitial, request: Request())
            interstitial?.fullScreenContentDelegate = self
        } catch {
            interstitial = nil
        }
    }

    /// Shows the loaded interstitial if one's ready, from the app's
    /// current root view controller — a no-op otherwise (e.g. still
    /// loading, or the previous load failed), so a caller never needs to
    /// check readiness itself first.
    func showIfReady() {
        guard let interstitial, let presenter = AdsManager.topViewController else { return }
        interstitial.present(from: presenter)
    }
}

extension InterstitialAdCoordinator: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitial = nil
        Task { await load() }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitial = nil
    }
}
