import Foundation
import Observation

@MainActor
@Observable
final class BookDataStore {
    private struct LoadResult: Sendable {
        let book: BookData?
        let searchIndex: [SearchDocument]
        let errorMessage: String?
    }

    private var searchIndex: [SearchDocument] = []

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
            searchIndex = result.searchIndex
            questionsByNumber = Dictionary(uniqueKeysWithValues: decoded.questions.map { ($0.number, $0) })
            loadError = nil
        } else {
            loadError = result.errorMessage
        }
    }

    private nonisolated static func decodeBook() -> LoadResult {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            return LoadResult(book: nil, searchIndex: [], errorMessage: "Arquivo questions.json não encontrado no bundle.")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(BookData.self, from: data)
            let searchIndex = decoded.questions.map(SearchDocument.init)
            return LoadResult(book: decoded, searchIndex: searchIndex, errorMessage: nil)
        } catch {
            return LoadResult(book: nil, searchIndex: [], errorMessage: "Falha ao carregar o livro: \(error.localizedDescription)")
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

    func search(_ query: String) async -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !searchIndex.isEmpty else { return [] }

        let terms = trimmed
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .split(separator: " ")
            .map(String.init)

        let index = searchIndex
        let searchTask = Task.detached(priority: .userInitiated) {
            Self.performSearch(terms: terms, index: index)
        }

        return await withTaskCancellationHandler {
            await searchTask.value
        } onCancel: {
            searchTask.cancel()
        }
    }

    private nonisolated static func performSearch(terms: [String], index: [SearchDocument]) -> [SearchResult] {
        var results: [SearchResult] = []
        results.reserveCapacity(32)

        for (index, document) in index.enumerated() {
            if index.isMultiple(of: 16), Task.isCancelled {
                return []
            }

            var matched: [String] = []

            if document.matches(document.questionText, terms: terms) { matched.append("Pergunta") }
            if document.matches(document.answer, terms: terms) { matched.append("Resposta") }
            if document.matches(document.commentary, terms: terms) { matched.append("Comentário") }
            if document.notes.contains(where: { document.matches($0, terms: terms) }) {
                matched.append("Nota")
            }
            if document.matches(document.section, terms: terms) { matched.append("Seção") }
            if document.matches(document.chapterTitle, terms: terms) { matched.append("Capítulo") }
            if document.matches(document.number, terms: terms) { matched.append("Número") }

            if !matched.isEmpty {
                results.append(SearchResult(question: document.question, matchedFields: matched))
            }
        }

        return results
    }
}

private struct SearchDocument: Sendable {
    let question: Question
    let questionText: String
    let answer: String
    let commentary: String
    let notes: [String]
    let section: String
    let chapterTitle: String
    let number: String

    init(question: Question) {
        self.question = question
        questionText = Self.normalize(question.question)
        answer = Self.normalize(question.answer)
        commentary = Self.normalize(question.commentary)
        notes = question.notes.map { Self.normalize($0.text) }
        section = Self.normalize(question.section)
        chapterTitle = Self.normalize(question.chapterTitle)
        number = String(question.number)
    }

    func matches(_ text: String, terms: [String]) -> Bool {
        !text.isEmpty && terms.allSatisfy { text.contains($0) }
    }

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
