import SwiftUI
import SwiftData

struct DetailView: View {
    let apod: APODItem

    @State private var favoritesVM = FavoritesViewModel()
    @State private var eli5Text: String?
    @State private var isGeneratingELI5 = false
    @State private var imageScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Query private var favoriteItems: [FavoriteItem]

    private var isFav: Bool {
        favoriteItems.contains { $0.date == apod.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Full-screen image with pinch-to-zoom
                zoomableImage

                // Info
                VStack(alignment: .leading, spacing: 16) {
                    DateBadge(text: apod.formattedDate)

                    Text(apod.title)
                        .font(.astroTitle)
                        .foregroundStyle(.astroTextPrimary)

                    Text(apod.explanation)
                        .font(.astroBody)
                        .foregroundStyle(.astroTextSecondary)
                        .lineSpacing(5)

                    // ELI5 Section
                    eli5Section

                    Divider()
                        .background(Color.astroBorder)

                    // Action bar
                    actionBar
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 100)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.astroBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Zoomable Image / Video Hero

    @ViewBuilder
    private var zoomableImage: some View {
        if apod.isImage {
            AsyncImage(url: apod.hdImageURL ?? apod.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(imageScale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    imageScale = min(max(imageScale * delta, 1.0), 4.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if imageScale < 1.2 {
                                        withAnimation(.spring(duration: 0.3)) {
                                            imageScale = 1.0
                                        }
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(duration: 0.3)) {
                                imageScale = imageScale > 1.0 ? 1.0 : 2.5
                            }
                        }
                case .failure:
                    ZStack {
                        Color.astroSurface
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundStyle(.astroTextSecondary)
                    }
                    .frame(height: 300)
                case .empty:
                    ShimmerView()
                        .frame(height: 350)
                @unknown default:
                    ShimmerView()
                        .frame(height: 350)
                }
            }
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 0))
            .glowEffect(color: .astroAccent, radius: 16)
        } else {
            videoHero
        }
    }

    // MARK: - Video Hero

    private var videoHero: some View {
        ZStack {
            if let thumbURL = apod.thumbnailURL {
                AsyncImage(url: thumbURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                            .frame(maxWidth: .infinity).frame(height: 300).clipped()
                    default:
                        Color.astroSurface.frame(height: 300)
                    }
                }
            } else {
                Color.astroSurface.frame(height: 300)
            }

            Color.black.opacity(0.35)

            VStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .shadow(radius: 10)
                Text("Tap to watch on YouTube")
                    .font(.astroBody)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity).frame(height: 300)
        .onTapGesture {
            if let url = apod.videoWatchURL { openURL(url) }
        }
    }

    // MARK: - ELI5 Section

    @ViewBuilder
    private var eli5Section: some View {
        if let eli5 = eli5Text {
            ELI5Card(text: eli5)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            if #available(iOS 26.0, *) {
                ELI5Button(isLoading: isGeneratingELI5) {
                    Task { await generateELI5() }
                }
            }
        }
    }

    @available(iOS 26.0, *)
    private func generateELI5() async {
        guard !isGeneratingELI5 else { return }

        // Check cache
        if let cached = FoundationModelsService.shared.getCachedELI5(for: apod.id) {
            eli5Text = cached
            return
        }

        isGeneratingELI5 = true

        do {
            eli5Text = try await FoundationModelsService.shared.generateELI5(
                for: apod.explanation,
                id: apod.id
            )
        } catch {
            eli5Text = "Couldn't generate a simplified explanation right now."
        }

        isGeneratingELI5 = false
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                withAnimation(.spring(duration: 0.3)) {
                    if isFav {
                        favoritesVM.removeFavorite(date: apod.date, context: modelContext)
                    } else {
                        favoritesVM.saveFavorite(
                            from: apod,
                            eli5Summary: eli5Text,
                            context: modelContext
                        )
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isFav ? "heart.fill" : "heart")
                        .contentTransition(.symbolEffect(.replace))
                    Text(isFav ? "Saved" : "Save to Galaxy")
                }
                .font(.astroBody)
                .fontWeight(.semibold)
                .foregroundStyle(isFav ? .astroAccent : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isFav ? Color.astroAccent.opacity(0.2) : Color.astroAccent)
                .clipShape(Capsule())
                .glowEffect(
                    color: isFav ? .clear : .astroAccent,
                    radius: isFav ? 0 : 10
                )
            }

            // Share
            if let url = apod.isImage ? apod.imageURL : apod.videoWatchURL {
                ShareLink(
                    item: url,
                    subject: Text(apod.title),
                    message: Text("Check out \(apod.title) from NASA's APOD!")
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.astroBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.astroSurface)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.astroBorder, lineWidth: 1)
                        )
                }
            }
        }
    }
}
