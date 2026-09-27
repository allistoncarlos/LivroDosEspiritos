import AmplitudeSwift
import Foundation

enum AnalyticsEvent {
    static let perguntaVisualizada = "Pergunta Visualizada"
}

enum AnalyticsService {
    private static let apiKey = "c49a67003fb51822e10b12e8fb9efa81"

    static let amplitude = Amplitude(
        configuration: Configuration(
            apiKey: apiKey,
            serverZone: .US,
            autocapture: .all
        )
    )

    static func track(_ eventName: String, properties: [String: Any]? = nil) {
        amplitude.track(eventType: eventName, eventProperties: properties)
    }
}
