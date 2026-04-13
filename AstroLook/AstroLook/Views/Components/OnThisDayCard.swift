import SwiftUI

struct OnThisDayCard: View {
    let historical: HistoricalAPOD
    var isFavorited: Bool = false
    var onFavoriteTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                imageView

                if let onFavoriteTap {
                    Button(action: onFavoriteTap) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isFavorited ? Color.astroAccent : .white)
                            .padding(7)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(8)
                    .glowEffect(color: isFavorited ? .astroAccent : .clear, radius: 8)
                }
            }
            .frame(width: 160, height: 130)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(historical.yearLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.astroAccent)
                    .tracking(0.8)
                    .lineLimit(1)

                Text(historical.apod.title)
                    .font(.astroCaption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.astroTextPrimary)
                    .lineLimit(2)
                    .frame(width: 136, alignment: .leading)
            }
            .padding(12)
            .frame(width: 160, height: 90, alignment: .topLeading)
        }
        .frame(width: 160, height: 220)
        .background(Color.astroSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.astroBorder, lineWidth: 1)
        )
    }

    private var imageView: some View {
        AsyncImage(url: historical.apod.imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 130)
                    .clipped()
            case .failure:
                ZStack {
                    Color.astroSurface
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.title3)
                        .foregroundStyle(.astroTextSecondary)
                }
                .frame(width: 160, height: 130)
            default:
                ShimmerView()
                    .frame(width: 160, height: 130)
            }
        }
        .frame(width: 160, height: 130)
        .clipped()
    }
}
