import SwiftUI
import SwiftData

struct BrowseView: View {
    @State private var viewModel = BrowseViewModel()
    @State private var favoritesVM = FavoritesViewModel()
    @State private var selectedAPOD: APODItem?
    @Environment(\.modelContext) private var modelContext
    @Namespace private var gridNamespace
    @Query private var favoriteItems: [FavoriteItem]

    private let columns = [
        GridItem(.fixed(170), spacing: 12),
        GridItem(.fixed(170), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date range picker
                datePickerBar

                // Content
                ScrollView {
                    if viewModel.isLoading {
                        loadingGrid
                    } else if let error = viewModel.errorMessage {
                        errorState(error)
                    } else if viewModel.items.isEmpty {
                        emptyState
                    } else {
                        imageGrid
                    }
                }
                .scrollIndicators(.hidden)
            }
            .background(Color.astroBackground)
            .navigationTitle("The Archive")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedAPOD) { apod in
                DetailView(apod: apod)
            }
        }
        .task {
            if viewModel.items.isEmpty {
                await viewModel.loadRange()
            }
        }
    }

    // MARK: - Date Picker

    private var datePickerBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("FROM")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.astroTextSecondary)
                    .tracking(1)
                DatePicker(
                    "",
                    selection: $viewModel.startDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(.astroAccent)
                .colorScheme(.dark)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("TO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.astroTextSecondary)
                    .tracking(1)
                DatePicker(
                    "",
                    selection: $viewModel.endDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(.astroAccent)
                .colorScheme(.dark)
            }

            Spacer()

            Button {
                Task { await viewModel.loadRange() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.astroAccent)
                    .clipShape(Circle())
                    .glowEffect()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.astroSurface)
    }

    // MARK: - Image Grid

    private var imageGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                if item.isImage {
                    AstroCard(
                        title: item.title,
                        date: item.formattedDate,
                        imageURL: item.imageURL,
                        isFavorited: favoriteItems.contains { $0.date == item.date },
                        onFavoriteTap: {
                            toggleFavorite(item)
                        },
                        namespace: gridNamespace,
                        itemID: item.id
                    )
                    .onTapGesture {
                        selectedAPOD = item
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 100)
        .animation(.spring(duration: 0.4), value: viewModel.items.count)
    }

    // MARK: - Loading Grid

    private var loadingGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                ShimmerCard(height: 220)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(.astroTextSecondary)
            Text("No images found")
                .font(.astroTitle2)
                .foregroundStyle(.astroTextPrimary)
            Text("Try selecting a different date range.")
                .font(.astroBody)
                .foregroundStyle(.astroTextSecondary)
        }
        .padding(.top, 80)
    }

    // MARK: - Error State

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
                Task { await viewModel.loadRange() }
            }
            .font(.astroBody)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.astroAccent)
            .clipShape(Capsule())
        }
        .padding(32)
        .astroCard()
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    // MARK: - Helpers

    private func toggleFavorite(_ item: APODItem) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if favoritesVM.isFavorited(date: item.date, context: modelContext) {
            favoritesVM.removeFavorite(date: item.date, context: modelContext)
        } else {
            favoritesVM.saveFavorite(from: item, context: modelContext)
        }
    }
}
