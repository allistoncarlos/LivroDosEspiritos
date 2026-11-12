import Foundation
import Observation

@MainActor
@Observable
final class BookDataStore {
    private struct LoadResult {
        let book: BookData?
        let errorMessage: String?
    }

    private(set) var book: BookData?
    private(set) var loadError: String?
    private var questionsByNumber: [Int: Question] = [:]

    init() {}

    func load() async {
        guard book == nil else { return }

        let result = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: Self.decodeBook())
            }
        }

        if let decoded = result.book {
            book = decoded
            questionsByNumber = Dictionary(uniqueKeysWithValues: decoded.questions.map { ($0.number, $0) })
            loadError = nil
        } else {
            loadError = result.errorMessage
        }
    }

    private nonisolated static func decodeBook() -> LoadResult {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            return LoadResult(book: nil, errorMessage: "Arquivo questions.json não encontrado no bundle.")
        }

        do {
            let data = try Data(contentsOf: url)
            return LoadResult(book: try JSONDecoder().decode(BookData.self, from: data), errorMessage: nil)
        } catch {
            return LoadResult(book: nil, errorMessage: "Falha ao carregar o livro: \(error.localizedDescription)")
        }
    }

    func question(number: Int) -> Question? {
        questionsByNumber[number]
    }

    struct QuestionNavigationContext: Hashable {
        let part: BookPart
        let chapter: BookChapter
        let question: Question
    }

    func navigationContext(for questionNumber: Int) -> QuestionNavigationContext? {
        guard let question = question(number: questionNumber),
              let book,
              let part = book.parts.first(where: { $0.number == question.partNumber }),
              let chapter = part.chapters.first(where: { $0.id == question.chapterId }) else {
            return nil
        }

        return QuestionNavigationContext(part: part, chapter: chapter, question: question)
    }

    func questions(for chapter: BookChapter) -> [Question] {
        guard let book else { return [] }
        return book.questions.filter { $0.chapterId == chapter.id }
    }

    func sectionGroups(for chapter: BookChapter) -> [SectionGroup] {
        let chapterQuestions = questions(for: chapter)
        var groups: [SectionGroup] = []
        var currentTitle = ""
        var currentQuestions: [Question] = []

        for question in chapterQuestions {
            let sectionTitle = question.section.isEmpty ? "Geral" : question.section
            if sectionTitle != currentTitle, !currentQuestions.isEmpty {
                groups.append(SectionGroup(title: currentTitle, questions: currentQuestions))
                currentQuestions = []
            }
            currentTitle = sectionTitle
            currentQuestions.append(question)
        }

        if !currentQuestions.isEmpty {
            groups.append(SectionGroup(title: currentTitle, questions: currentQuestions))
        }

        return groups
    }

    func search(_ query: String) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let book else { return [] }

        let terms = trimmed
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .split(separator: " ")
            .map(String.init)

        return book.questions.compactMap { question in
            var matched: [String] = []

            if matches(question.question, terms: terms) { matched.append("Pergunta") }
            if matches(question.answer, terms: terms) { matched.append("Resposta") }
            if matches(question.commentary, terms: terms) { matched.append("Comentário") }
            if question.notes.contains(where: { matches($0.text, terms: terms) }) {
                matched.append("Nota")
            }
            if matches(question.section, terms: terms) { matched.append("Seção") }
            if matches(question.chapterTitle, terms: terms) { matched.append("Capítulo") }
            if matches("\(question.number)", terms: terms) { matched.append("Número") }

            return matched.isEmpty ? nil : SearchResult(question: question, matchedFields: matched)
        }
    }

    private func matches(_ text: String, terms: [String]) -> Bool {
        guard !text.isEmpty else { return false }
        let normalized = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return terms.allSatisfy { normalized.contains($0) }
    }
}
