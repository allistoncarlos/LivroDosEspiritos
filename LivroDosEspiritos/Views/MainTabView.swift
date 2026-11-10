import SwiftUI
import UIKit

struct MainTabView: View {
    @Environment(BookDataStore.self) private var store
    @State private var selectedTab = AppTab.book
    @State private var searchText = ""
    @State private var chaptersNavigationPath = NavigationPath()
    @State private var isPresentingPendingQuestion = false

    private enum AppTab: Hashable {
        case book
        case search
        case settings
    }

    var body: some View {
        Group {
            if store.book != nil {
                appTabs
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
            _ = PendingQuestionNavigation.consume()
            selectedTab = .book
            chaptersNavigationPath = NavigationPath()
            chaptersNavigationPath.append(question)
            isPresentingPendingQuestion = false
        }
    }

    @ViewBuilder
    private var appTabs: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $selectedTab) {
                Tab("Livro", systemImage: "books.vertical", value: .book) {
                    bookNavigation
                }

                Tab(value: .search, role: .search) {
                    NavigationStack {
                        SearchView(
                            query: $searchText,
                            installsSearchField: false,
                            showsCustomEmptyState: false
                        )
                    }
                }

                Tab("Ajustes", systemImage: "gearshape", value: .settings) {
                    NavigationStack {
                        DailyQuestionSettingsView()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Pergunta, resposta ou tema")
            .searchSuggestions {
                SearchSuggestionList(query: $searchText)
            }
            .tabViewSearchActivation(.searchTabSelection)
            .modifier(SearchPresentationModifier())
        } else {
            TabView(selection: $selectedTab) {
                bookNavigation
                    .tabItem {
                        Label("Livro", systemImage: "books.vertical")
                    }
                    .tag(AppTab.book)

                NavigationStack {
                    SearchView(query: $searchText)
                }
                .tabItem {
                    Label("Busca", systemImage: "magnifyingglass")
                }
                .tag(AppTab.search)

                NavigationStack {
                    DailyQuestionSettingsView()
                }
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
            }
        }
    }

    private var bookNavigation: some View {
        NavigationStack(path: $chaptersNavigationPath) {
            HomeView()
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
    }
}
