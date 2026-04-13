import SwiftUI

struct ELI5Card: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Explain Like I'm 5", systemImage: "sparkles")
                .font(.astroCaption)
                .fontWeight(.bold)
                .foregroundStyle(.astroAccent)

            Text(text)
                .font(.astroBody)
                .foregroundStyle(.astroTextPrimary)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.astroSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.astroAccent.opacity(0.3), lineWidth: 1.5)
        )
        .glowEffect(color: .astroAccent, radius: 6)
    }
}

struct ELI5Button: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(isLoading ? "Thinking..." : "Explain Like I'm 5")
                    .fontWeight(.semibold)
            }
            .font(.astroBody)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.astroAccent)
            .clipShape(Capsule())
            .glowEffect()
        }
        .disabled(isLoading)
    }
}
