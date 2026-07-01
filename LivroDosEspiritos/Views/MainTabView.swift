import SwiftUI

struct MainTabView: View {
    @Environment(BookDataStore.self) private var store
    @Environment(NotificationHandler.self) private var notificationHandler
    @State private var presentedQuestion: Question?

    var body: some View {
        Group {
            if let book = store.book {
                TabView {
                    NavigationStack {
                        PartListView(book: book)
                    }
                    .tabItem {
                        Label("Capítulos", systemImage: "books.vertical")
                    }

                    NavigationStack {
                        SearchView()
                    }
                    .tabItem {
                        Label("Busca", systemImage: "magnifyingglass")
                    }

                    NavigationStack {
                        DailyQuestionSettingsView()
                    }
                    .tabItem {
                        Label("Notificações", systemImage: "bell")
                    }
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
        .sheet(item: $presentedQuestion) { question in
            NavigationStack {
                QuestionDetailView(question: question)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Fechar") {
                                presentedQuestion = nil
                                notificationHandler.clearPendingNavigation()
                            }
                        }
                    }
            }
        }
        .onChange(of: notificationHandler.pendingQuestionNumber) { _, number in
            openQuestion(number: number)
        }
        .onAppear {
            openQuestion(number: notificationHandler.pendingQuestionNumber)
        }
    }

    private func openQuestion(number: Int?) {
        guard let number, let question = store.question(number: number) else { return }
        presentedQuestion = question
    }
}
