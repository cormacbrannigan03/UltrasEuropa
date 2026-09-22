import SwiftUI

struct RootTabView: View {
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label(localization.string(.tabDashboard), systemImage: "person.fill") }

            NavigationStack { ClubDirectoryView() }
                .tabItem { Label(localization.string(.tabClubs), systemImage: "shield.fill") }

            NavigationStack { MatchesHomeView() }
                .tabItem { Label(localization.string(.tabMatches), systemImage: "sportscourt.fill") }

            NavigationStack { ChantsLibraryView() }
                .tabItem { Label(localization.string(.tabChants), systemImage: "music.mic") }

            NavigationStack { TifoGalleryView() }
                .tabItem { Label(localization.string(.tabGallery), systemImage: "photo.on.rectangle.angled") }
        }
        .tint(Theme.accent)
    }
}
