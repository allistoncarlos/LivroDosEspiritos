import SwiftUI

struct QuestionDetailView: View {
    let question: Question

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                questionBlock

                if question.hasAnswer {
                    answerBlock
                }

                if question.hasCommentary {
                    commentaryBlock
                }

                if question.hasNotes {
                    notesBlock
                }
            }
            .padding()
        }
        .navigationTitle("Pergunta \(question.number)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.partTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Capítulo \(question.chapterNumber) — \(question.chapterTitle)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !question.section.isEmpty {
                Text(question.section)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var questionBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pergunta", systemImage: "questionmark.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(question.question)
                .font(.title3.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var answerBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Resposta dos Espíritos", systemImage: "quote.opening")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(question.answer)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var commentaryBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Comentário de Allan Kardec", systemImage: "text.book.closed")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(question.commentary)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notesBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notas e adendos", systemImage: "note.text")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(question.notes) { note in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(note.number). \(note.label)")
                        .font(.subheadline.weight(.semibold))
                    Text(note.text)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
