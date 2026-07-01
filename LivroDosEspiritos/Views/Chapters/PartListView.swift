import SwiftUI

struct PartListView: View {
    let book: BookData

    var body: some View {
        List(book.parts) { part in
            NavigationLink(value: part) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(part.title)
                        .font(.headline)
                    Text("\(part.chapters.count) capítulos")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: BookPart.self) { part in
            ChapterListView(part: part)
        }
    }
}
