import SwiftUI
import WatchKit

struct QuestionReaderView: View {
    @Environment(BookDataStore.self) private var store
    @State private var currentQuestionNumber = WatchLastQuestionStore.lastQuestionNumber
    @State private var showingBrowser = false

    private let minimumQuestion = 1
    private let maximumQuestion = 1019

    var body: some View {
        NavigationStack {
            Group {
                if let question = store.question(number: currentQuestionNumber) {
                    WatchQuestionDetailView(question: question)
                        .simultaneousGesture(longPressGesture)
                        .simultaneousGesture(horizontalSwipeGesture)
                } else if store.loadError != nil {
                    ContentUnavailableView(
                        "Erro",
                        systemImage: "exclamationmark.triangle",
                        description: Text(store.loadError ?? "")
                    )
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Pergunta \(currentQuestionNumber)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingBrowser = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
        .sheet(isPresented: $showingBrowser) {
            QuestionBrowserView(selectedQuestionNumber: $currentQuestionNumber)
                .environment(store)
        }
        .onAppear {
            currentQuestionNumber = WatchLastQuestionStore.lastQuestionNumber
        }
        .onChange(of: currentQuestionNumber) { _, newValue in
            WatchLastQuestionStore.lastQuestionNumber = newValue
        }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                WKInterfaceDevice.current().play(.click)
                showingBrowser = true
            }
    }

    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 32, coordinateSpace: .local)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = abs(value.translation.height)
                guard abs(horizontal) > vertical, abs(horizontal) > 32 else { return }

                if horizontal < 0 {
                    goToNext()
                } else {
                    goToPrevious()
                }
            }
    }

    private func goToPrevious() {
        guard currentQuestionNumber > minimumQuestion else { return }
        currentQuestionNumber -= 1
    }

    private func goToNext() {
        guard currentQuestionNumber < maximumQuestion else { return }
        currentQuestionNumber += 1
    }
}

struct WatchQuestionDetailView: View {
    let question: Question

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(question.partTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("Cap. \(question.chapterNumber) — \(question.chapterTitle)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if !question.section.isEmpty {
                    Text(question.section)
                        .font(.caption.weight(.semibold))
                }

                Label("Pergunta", systemImage: "questionmark.circle")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(question.question)
                    .font(.body.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                if question.hasAnswer {
                    Label("Resposta dos Espíritos", systemImage: "quote.opening")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    Text(question.answer)
                        .font(.footnote)
                }

                if question.hasCommentary {
                    Label("Comentário de Allan Kardec", systemImage: "text.book.closed")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    Text(question.commentary)
                        .font(.footnote)
                }

                if question.hasNotes {
                    Label("Notas e adendos", systemImage: "note.text")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    ForEach(question.notes) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(note.number). \(note.label)")
                                .font(.caption2.weight(.semibold))
                            Text(note.text)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
    }
}
