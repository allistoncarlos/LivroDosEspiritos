import Foundation
import Sentry

enum CrashReportingService {
    private static let dsn = "https://a2a799dae1e645132fe3b444011c6535@o4512157514924032.ingest.us.sentry.io/4512157542514688"

    static func start() {
        SentrySDK.start { options in
            options.dsn = dsn
            options.tracesSampleRate = 1.0
        }
    }
}
