import SwiftUI

struct SearchView: View {
    @Environment(BookDataStore.self) private var store
    @State private var query = ""

    private var results: [SearchResult] {
        store.search(query)
    }

    var body: some View {
        List {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView(
                    "Buscar no Livro dos Espíritos",
                    systemImage: "text.magnifyingglass",
                    description: Text("Pesquise por número, palavra-chave, tema ou trecho das respostas e comentários.")
                )
                .listRowBackground(Color.clear)
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
                    .listRowBackground(Color.clear)
            } else {
                Section("\(results.count) resultado(s)") {
                    ForEach(results) { result in
                        NavigationLink(value: result.question) {
                            SearchResultRow(result: result)
                        }
                    }
                }
            }
        }
        .navigationTitle("Busca")
        .searchable(text: $query, prompt: "Pergunta, resposta, tema…")
        .navigationDestination(for: Question.self) { question in
            QuestionDetailView(question: question)
        }
    }
}

struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Pergunta \(result.question.number)")
                    .font(.headline)
                Spacer()
                Text(result.matchedFields.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(result.question.question)
                .font(.subheadline)
                .lineLimit(2)

            Text(result.question.previewText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text("\(result.question.partTitle) • Cap. \(result.question.chapterNumber)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
