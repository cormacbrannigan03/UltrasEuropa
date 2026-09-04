import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Dashboard", systemImage: "person.fill") }

            NavigationStack { ClubDirectoryView() }
                .tabItem { Label("Clubs", systemImage: "shield.fill") }

            NavigationStack { MatchScheduleView() }
                .tabItem { Label("Matches", systemImage: "sportscourt.fill") }

            NavigationStack { ChantsLibraryView() }
                .tabItem { Label("Chants", systemImage: "music.mic") }

            NavigationStack { TifoGalleryView() }
                .tabItem { Label("Gallery", systemImage: "photo.on.rectangle.angled") }
        }
        .tint(Theme.accent)
    }
}
