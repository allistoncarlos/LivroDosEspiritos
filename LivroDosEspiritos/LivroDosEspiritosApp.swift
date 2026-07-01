import SwiftUI

@main
struct LivroDosEspiritosApp: App {
    @State private var store = BookDataStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(store)
        }
    }
}
