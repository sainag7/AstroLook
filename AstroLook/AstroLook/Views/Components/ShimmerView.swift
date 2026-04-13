import SwiftUI

struct ShimmerView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            Color.astroSurface
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: phase * geometry.size.width)
                )
                .clipped()
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                phase = 1.5
            }
        }
    }
}

// Shimmer placeholder for an image card
struct ShimmerCard: View {
    var height: CGFloat = 200

    var body: some View {
        ShimmerView()
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.astroBorder, lineWidth: 1)
            )
    }
}

// Shimmer placeholder for text lines
struct ShimmerTextBlock: View {
    var lines: Int = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<lines, id: \.self) { index in
                ShimmerView()
                    .frame(maxWidth: index == lines - 1 ? 160 : .infinity, minHeight: 14, maxHeight: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}
