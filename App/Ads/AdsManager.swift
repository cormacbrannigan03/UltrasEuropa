import Foundation
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

/// Centralizes Google Mobile Ads (AdMob) setup for the whole app: GDPR/UK
/// consent via the UMP SDK, then starting the Mobile Ads SDK itself, plus
/// the ad unit IDs every ad surface (`BannerAdView`,
/// `InterstitialAdCoordinator`, `RewardedAdCoordinator`) reads from.
enum AdsManager {
    /// Flip back to `true` (and the AdMob App ID in Info.plist back to
    /// Google's sample one) if real ads ever need to come down for
    /// testing — this app's own AdMob app/ad units now exist (created
    /// 1 Oct 2026, app ID ca-app-pub-9676786622570370~8925541395), so
    /// real ads are live. Google's docs on test ads either way:
    /// https://developers.google.com/admob/ios/test-ads
    private static let isUsingTestAdUnits = false

    enum AdUnitID {
        static let banner = isUsingTestAdUnits
            ? "ca-app-pub-3940256099942544/2934735716"
            : "ca-app-pub-9676786622570370/5409053938"
        static let interstitial = isUsingTestAdUnits
            ? "ca-app-pub-3940256099942544/4411468910"
            : "ca-app-pub-9676786622570370/4986296389"
        static let rewarded = isUsingTestAdUnits
            ? "ca-app-pub-3940256099942544/1712485313"
            : "ca-app-pub-9676786622570370/5669831820"
    }

    /// Call once at app launch (see `UltrasEuropaApp`). Requests an
    /// up-to-date GDPR/UK consent status from the UMP SDK and shows a
    /// consent form if the player's region requires one, then starts the
    /// Mobile Ads SDK — which is what actually allows any ad request to
    /// go out — only after consent is resolved one way or another, so a
    /// slow or failed consent fetch can never result in ads loading
    /// without it ever being asked for.
    static func start() {
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false

        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { requestError in
            guard requestError == nil else {
                // Couldn't reach Google's consent service (e.g. offline on
                // first launch) — fall back to starting the SDK as-is
                // rather than permanently blocking ads over a network
                // blip; it will ask again on the next launch.
                MobileAds.shared.start(completionHandler: nil)
                return
            }
            UMPConsentForm.loadAndPresentIfRequired(from: topViewController) { _ in
                MobileAds.shared.start(completionHandler: nil)
            }
        }
    }

    /// The current key window's root view controller — needed to present
    /// the UMP consent form and any full-screen ad (interstitial/
    /// rewarded), none of which have a SwiftUI-native presentation API.
    static var topViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    /// Shows an interstitial after roughly every third clean Full Time
    /// screen (see `MatchDayCutsceneView.summaryCard`) rather than every
    /// single one, so ad breaks don't dominate the between-match flow.
    /// Each call both checks and advances the counter — call it exactly
    /// once per eligible match, not on every re-render.
    static func shouldShowInterstitialAfterMatch() -> Bool {
        let key = "AdsManager.matchesSinceLastInterstitial"
        let count = UserDefaults.standard.integer(forKey: key) + 1
        guard count >= 3 else {
            UserDefaults.standard.set(count, forKey: key)
            return false
        }
        UserDefaults.standard.set(0, forKey: key)
        return true
    }
}
