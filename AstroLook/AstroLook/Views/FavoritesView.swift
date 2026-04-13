import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(sort: \FavoriteItem.savedAt, order: .reverse) private var favorites: [FavoriteItem]
    @Environment(\.modelContext) private var modelContext
    @State private var favoritesVM = FavoritesViewModel()
    @State private var selectedFavorite: FavoriteItem?

    private let columns = [
        GridItem(.fixed(170), spacing: 12),
        GridItem(.fixed(170), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if favorites.isEmpty {
                    emptyState
                } else {
                    favoritesGrid
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.astroBackground)
            .navigationTitle("My Galaxy")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedFavorite) { fav in
                FavoriteDetailSheet(favorite: fav)
            }
            .confirmationDialog(
                "Remove from Galaxy?",
                isPresented: $favoritesVM.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let item = favoritesVM.itemToDelete {
                        withAnimation(.spring(duration: 0.3)) {
                            favoritesVM.deleteFavorite(item, context: modelContext)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Favorites Grid

    private var favoritesGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(favorites) { item in
                FavoriteCard(item: item, onRemove: {
                    withAnimation(.spring(duration: 0.3)) {
                        favoritesVM.deleteFavorite(item, context: modelContext)
                    }
                })
                .onTapGesture {
                    selectedFavorite = item
                }
                .contextMenu {
                    Button(role: .destructive) {
                        favoritesVM.itemToDelete = item
                        favoritesVM.showDeleteConfirmation = true
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 100)
    }

    // MARK: - Favorite Card

    struct FavoriteCard: View {
        let item: FavoriteItem
        var onRemove: (() -> Void)? = nil

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: item.imageURLValue) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 170, height: 160)
                                .clipped()
                        case .failure:
                            ZStack {
                                Color.astroSurface
                                Image(systemName: "photo.badge.exclamationmark")
                                    .foregroundStyle(.astroTextSecondary)
                            }
                            .frame(width: 170, height: 160)
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

                    if let onRemove {
                        Button(action: onRemove) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.astroAccent)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(8)
                        .glowEffect(color: .astroAccent, radius: 8)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.astroCaption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.astroTextPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    DateBadge(text: item.formattedDate, style: .subtle)
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
    }

    // MARK: - Favorite Detail Sheet

    struct FavoriteDetailSheet: View {
        let favorite: FavoriteItem
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Image
                        AsyncImage(url: favorite.imageURLValue) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .glowEffect(radius: 16)
                            default:
                                ShimmerCard(height: 300)
                            }
                        }

                        DateBadge(text: favorite.formattedDate)

                        Text(favorite.title)
                            .font(.astroTitle)
                            .foregroundStyle(.astroTextPrimary)

                        Text(favorite.explanation)
                            .font(.astroBody)
                            .foregroundStyle(.astroTextSecondary)
                            .lineSpacing(5)

                        if let eli5 = favorite.eli5Summary {
                            ELI5Card(text: eli5)
                        }

                        // Share button
                        if let url = favorite.imageURLValue {
                            ShareLink(
                                item: url,
                                subject: Text(favorite.title),
                                message: Text(favorite.title)
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

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .background(Color.astroBackground)
                .navigationTitle("Favorite")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundStyle(.astroAccent)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 56))
                .foregroundStyle(.astroAccent.opacity(0.4))
                .glowEffect(color: .astroAccent, radius: 20)

            Text("Your galaxy is empty")
                .font(.astroTitle2)
                .foregroundStyle(.astroTextPrimary)

            Text("Save images from the Today or Browse tabs\nto build your personal collection.")
                .font(.astroBody)
                .foregroundStyle(.astroTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }
}
