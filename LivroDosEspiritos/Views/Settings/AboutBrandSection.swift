import SwiftUI

/// Chevron "A" da marca Alliston Aleixo (mesmo path do logo-icon.svg, viewBox 72x72).
struct BrandChevron: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 72
        var path = Path()
        path.move(to: CGPoint(x: 36 * s, y: 8 * s))
        path.addLine(to: CGPoint(x: 62 * s, y: 58 * s))
        path.addLine(to: CGPoint(x: 50 * s, y: 58 * s))
        path.addLine(to: CGPoint(x: 36 * s, y: 32 * s))
        path.addLine(to: CGPoint(x: 22 * s, y: 58 * s))
        path.addLine(to: CGPoint(x: 10 * s, y: 58 * s))
        path.closeSubpath()
        return path
    }
}

/// Identidade visual "Alliston Aleixo" (Violet Core).
private enum Brand {
    static let violetCore = Color(red: 0x7C / 255, green: 0x3A / 255, blue: 0xED / 255)
    static let violetSoft = Color(red: 0xA7 / 255, green: 0x8B / 255, blue: 0xFA / 255)
    static let indigo = Color(red: 0x63 / 255, green: 0x66 / 255, blue: 0xF1 / 255)
    static let void = Color(red: 0x0A / 255, green: 0x0A / 255, blue: 0x0F / 255)
    static let surface = Color(red: 0x14 / 255, green: 0x14 / 255, blue: 0x1F / 255)
    static let textPrimary = Color(red: 0xF4 / 255, green: 0xF4 / 255, blue: 0xF5 / 255)
    static let textMuted = Color(red: 0xA1 / 255, green: 0xA1 / 255, blue: 0xAA / 255)

    static let gradient = LinearGradient(
        colors: [violetCore, indigo],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
}

/// Seção "Sobre" da tela de Ajustes: apresenta o app e a marca de quem o criou.
struct AboutBrandSection: View {
    private struct Pillar: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let text: String
    }

    private let pillars = [
        Pillar(icon: "checkmark.seal.fill", title: "Qualidade",
               text: "Cada detalhe é cuidado à mão: do código ao último pixel, sem atalhos."),
        Pillar(icon: "heart.fill", title: "Propósito",
               text: "Apps que nascem de um problema real e existem para ajudar de verdade."),
        Pillar(icon: "scope", title: "Resultado",
               text: "Simples de usar e focados no que importa: você sai com algo resolvido."),
    ]

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        Section {
            hero
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        } header: {
            Text("Sobre")
        }

        Section("Livro dos Espíritos") {
            Text("As 1019 perguntas de Allan Kardec para ler, buscar e refletir, com uma pergunta por dia no horário que você escolher.")
                .font(.subheadline)
            LabeledContent("Versão", value: version)
        }

        Section("Como os apps são construídos") {
            ForEach(pillars) { pillar in
                HStack(spacing: 16) {
                    Image(systemName: pillar.icon)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Brand.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pillar.title).font(.subheadline.weight(.semibold))
                        Text(pillar.text).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }

        Section {
            Link(destination: URL(string: "mailto:alliston@outlook.com")!) {
                Label("alliston@outlook.com", systemImage: "envelope.fill")
            }
            Link(destination: URL(string: "https://instagram.com/alliston.tech")!) {
                Label("@alliston.tech", systemImage: "at")
            }
        } header: {
            Text("Vamos conversar?")
        } footer: {
            Text("Precisa de um app sob medida? Entre em contato para contratar.")
        }

        Section {
        } footer: {
            Text("Feito com cuidado por Alliston Aleixo, desenvolvedor independente de aplicativos.")
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }

    private var hero: some View {
        VStack(spacing: 8) {
            BrandChevron()
                .fill(Brand.gradient)
                .frame(width: 72, height: 72)
            Text("Alliston Aleixo")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Brand.textPrimary)
                .padding(.top, 8)
            Text("BY ALLISTON")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Brand.textMuted)
            Text("Apps com qualidade, propósito e resultado.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Brand.violetSoft)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background {
            ZStack(alignment: .top) {
                LinearGradient(colors: [Brand.surface, Brand.void], startPoint: .top, endPoint: .bottom)
                RadialGradient(
                    colors: [Brand.violetCore.opacity(0.35), .clear],
                    center: .top, startRadius: 0, endRadius: 160
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
