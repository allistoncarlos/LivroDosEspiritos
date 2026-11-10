import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(BookDataStore.self) private var store
    @State private var dailyQuestion: Question?
    @State private var isPreparingShare = false
    @State private var shareErrorMessage: String?

    private let rotationStore = DailyQuestionRotationStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                homeHeader
                dailyQuestionSection
                partsSection
            }
            .padding(.top, 8)
            .padding(.bottom)
        }
        .bookTypography()
        .toolbar(.hidden, for: .navigationBar)
        .task {
            loadDailyQuestion()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            loadDailyQuestion()
        }
    }

    private var homeHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("O Livro dos Espíritos")
                .font(.largeTitle.weight(.bold))
                .tracking(-0.5)

            Text("Estude, reflita e avance um capítulo por vez.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var dailyQuestionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pergunta do dia")
                .font(.title2.weight(.bold))
                .padding(.horizontal)

            if let dailyQuestion {
                VStack(alignment: .leading, spacing: 16) {
                    NavigationLink(value: dailyQuestion) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.subheadline.weight(.bold))
                            }

                            Text(dailyQuestion.question)
                                .font(.title3.weight(.medium))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pergunta \(dailyQuestion.number)")
                                    .font(.subheadline.weight(.semibold))
                                Text("Capítulo \(dailyQuestion.chapterNumber) — \(dailyQuestion.chapterTitle)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        trackClick(type: "question")
                    })

                    HStack {
                        Spacer()

                        Button {
                            trackClick(type: "share")
                            shareDailyQuestion()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline.weight(.bold))
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Compartilhar Pergunta do Dia")
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                        .disabled(isPreparingShare)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.24), Color.accentColor.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                }
                .padding(.horizontal)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
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
    }

    @MainActor
    private func shareDailyQuestion() {
        guard let dailyQuestion, !isPreparingShare else { return }
        isPreparingShare = true

        Task { @MainActor in
            defer { isPreparingShare = false }

            guard let image = InstagramStoriesShareService.renderShareImage(
                for: dailyQuestion,
                isDailyQuestion: true
            ) else {
                shareErrorMessage = "Falha ao montar o card da pergunta do dia."
                return
            }

            InstagramStoriesShareService.presentSystemShareSheet(
                image: image,
                message: InstagramStoriesShareService.message(for: dailyQuestion, isDailyQuestion: true)
            )
        }
    }

    private var partsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Continue seu estudo")
                .font(.title2.weight(.bold))
                .padding(.horizontal)

            Text("Escolha uma parte para explorar os capítulos e perguntas.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(store.book?.parts ?? []) { part in
                    NavigationLink(value: part) {
                        PartCard(part: part)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        trackClick(type: clickType(for: part.number))
                    })
                }
            }
            .padding(.horizontal)
        }
    }

    private func trackClick(type: String) {
        AnalyticsService.track(AnalyticsEvent.clique, properties: ["type": type])
    }

    private func clickType(for partNumber: Int) -> String {
        switch partNumber {
        case 1: "firstPart"
        case 2: "secondPart"
        case 3: "thirdPart"
        case 4: "fourthPart"
        default: "part\(partNumber)"
        }
    }

    private func loadDailyQuestion() {
        guard store.book != nil else { return }
        let number = rotationStore.questionForToday()
        dailyQuestion = store.question(number: number)
    }
}

private struct PartCard: View {
    let part: BookPart

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("PARTE \(part.number)")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(Color.accentColor)

                    Text(part.title)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .padding(8)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
            }

            Label("\(part.chapters.count) capítulos", systemImage: "book.closed")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(description(for: part.number))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, minHeight: 175, alignment: .topLeading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.18), Color.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.accentColor.opacity(0.18), lineWidth: 1)
        }
    }

    private func description(for number: Int) -> String {
        switch number {
        case 1: "Investiga Deus, a criação e os princípios do Universo."
        case 2: "Apresenta a origem, a natureza e a evolução dos Espíritos."
        case 3: "Reúne as leis morais que orientam o progresso humano."
        case 4: "Reflete sobre esperanças, consolações e o futuro espiritual."
        default: "Explore os capítulos e perguntas desta parte do livro."
        }
    }
}
