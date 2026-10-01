import SwiftUI
import SwiftData

@main
struct UltrasEuropaApp: App {
    let modelContainer: ModelContainer = ModelContainerFactory.make()

    init() {
        AdsManager.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
