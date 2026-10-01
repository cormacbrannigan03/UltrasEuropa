import GoogleMobileAds
import SwiftUI

/// A single anchored adaptive banner ad, bridged into SwiftUI. Needs a
/// real `UIViewController` to attach to (for ad-tap full-screen
/// presentation), which `UIViewControllerRepresentable` provides for
/// free — there's no SwiftUI-native banner API in the Google Mobile Ads
/// SDK.
struct BannerAdView: UIViewControllerRepresentable {
    var adUnitID: String = AdsManager.AdUnitID.banner

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let adSize = currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = controller

        controller.view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            banner.topAnchor.constraint(equalTo: controller.view.topAnchor),
        ])
        controller.view.frame = CGRect(origin: .zero, size: adSize.size)
        banner.load(Request())
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
