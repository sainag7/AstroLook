import SwiftUI

struct AstroCard: View {
    let title: String
    let date: String
    let imageURL: URL?
    var isFavorited: Bool = false
    var onFavoriteTap: (() -> Void)? = nil
    var namespace: Namespace.ID?
    var itemID: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image — fixed 160pt tall, fills full width, crops overflow
            ZStack(alignment: .topTrailing) {
                if let namespace {
                    imageView
                        .matchedGeometryEffect(id: "image_\(itemID)", in: namespace)
                } else {
                    imageView
                }

                // Favorite heart
                if let onFavoriteTap {
                    Button(action: onFavoriteTap) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isFavorited ? Color.astroAccent : .white)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(8)
                    .glowEffect(
                        color: isFavorited ? .astroAccent : .clear,
                        radius: 8
                    )
                }
            }
            .frame(width: 170, height: 160)
            .clipped()

            // Info — fixed 80pt so total card is always 240pt tall
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.astroCaption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.astroTextPrimary)
                    .lineLimit(2)
                    .frame(width: 146, alignment: .leading)

                DateBadge(text: date, style: .subtle)
            }
            .padding(12)
            .frame(width: 170, height: 80, alignment: .topLeading)
        }
        .frame(width: 170, height: 240)
        .background(Color.astroSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.astroBorder, lineWidth: 1)
        )
    }

    private var imageView: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 170, height: 160)
                    .clipped()
            case .failure:
                failurePlaceholder
            case .empty:
                ShimmerView()
                    .frame(width: 170, height: 160)
            @unknown default:
                ShimmerView()
                    .frame(width: 170, height: 160)
            }
        }
        .frame(width: 170, height: 160)
        .clipped()
    }

    private var failurePlaceholder: some View {
        ZStack {
            Color.astroSurface
            Image(systemName: "photo.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(.astroTextSecondary)
        }
        .frame(width: 170, height: 160)
    }
}
