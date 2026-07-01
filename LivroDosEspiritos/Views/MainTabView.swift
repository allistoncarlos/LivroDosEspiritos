import SwiftUI

struct MainTabView: View {
    @Environment(BookDataStore.self) private var store

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
    }
}
