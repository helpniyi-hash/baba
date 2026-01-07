import SwiftUI
import Core
import Common

enum BabciaGradientStyle {
    case vibrant
    case primary
    case subtle
}

enum BabciaBackgroundStyle {
    case character(BabciaCharacter)
    case gradient(BabciaCharacter, BabciaGradientStyle)
    case dreamVision(URL?, fallback: BabciaCharacter)
}

struct BabciaBackground: View {
    let style: BabciaBackgroundStyle
    var addsScrim: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()

            if addsScrim {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        switch style {
        case .character(let character):
            CharacterBackground(character: character)
                .overlay(gradientOverlay(for: character, style: .primary))
        case .gradient(let character, let style):
            gradientOverlay(for: character, style: style)
        case .dreamVision(let url, let fallback):
            ZStack {
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            CharacterBackground(character: fallback)
                        }
                    }
                } else {
                    CharacterBackground(character: fallback)
                }
            }
            .overlay(LinearGradient(
                colors: [.clear, Color.black.opacity(colorScheme == .dark ? 0.4 : 0.25)],
                startPoint: .center,
                endPoint: .bottom
            ))
        }
    }

    private func gradientOverlay(for character: BabciaCharacter, style: BabciaGradientStyle) -> LinearGradient {
        let accent = Color(hex: character.accentHex)
        let multiplier: Double = colorScheme == .dark ? 0.6 : 1.0

        let topOpacity: Double
        let midOpacity: Double
        let bottomColor: Color

        switch style {
        case .vibrant:
            topOpacity = 0.5 * multiplier
            midOpacity = 0.2 * multiplier
            bottomColor = colorScheme == .dark ? Color.black : Color(.systemBackground)
        case .primary:
            topOpacity = 0.3 * multiplier
            midOpacity = 0.15 * multiplier
            bottomColor = colorScheme == .dark ? Color.black : Color(.systemBackground)
        case .subtle:
            topOpacity = 0.15 * multiplier
            midOpacity = 0.08 * multiplier
            bottomColor = colorScheme == .dark ? Color.black : Color(.systemBackground)
        }

        return LinearGradient(
            colors: [
                accent.opacity(topOpacity),
                accent.opacity(midOpacity),
                bottomColor
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
