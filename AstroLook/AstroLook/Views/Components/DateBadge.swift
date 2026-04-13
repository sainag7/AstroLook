import SwiftUI

struct DateBadge: View {
    let text: String
    var style: BadgeStyle = .accent

    enum BadgeStyle {
        case accent, subtle
    }

    var body: some View {
        Text(text)
            .font(.astroCaption)
            .fontWeight(.semibold)
            .tracking(0.5)
            .foregroundStyle(style == .accent ? .white : .astroTextSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                style == .accent
                    ? AnyShapeStyle(Color.astroAccent.opacity(0.3))
                    : AnyShapeStyle(Color.astroSurface.opacity(0.8))
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        style == .accent
                            ? Color.astroAccent.opacity(0.5)
                            : Color.astroBorder,
                        lineWidth: 1
                    )
            )
    }
}
