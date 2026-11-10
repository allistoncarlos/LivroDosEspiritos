import SwiftUI

/// Card 9:16 otimizado para Instagram Stories (1080×1920).
struct QuestionShareCardView: View {
    let question: Question
    let isDailyQuestion: Bool

    init(question: Question, isDailyQuestion: Bool = false) {
        self.question = question
        self.isDailyQuestion = isDailyQuestion
    }

    private enum Palette {
        static let bgTop = Color(red: 0.04, green: 0.07, blue: 0.13)
        static let bgBottom = Color(red: 0.10, green: 0.15, blue: 0.27)
        static let gold = Color(red: 0.79, green: 0.66, blue: 0.30)
        static let goldSoft = Color(red: 0.79, green: 0.66, blue: 0.30).opacity(0.55)
        static let text = Color(red: 0.96, green: 0.94, blue: 0.91)
        static let muted = Color(red: 0.66, green: 0.69, blue: 0.75)
        static let quoteBg = Color.white.opacity(0.06)
    }

    var body: some View {
        ZStack {
            background

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 56)

                questionSection

                if showsAnswer {
                    Divider()
                        .overlay(Palette.goldSoft)
                        .padding(.vertical, 36)

                    answerSection
                }

                Spacer(minLength: 40)

                footer
            }
            .padding(.horizontal, 72)
            .padding(.top, 160)
            .padding(.bottom, 180)
        }
        .frame(width: Self.canvasWidth, height: Self.canvasHeight)
    }

    static let canvasWidth: CGFloat = 1080
    static let canvasHeight: CGFloat = 1920

    private var showsAnswer: Bool {
        question.hasAnswer && truncatedAnswer != nil
    }

    private var truncatedQuestion: String {
        Self.clamp(question.question, limit: question.hasAnswer ? 280 : 520)
    }

    private var truncatedAnswer: String? {
        guard question.hasAnswer else { return nil }
        let trimmed = question.answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Self.clamp(trimmed, limit: truncatedQuestion.count > 180 ? 320 : 480)
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.bgTop, Palette.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Palette.gold.opacity(0.14), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 700
            )

            // Vinheta suave nas bordas (zona segura do Stories).
            VStack {
                LinearGradient(colors: [.black.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 140)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 200)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("O LIVRO DOS ESPÍRITOS")
                .font(.system(size: 22, weight: .semibold, design: .default))
                .tracking(3.2)
                .foregroundStyle(Palette.gold)

            Text(isDailyQuestion ? "PERGUNTA DO DIA" : "Pergunta \(question.number)")
                .font(.system(
                    size: isDailyQuestion ? 58 : 54,
                    weight: .bold,
                    design: .serif
                ))
                .foregroundStyle(Palette.text)

            if isDailyQuestion {
                Text("Uma reflexão para hoje")
                    .font(.system(size: 24, weight: .medium, design: .serif))
                    .foregroundStyle(Palette.gold)
            }

            Text("Capítulo \(question.chapterNumber) · \(question.chapterTitle)")
                .font(.system(size: 24, weight: .regular, design: .serif))
                .foregroundStyle(Palette.muted)
                .lineLimit(2)
        }
    }

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("PERGUNTA")
                .font(.system(size: 18, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Palette.goldSoft)

            Text(truncatedQuestion)
                .font(.system(size: 40, weight: .medium, design: .serif))
                .foregroundStyle(Palette.text)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("RESPOSTA DOS ESPÍRITOS")
                .font(.system(size: 18, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Palette.goldSoft)

            Text(truncatedAnswer ?? "")
                .font(.system(size: 34, weight: .regular, design: .serif))
                .foregroundStyle(Palette.text.opacity(0.92))
                .lineSpacing(6)
                .padding(36)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.quoteBg, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Palette.gold.opacity(0.22), lineWidth: 1.5)
                )
        }
    }

    private var footer: some View {
        HStack(spacing: 16) {
            Capsule()
                .fill(Palette.gold)
                .frame(width: 36, height: 3)

            Text("Livro dos Espíritos · iOS")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Palette.muted)

            Spacer(minLength: 0)
        }
    }

    private static func clamp(_ text: String, limit: Int) -> String {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalized.count > limit else { return normalized }

        let end = normalized.index(normalized.startIndex, offsetBy: limit)
        var truncated = String(normalized[..<end])
        if let lastSpace = truncated.lastIndex(of: " ") {
            truncated = String(truncated[..<lastSpace])
        }
        return truncated.trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }
}
