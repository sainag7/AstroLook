import SwiftUI

// MARK: - Colors

extension Color {
    static let astroBackground = Color(hex: "0A0A0F")
    static let astroSurface = Color(hex: "12121A")
    static let astroAccent = Color(hex: "7B61FF")
    static let astroTextPrimary = Color.white
    static let astroTextSecondary = Color(hex: "8A8A9A")
    static let astroBorder = Color.white.opacity(0.08)
}

// Enables dot-syntax shorthand: .foregroundStyle(.astroAccent)
extension ShapeStyle where Self == Color {
    static var astroBackground: Color { .astroBackground }
    static var astroSurface: Color { .astroSurface }
    static var astroAccent: Color { .astroAccent }
    static var astroTextPrimary: Color { .astroTextPrimary }
    static var astroTextSecondary: Color { .astroTextSecondary }
    static var astroBorder: Color { .astroBorder }
}

extension Color {

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

// MARK: - Glow Modifier

struct GlowModifier: ViewModifier {
    var color: Color = .astroAccent
    var radius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: radius * 2, x: 0, y: 4)
    }
}

extension View {
    func glowEffect(color: Color = .astroAccent, radius: CGFloat = 12) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Card Style

struct AstroCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.astroSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.astroBorder, lineWidth: 1)
            )
    }
}

extension View {
    func astroCard() -> some View {
        modifier(AstroCardStyle())
    }
}

// MARK: - Typography

extension Font {
    static let astroLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let astroTitle = Font.system(size: 24, weight: .bold, design: .default)
    static let astroTitle2 = Font.system(size: 20, weight: .semibold, design: .default)
    static let astroHeadline = Font.system(size: 17, weight: .semibold, design: .default)
    static let astroBody = Font.system(size: 15, weight: .regular, design: .default)
    static let astroCaption = Font.system(size: 13, weight: .medium, design: .default)
    static let astroDisplayTitle = Font.system(size: 42, weight: .heavy, design: .default)
}
