import AmplitudeSwift
import Foundation

enum AnalyticsEvent {
    static let parteVisualizada = "Parte Visualizada"
    static let capituloVisualizado = "Capítulo Visualizado"
    static let perguntaVisualizada = "Pergunta Visualizada"
    static let buscaRealizada = "Busca Realizada"
    static let notificacaoDiariaConfigurada = "Notificação Diária Configurada"
    static let notificacaoDiariaAberta = "Notificação Diária Aberta"
    static let linkDeContatoClicado = "Link de Contato Clicado"
    static let perguntaCompartilhadaInstagram = "Pergunta Compartilhada Instagram"
    static let clique = "Clique"
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
