import SwiftUI

struct ChapterListView: View {
    let part: BookPart

    var body: some View {
        List(part.chapters) { chapter in
            NavigationLink(value: chapter) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chapter.displayTitle)
                        .font(.headline)
                    if let range = chapter.questionRange {
                        Text("Perguntas \(range.start)–\(range.end)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if !chapter.sections.isEmpty {
                        Text(chapter.sections.joined(separator: " • "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(part.title)
    }
}
