// Design tokens. Role names are stable; /replica-brand changes values only.

import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Theme {
    /// The widest the menus and bars get, so iPad screens keep phone-like proportions.
    static let contentWidth: CGFloat = 620

    // Brand
    static let leaf = Color(hex: 0x3E9B4F)
    static let leafDeep = Color(hex: 0x1F5D3A)
    static let sunshine = Color(hex: 0xFFC94A)
    static let blossom = Color(hex: 0xFF8FB1)
    static let cream = Color(hex: 0xFFF8E7)
    static let ink = Color(hex: 0x24352B)

    // Tiles
    static let tileFaceTop = Color(hex: 0xFFFDF5)
    static let tileFaceBottom = Color(hex: 0xF1E9D2)
    static let tileEdge = Color(hex: 0xD9C9A3)
    static let tileSide = Color(hex: 0x6FA86A)          // jade back, like a real tile
    static let tileSelectedTop = Color(hex: 0xF4FFD9)
    static let tileSelectedBottom = Color(hex: 0xD3F2A6)
    static let selection = Color(hex: 0x58B947)
    static let hint = Color(hex: 0xFFB300)

    // Glyphs
    static let glyphRed = Color(hex: 0xC8423B)
    static let glyphGreen = Color(hex: 0x2F8F4E)
    static let glyphBlue = Color(hex: 0x2E64A8)
    static let glyphNavy = Color(hex: 0x23345C)

    // Surfaces over the scene
    static let card = Color(hex: 0xFFFBEF)
    static let scrim = Color.black.opacity(0.35)

    // Type: rounded, large, for older players too
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .black, design: .rounded) }
    static func title(_ size: CGFloat = 24) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func body(_ size: CGFloat = 18) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
}

// MARK: - Buttons

/// Big green pill used for the main action on every screen.
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.leaf

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.title(22))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.85), tint], startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 2))
                    .shadow(color: tint.opacity(0.5), radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 1 : 5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.title(19))
            .foregroundStyle(Theme.leafDeep)
            .padding(.vertical, 13)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(.white.opacity(0.85)))
            .overlay(Capsule().strokeBorder(Theme.leaf.opacity(0.35), lineWidth: 2))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Round glassy icon button for the top bars.
struct RoundIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.leafDeep)
                .frame(width: 48, height: 48)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1.5))
        }
        .accessibilityLabel(label)
    }
}

/// A rounded cream card for overlays and sheets. Stays phone-sized on iPad.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: 440)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(Theme.sunshine.opacity(0.6), lineWidth: 3)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}
