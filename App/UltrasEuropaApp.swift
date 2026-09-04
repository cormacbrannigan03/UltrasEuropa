import SwiftUI
import SwiftData

@main
struct UltrasEuropaApp: App {
    let modelContainer: ModelContainer = ModelContainerFactory.make()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
