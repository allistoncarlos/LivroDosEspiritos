import SwiftUI

struct QuestionBrowserView: View {
    @Environment(BookDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedQuestionNumber: Int
    @State private var query = ""

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchResults: [SearchResult] {
        store.search(query)
    }

    var body: some View {
        NavigationStack {
            List {
                if trimmedQuery.isEmpty {
                    catalogSections
                } else if searchResults.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    ForEach(searchResults) { result in
                        questionButton(result.question)
                    }
                }
            }
            .navigationTitle("Perguntas")
            .searchable(text: $query, prompt: "Pergunta, tema…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var catalogSections: some View {
        if let book = store.book {
            ForEach(book.parts) { part in
                Section(part.title) {
                    ForEach(part.chapters) { chapter in
                        Section(chapter.displayTitle) {
                            ForEach(store.questions(for: chapter)) { question in
                                questionButton(question)
                            }
                        }
                    }
                }
            }
        }
    }

    private func questionButton(_ question: Question) -> some View {
        Button {
            selectedQuestionNumber = question.number
            WatchLastQuestionStore.lastQuestionNumber = question.number
            dismiss()
        } label: {
            Text("\(question.number). \(question.question)")
                .font(.caption2)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
    }
}
