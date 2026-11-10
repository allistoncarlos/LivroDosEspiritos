import SwiftUI

struct SearchView: View {
    @Environment(BookDataStore.self) private var store
    @Environment(\.isSearching) private var isSearching
    @Binding private var query: String
    private let installsSearchField: Bool
    private let showsCustomEmptyState: Bool

    init(
        query: Binding<String>,
        installsSearchField: Bool = true,
        showsCustomEmptyState: Bool = true
    ) {
        _query = query
        self.installsSearchField = installsSearchField
        self.showsCustomEmptyState = showsCustomEmptyState
    }

    private var results: [SearchResult] {
        store.search(query)
    }

    var body: some View {
        Group {
            if installsSearchField {
                searchableContent
            } else {
                content
            }
        }
        .bookTypography()
    }

    private var content: some View {
        List {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if showsCustomEmptyState {
                    SearchEmptyState(
                        isSearching: isSearching,
                        onSuggestionSelected: { suggestion in
                            query = suggestion
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 36, leading: 20, bottom: 24, trailing: 20))
                    .listRowBackground(Color.clear)
                }
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(results) { result in
                        NavigationLink(value: result.question) {
                            SearchResultRow(result: result)
                        }
                    }
                } header: {
                    Text(resultsSummary)
                        .textCase(nil)
                }
            }
        }
        .bookTypography()
        .listStyle(.plain)
        .navigationTitle("Busca")
        .navigationDestination(for: Question.self) { question in
            QuestionDetailView(question: question)
        }
        .task(id: query) {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }

            AnalyticsService.track(AnalyticsEvent.buscaRealizada, properties: [
                "tamanho_termo": trimmed.count,
                "resultados": results.count
            ])
        }
    }

    private var searchableContent: some View {
        content
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Pergunta, resposta ou tema"
            )
            .searchSuggestions {
                SearchSuggestionList(query: $query)
            }
            .modifier(SearchPresentationModifier())
    }

    private var resultsSummary: String {
        results.count == 1 ? "1 resultado" : "\(results.count) resultados"
    }
}

struct SearchPresentationModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .searchPresentationToolbarBehavior(.avoidHidingContent)
        } else {
            content
        }
    }
}

struct SearchSuggestionList: View {
    @Binding var query: String

    private let suggestions = ["Deus", "Espíritos", "Leis morais", "Vida futura"]

    var body: some View {
        Group {
            if query.isEmpty {
                Section("Sugestões") {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            query = suggestion
                        } label: {
                            Label(suggestion, systemImage: "magnifyingglass")
                        }
                    }
                }
            }
        }
        .bookTypography()
    }
}

private struct SearchEmptyState: View {
    let isSearching: Bool
    let onSuggestionSelected: (String) -> Void

    private let suggestions = ["Deus", "Espíritos", "Leis morais", "Vida futura"]

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 72, height: 72)
                .background(Color.accentColor.opacity(0.12), in: Circle())

            VStack(spacing: 7) {
                Text("Encontre uma reflexão")
                    .font(.title3.weight(.semibold))

                Text("Pesquise por número, palavra-chave, tema ou trecho das respostas e comentários.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !isSearching {
                VStack(spacing: 10) {
                    Text("Experimente buscar por")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                onSuggestionSelected(suggestion)
                            }
                            .font(.footnote.weight(.medium))
                            .buttonStyle(.bordered)
                            .tint(.accentColor)
                        }
                    }
                }
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .bookTypography()
    }
}

struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Pergunta \(result.question.number)")
                        .font(.headline)
                    Text("Capítulo \(result.question.chapterNumber) — \(result.question.chapterTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            Text(result.question.question)
                .font(.subheadline)
                .lineLimit(2)

            Text(result.question.previewText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(result.matchedFields.joined(separator: " · "))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .bookTypography()
    }
}
