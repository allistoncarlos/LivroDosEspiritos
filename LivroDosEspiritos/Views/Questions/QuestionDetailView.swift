import SwiftUI

struct QuestionDetailView: View {
    let question: Question

    @State private var isPreparingShare = false
    @State private var shareErrorMessage: String?

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
        .bookTypography()
        .navigationTitle("Pergunta \(question.number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shareToInstagramStories()
                } label: {
                    if isPreparingShare {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .disabled(isPreparingShare)
                .accessibilityLabel("Compartilhar no Instagram Stories")
            }
        }
        .alert("Não foi possível compartilhar", isPresented: Binding(
            get: { shareErrorMessage != nil },
            set: { if !$0 { shareErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { shareErrorMessage = nil }
        } message: {
            Text(shareErrorMessage ?? "")
        }
        .onAppear {
            AnalyticsService.track(AnalyticsEvent.perguntaVisualizada, properties: [
                "pergunta_numero": question.number,
                "capitulo_numero": question.chapterNumber,
                "parte_titulo": question.partTitle
            ])
        }
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

    @MainActor
    private func shareToInstagramStories() {
        guard !isPreparingShare else { return }
        isPreparingShare = true

        Task { @MainActor in
            defer { isPreparingShare = false }

            guard let image = InstagramStoriesShareService.renderShareImage(for: question) else {
                shareErrorMessage = "Falha ao montar o card da pergunta."
                return
            }

            let outcome = InstagramStoriesShareService.shareToStories(image: image)
            switch outcome {
            case .openedInstagramStories:
                AnalyticsService.track(AnalyticsEvent.perguntaCompartilhadaInstagram, properties: [
                    "pergunta_numero": question.number,
                    "modo": "stories"
                ])
            case .systemShareFallback:
                InstagramStoriesShareService.presentSystemShareSheet(image: image)
                AnalyticsService.track(AnalyticsEvent.perguntaCompartilhadaInstagram, properties: [
                    "pergunta_numero": question.number,
                    "modo": "sistema"
                ])
            case .failed(let message):
                shareErrorMessage = message
            }
        }
    }
}
