import Foundation

struct BookData: Codable {
    let title: String
    let subtitle: String
    let sourcePages: String
    let totalQuestions: Int
    let parts: [BookPart]
    let chapters: [BookChapter]
    let questions: [Question]
}

struct BookPart: Codable, Identifiable, Hashable {
    let number: Int
    let title: String
    let chapters: [BookChapter]

    var id: Int { number }
}

struct BookChapter: Codable, Identifiable, Hashable {
    let id: String
    let partNumber: Int
    let partTitle: String
    let chapterNumber: Int
    let chapterRoman: String
    let title: String
    let sections: [String]
    let questionRange: QuestionRange?
    let questionNumbers: [Int]?

    var displayTitle: String {
        "Capítulo \(chapterRoman) — \(title)"
    }
}

struct QuestionRange: Codable, Hashable {
    let start: Int
    let end: Int
}

struct QuestionNote: Codable, Identifiable, Hashable {
    let number: Int
    let type: String
    let text: String

    var id: Int { number }

    var label: String {
        type == "kardec" ? "Nota de Allan Kardec" : "Nota do Editor"
    }
}

struct Question: Codable, Identifiable, Hashable {
    let number: Int
    let section: String
    let question: String
    let answer: String
    let commentary: String
    let notes: [QuestionNote]
    let chapterId: String
    let partNumber: Int
    let partTitle: String
    let chapterNumber: Int
    let chapterTitle: String

    var id: Int { number }

    var hasAnswer: Bool { !answer.isEmpty }
    var hasCommentary: Bool { !commentary.isEmpty }
    var hasNotes: Bool { !notes.isEmpty }

    var previewText: String {
        if hasAnswer { return answer }
        if hasCommentary { return commentary }
        return question
    }
}

struct SectionGroup: Identifiable, Hashable {
    let title: String
    let questions: [Question]

    var id: String { title }
}

struct SearchResult: Identifiable, Hashable {
    let question: Question
    let matchedFields: [String]

    var id: Int { question.number }
}
