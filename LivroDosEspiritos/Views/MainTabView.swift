import SwiftUI

struct MainTabView: View {
    @Environment(BookDataStore.self) private var store
    @Environment(NotificationHandler.self) private var notificationHandler
    @State private var selectedTab = 0
    @State private var chaptersNavigationPath = NavigationPath()

    var body: some View {
        Group {
            if let book = store.book {
                TabView(selection: $selectedTab) {
                    NavigationStack(path: $chaptersNavigationPath) {
                        PartListView(book: book)
                    }
                    .tabItem {
                        Label("Capítulos", systemImage: "books.vertical")
                    }
                    .tag(0)

                    NavigationStack {
                        SearchView()
                    }
                    .tabItem {
                        Label("Busca", systemImage: "magnifyingglass")
                    }
                    .tag(1)

                    NavigationStack {
                        DailyQuestionSettingsView()
                    }
                    .tabItem {
                        Label("Notificações", systemImage: "bell")
                    }
                    .tag(2)
                }
            } else if let error = store.loadError {
                ContentUnavailableView(
                    "Não foi possível carregar",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                ProgressView("Carregando…")
            }
        }
        .onChange(of: notificationHandler.pendingQuestionNumber) { _, number in
            openQuestionFromNotification(number: number)
        }
        .onChange(of: store.book?.title) { _, _ in
            openQuestionFromNotification(number: notificationHandler.pendingQuestionNumber)
        }
        .onAppear {
            openQuestionFromNotification(number: notificationHandler.pendingQuestionNumber)
        }
    }

    private func openQuestionFromNotification(number: Int?) {
        guard let number,
              let context = store.navigationContext(for: number) else {
            return
        }

        selectedTab = 0
        var path = NavigationPath()
        path.append(context.part)
        path.append(context.chapter)
        path.append(context.question)
        chaptersNavigationPath = path
        notificationHandler.clearPendingNavigation()
    }
}
