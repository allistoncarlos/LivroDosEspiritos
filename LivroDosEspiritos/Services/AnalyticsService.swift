import AmplitudeSwift
import Foundation

enum AnalyticsService {
    private static let apiKey = "c49a67003fb51822e10b12e8fb9efa81"

    static let amplitude = Amplitude(
        configuration: Configuration(
            apiKey: apiKey,
            serverZone: .US,
            autocapture: .all
        )
    )
}
