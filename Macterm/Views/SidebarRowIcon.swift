import SwiftUI

/// The leading glyph of a sidebar row — the user's chosen SF Symbol, a live
/// AI-agent logo, or a 1-based position number. Shared with the window header
/// badge, which has to draw exactly what the project's row draws.
struct SidebarRowIcon: View {
    let symbol: String
    let index: Int
    var agent: AgentIcon?
    @AppStorage(Preferences.Keys.sidebarIconSize)
    private var iconSizeRaw = SidebarIconSize.medium.rawValue
    /// Scales with the user's text size like the sibling SF Symbols do; a
    /// fixed 15pt would stay small next to enlarged row text.
    @ScaledMetric(relativeTo: .body)
    private var agentIconSize: CGFloat = 15

    private var size: SidebarIconSize {
        SidebarIconSize(rawValue: iconSizeRaw) ?? .medium
    }

    var body: some View {
        if let agent {
            // A live AI agent in the tab overrides the user's chosen icon —
            // the logo is a status signal, tinted with the agent's brand color
            // (overriding the row's .secondary tint).
            let side = agentIconSize * size.glyphScale
            Image(agent.rawValue)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)
                .foregroundStyle(agent.brandColor)
        } else if Preferences.numberIconChoices.contains(symbol) {
            NumberGlyph(index: index, variant: symbol, size: size)
        } else {
            Image(systemName: symbol)
                .imageScale(size.imageScale)
        }
    }
}

private extension SidebarIconSize {
    /// SwiftUI's own symbol scaling, which sizes a symbol against whatever font
    /// the row hands it. `medium` is the default, so the middle case leaves an
    /// icon exactly the size it was before this preference existed rather than
    /// pinning it to a point size of our own.
    var imageScale: Image.Scale {
        switch self {
        case .small: .small
        case .medium: .medium
        case .large: .large
        }
    }
}

struct NumberGlyph: View {
    let index: Int
    let variant: String
    var size: SidebarIconSize = .medium
    /// The `.body` point size, as a metric so the digits keep tracking the
    /// user's text size once `glyphScale` has been applied — `imageScale` is
    /// no help here, since these variants draw text rather than a symbol.
    @ScaledMetric(relativeTo: .body)
    private var bodyFontSize: CGFloat = 13

    private var digitFont: Font {
        .system(size: bodyFontSize * size.glyphScale).monospacedDigit()
    }

    var body: some View {
        if variant == Preferences.numberIconPlain {
            Text("\(index)")
                .font(digitFont)
        } else if let suffix = shapeSuffix, (1 ... 50).contains(index) {
            // SF Symbols ships `1.<shape>` through `50.<shape>`; beyond that,
            // fall back to plain digits so we don't render a missing glyph.
            Image(systemName: "\(index).\(suffix)")
                .imageScale(size.imageScale)
        } else {
            Text("\(index)")
                .font(digitFont)
        }
    }

    /// Maps the sentinel token (e.g. `number.circle.fill`) to the suffix used
    /// by the indexed SF Symbol (e.g. `circle.fill` in `1.circle.fill`).
    private var shapeSuffix: String? {
        switch variant {
        case Preferences.numberIconCircleFill: "circle.fill"
        case Preferences.numberIconCircle: "circle"
        case Preferences.numberIconSquareFill: "square.fill"
        case Preferences.numberIconSquare: "square"
        default: nil
        }
    }
}

private extension AgentIcon {
    /// The agent's brand tint. These are vendor identity colors, not theme
    /// colors, so they're the one deliberate exception to "all colors come
    /// from MactermTheme". Monochrome brands (Cursor, Grok, opencode) use
    /// `.primary` so they stay black-on-light / white-on-dark like the brand.
    var brandColor: Color {
        switch self {
        case .claude: Color(red: 0xD9 / 255, green: 0x77 / 255, blue: 0x57 / 255) // Anthropic coral
        case .codex: Color(red: 0xAB / 255, green: 0xAB / 255, blue: 0xAB / 255) // OpenAI light gray
        case .gemini: Color(red: 0x42 / 255, green: 0x85 / 255, blue: 0xF4 / 255) // Google blue
        case .copilot: Color(red: 0x89 / 255, green: 0x57 / 255, blue: 0xE5 / 255) // GitHub purple
        case .antigravity: Color(red: 0x31 / 255, green: 0x86 / 255, blue: 0xFF / 255) // Google Antigravity blue
        case .opencode,
             .cursor,
             .grok,
             .pi: .primary
        }
    }
}
