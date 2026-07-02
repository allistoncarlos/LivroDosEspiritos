import SwiftUI

@main
struct LivroDosEspiritosWatchApp: App {
    @State private var store = BookDataStore()

    var body: some Scene {
        WindowGroup {
            QuestionReaderView()
                .environment(store)
        }
    }
}
