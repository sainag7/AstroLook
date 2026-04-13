import SwiftUI
import SwiftData

struct TodayView: View {
    @State private var viewModel = TodayViewModel()
    @State private var favoritesVM = FavoritesViewModel()
    @State private var onThisDayVM = OnThisDayViewModel()
    @State private var selectedHistoricalAPOD: APODItem?
    @State private var randomAPOD: APODItem?
    @State private var isLoadingRandom = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Namespace private var heroNamespace
    @Query private var favoriteItems: [FavoriteItem]

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    loadingState
                } else if let error = viewModel.errorMessage {
                    errorState(error)
                } else if let apod = viewModel.apod {
                    apodContent(apod)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.astroBackground)
            .navigationTitle("Cosmic Daily")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedHistoricalAPOD) { apod in
                DetailView(apod: apod)
            }
            .navigationDestination(item: $randomAPOD) { apod in
                DetailView(apod: apod)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await loadRandomAPOD() }
                    } label: {
                        if isLoadingRandom {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "shuffle")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(isLoadingRandom)
                }
            }
            .refreshable {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await viewModel.loadToday() }
                    group.addTask { await onThisDayVM.load() }
                }
            }
        }
        .task {
            await withTaskGroup(of: Void.self) { group in
                if viewModel.apod == nil {
                    group.addTask { await viewModel.loadToday() }
                }
                if onThisDayVM.items.isEmpty {
                    group.addTask { await onThisDayVM.load() }
                }
            }
        }
    }

    // MARK: - APOD Content

    @ViewBuilder
    private func apodContent(_ apod: APODItem) -> some View {
        VStack(spacing: 0) {
            // Hero Image
            if apod.isImage {
                heroImage(apod)
            } else {
                videoPlaceholder(apod)
            }

            // Content below the hero
            VStack(alignment: .leading, spacing: 20) {
                // Date badge
                DateBadge(text: apod.formattedDate)

                // Title
                Text(apod.title)
                    .font(.astroTitle)
                    .foregroundStyle(.astroTextPrimary)

                // Explanation
                Text(apod.explanation)
                    .font(.astroBody)
                    .foregroundStyle(.astroTextSecondary)
                    .lineSpacing(5)

                // ELI5 Section
                eli5Section(apod)

                // Action buttons
                actionButtons(apod)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // On This Day section — outside horizontal padding so scroll bleeds edge-to-edge
            onThisDaySection
                .padding(.top, 32)

            Spacer(minLength: 100)
        }
    }

    // MARK: - Hero Image

    private func heroImage(_ apod: APODItem) -> some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let height: CGFloat = 420

            AsyncImage(url: apod.hdImageURL ?? apod.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: geo.size.width,
                            height: height + (minY > 0 ? minY : 0)
                        )
                        .clipped()
                        .offset(y: minY > 0 ? -minY : 0)
                        .overlay(alignment: .bottom) {
                            // Gradient scrim
                            LinearGradient(
                                colors: [
                                    Color.astroBackground,
                                    Color.astroBackground.opacity(0.7),
                                    .clear
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 160)
                        }
                case .failure:
                    ZStack {
                        Color.astroSurface
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundStyle(.astroTextSecondary)
                    }
                case .empty:
                    ShimmerView()
                @unknown default:
                    ShimmerView()
                }
            }
            .glowEffect(color: .astroAccent, radius: 20)
        }
        .frame(height: 420)
    }

    // MARK: - Video Placeholder

    private func videoPlaceholder(_ apod: APODItem) -> some View {
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
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
                Text("Tap to watch")
                    .font(.astroBody)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .onTapGesture {
            if let url = apod.videoWatchURL {
                openURL(url)
            }
        }
    }

    // MARK: - ELI5 Section

    @ViewBuilder
    private func eli5Section(_ apod: APODItem) -> some View {
        Divider()
            .background(Color.astroBorder)

        if let eli5 = viewModel.eli5Text {
            ELI5Card(text: eli5)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            if #available(iOS 26.0, *) {
                ELI5Button(isLoading: viewModel.isGeneratingELI5) {
                    Task {
                        await viewModel.generateELI5()
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(_ apod: APODItem) -> some View {
        let isFav = favoriteItems.contains { $0.date == apod.date }
        return HStack(spacing: 12) {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                if isFav {
                    favoritesVM.removeFavorite(date: apod.date, context: modelContext)
                } else {
                    favoritesVM.saveFavorite(
                        from: apod,
                        eli5Summary: viewModel.eli5Text,
                        context: modelContext
                    )
                }
            } label: {
                Label(
                    isFav ? "Saved" : "Save",
                    systemImage: isFav ? "heart.fill" : "heart"
                )
                .font(.astroBody)
                .fontWeight(.semibold)
                .foregroundStyle(isFav ? .astroAccent : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isFav ? Color.astroAccent.opacity(0.2) : Color.astroSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isFav ? Color.astroAccent.opacity(0.5) : Color.astroBorder, lineWidth: 1)
                )
            }

            // Share button
            if let url = apod.imageURL {
                ShareLink(
                    item: url,
                    subject: Text(apod.title),
                    message: Text("Check out today's NASA Astronomy Picture of the Day: \(apod.title)")
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.astroBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.astroSurface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.astroBorder, lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - On This Day Section

    @ViewBuilder
    private var onThisDaySection: some View {
        if onThisDayVM.isLoading || !onThisDayVM.items.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("On This Day")
                    .font(.astroTitle2)
                    .foregroundStyle(.astroTextPrimary)
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if onThisDayVM.isLoading {
                            ForEach(0..<3, id: \.self) { _ in
                                ShimmerCard(height: 220)
                                    .frame(width: 160)
                            }
                        } else {
                            ForEach(onThisDayVM.items) { historical in
                                OnThisDayCard(
                                    historical: historical,
                                    isFavorited: favoriteItems.contains {
                                        $0.date == historical.apod.date
                                    },
                                    onFavoriteTap: {
                                        toggleHistoricalFavorite(historical.apod)
                                    }
                                )
                                .onTapGesture {
                                    selectedHistoricalAPOD = historical.apod
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Random APOD

    private func loadRandomAPOD() async {
        guard !isLoadingRandom else { return }
        isLoadingRandom = true
        defer { isLoadingRandom = false }

        // Archive spans June 16, 1995 → today
        let apodEpoch = Calendar.current.date(from: DateComponents(year: 1995, month: 6, day: 16))!
        let totalSeconds = Date().timeIntervalSince(apodEpoch)
        let randomDate = apodEpoch.addingTimeInterval(TimeInterval.random(in: 0..<totalSeconds))

        do {
            let apod = try await NASAService.shared.fetchAPOD(for: randomDate)
            randomAPOD = apod
        } catch NASAError.httpError(500) {
            // Some early-archive dates have gaps — retry with the next day
            let fallbackDate = Calendar.current.date(byAdding: .day, value: 1, to: randomDate)!
            if let apod = try? await NASAService.shared.fetchAPOD(for: fallbackDate) {
                randomAPOD = apod
            }
        } catch {
            // Silently fail — don't disrupt the current Today APOD
        }
    }

    private func toggleHistoricalFavorite(_ apod: APODItem) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if favoriteItems.contains(where: { $0.date == apod.date }) {
            favoritesVM.removeFavorite(date: apod.date, context: modelContext)
        } else {
            favoritesVM.saveFavorite(from: apod, context: modelContext)
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 16) {
            ShimmerCard(height: 420)
            ShimmerTextBlock(lines: 4)
                .padding(.horizontal, 20)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.astroAccent)

            Text("Something went wrong")
                .font(.astroTitle2)
                .foregroundStyle(.astroTextPrimary)

            Text(message)
                .font(.astroBody)
                .foregroundStyle(.astroTextSecondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task { await viewModel.loadToday() }
            }
            .font(.astroBody)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.astroAccent)
            .clipShape(Capsule())
        }
        .padding(40)
        .astroCard()
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
}
