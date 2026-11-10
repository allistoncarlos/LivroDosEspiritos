import SwiftUI

struct QuestionDetailView: View {
    let question: Question

    @State private var isPreparingShare = false
    @State private var shareErrorMessage: String?

    private enum ShareDestination {
        case stories
        case message
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                questionBlock

                if question.hasAnswer || question.isSpiritAnswerInCommentary {
                    answerBlock
                }

                if question.hasCommentary && !question.isSpiritAnswerInCommentary {
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
                Menu {
                    Button {
                        shareQuestion(to: .stories)
                    } label: {
                        Label("Instagram Story", systemImage: "camera.aperture")
                    }

                    Button {
                        shareQuestion(to: .message)
                    } label: {
                        Label("Mensagem…", systemImage: "message")
                    }
                } label: {
                    if isPreparingShare {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .disabled(isPreparingShare)
                .accessibilityLabel("Compartilhar pergunta")
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
            Label(
                question.isExpository ? "Texto" : "Pergunta",
                systemImage: question.isExpository ? "text.book.closed" : "questionmark.circle"
            )
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
            Text(question.hasAnswer ? question.answer : question.commentary)
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
    private func shareQuestion(to destination: ShareDestination) {
        guard !isPreparingShare else { return }
        isPreparingShare = true

        Task { @MainActor in
            defer { isPreparingShare = false }

            guard let image = InstagramStoriesShareService.renderShareImage(for: question) else {
                shareErrorMessage = "Falha ao montar o card da pergunta."
                return
            }

            switch destination {
            case .stories:
                let outcome = InstagramStoriesShareService.shareToStories(image: image)
                switch outcome {
                case .openedInstagramStories:
                    AnalyticsService.track(AnalyticsEvent.perguntaCompartilhadaInstagram, properties: [
                        "pergunta_numero": question.number,
                        "modo": "stories"
                    ])
                case .systemShareFallback:
                    InstagramStoriesShareService.presentSystemShareSheet(
                        image: image,
                        message: InstagramStoriesShareService.message(for: question)
                    )
                    AnalyticsService.track(AnalyticsEvent.perguntaCompartilhadaInstagram, properties: [
                        "pergunta_numero": question.number,
                        "modo": "sistema"
                    ])
                case .failed(let message):
                    shareErrorMessage = message
                }
            case .message:
                InstagramStoriesShareService.presentSystemShareSheet(
                    image: image,
                    message: InstagramStoriesShareService.message(for: question)
                )
                AnalyticsService.track(AnalyticsEvent.perguntaCompartilhadaInstagram, properties: [
                    "pergunta_numero": question.number,
                    "modo": "mensagem"
                ])
            }
        }
    }
}
