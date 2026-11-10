import SwiftUI
import UIKit

/// Compartilha uma pergunta no Instagram Stories via URL scheme + pasteboard.
/// Requer `FacebookAppID` numérico no Info.plist (obrigatório pela Meta desde jan/2023).
enum InstagramStoriesShareService {
    enum Outcome: Equatable {
        case openedInstagramStories
        case systemShareFallback
        case failed(String)
    }

    /// Facebook App ID (developers.facebook.com), lido de Info.plist (`FacebookAppID`).
    /// Precisa ser numérico; string vazia desativa o deep link e usa a share sheet do sistema.
    static var facebookAppID: String {
        guard let plist = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String else {
            return ""
        }
        let trimmed = plist.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.allSatisfy(\.isNumber) else { return "" }
        return trimmed
    }

    static var canOpenInstagramStories: Bool {
        guard let url = storiesURL else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    static var isConfigured: Bool {
        !facebookAppID.isEmpty
    }

    private static var storiesURL: URL? {
        guard isConfigured else { return nil }
        return URL(string: "instagram-stories://share?source_application=\(facebookAppID)")
    }

    @MainActor
    static func renderShareImage(for question: Question) -> UIImage? {
        let card = QuestionShareCardView(question: question)
        let renderer = ImageRenderer(content: card)
        renderer.proposedSize = ProposedViewSize(
            width: QuestionShareCardView.canvasWidth,
            height: QuestionShareCardView.canvasHeight
        )
        renderer.scale = 1
        return renderer.uiImage
    }

    /// Tenta abrir o editor de Stories; se Instagram/App ID não estiverem disponíveis, devolve fallback.
    @MainActor
    static func shareToStories(image: UIImage) -> Outcome {
        guard let imageData = image.pngData() else {
            return .failed("Não foi possível gerar a imagem.")
        }

        guard isConfigured else {
            return .systemShareFallback
        }

        guard let url = storiesURL, UIApplication.shared.canOpenURL(url) else {
            return .systemShareFallback
        }

        let pasteboardItems: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundImage": imageData,
            "com.instagram.sharedSticker.facebookAppID": facebookAppID
        ]]
        let options: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(60 * 5)
        ]
        UIPasteboard.general.setItems(pasteboardItems, options: options)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return .openedInstagramStories
    }

    @MainActor
    static func presentSystemShareSheet(image: UIImage) {
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        guard let presenter = topViewController() else { return }

        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        presenter.present(controller, animated: true)
    }

    @MainActor
    private static func topViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
