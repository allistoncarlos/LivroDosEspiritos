import SwiftUI
import UIKit

struct MainTabView: View {
    @Environment(BookDataStore.self) private var store
    @State private var selectedTab = 0
    @State private var chaptersNavigationPath = NavigationPath()
    @State private var isPresentingPendingQuestion = false

    var body: some View {
        Group {
            if let book = store.book {
                TabView(selection: $selectedTab) {
                    NavigationStack(path: $chaptersNavigationPath) {
                        PartListView(book: book)
                            .navigationDestination(for: BookPart.self) { part in
                                ChapterListView(part: part)
                            }
                            .navigationDestination(for: BookChapter.self) { chapter in
                                ChapterDetailView(chapter: chapter)
                            }
                            .navigationDestination(for: Question.self) { question in
                                QuestionDetailView(question: question)
                            }
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
        .onAppear {
            presentPendingQuestionIfNeeded()
        }
        .onChange(of: store.book?.title) { _, _ in
            presentPendingQuestionIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            presentPendingQuestionIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPendingQuestion)) { _ in
            presentPendingQuestionIfNeeded()
        }
    }

    private func presentPendingQuestionIfNeeded() {
        guard store.book != nil, !isPresentingPendingQuestion else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard !isPresentingPendingQuestion,
                  let number = PendingQuestionNavigation.peek(),
                  let question = store.question(number: number) else {
                return
            }

            isPresentingPendingQuestion = true
            PendingQuestionNavigation.consume()
            selectedTab = 0
            chaptersNavigationPath = NavigationPath()
            chaptersNavigationPath.append(question)
            isPresentingPendingQuestion = false
        }
    }
}
