import SwiftUI

struct ChapterDetailView: View {
    @Environment(BookDataStore.self) private var store
    let chapter: BookChapter

    var body: some View {
        List {
            ForEach(store.sectionGroups(for: chapter)) { group in
                Section(group.title) {
                    ForEach(group.questions) { question in
                        NavigationLink(value: question) {
                            QuestionRowView(question: question)
                        }
                    }
                }
            }
        }
        .navigationTitle("Cap. \(chapter.chapterRoman)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct QuestionRowView: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(question.number). \(question.question)")
                .font(.body)
                .lineLimit(3)

            if question.hasAnswer {
                Text(question.answer)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else if question.hasCommentary {
                Text(question.commentary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if question.hasNotes {
                Label("\(question.notes.count) nota(s)", systemImage: "note.text")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
