import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var selectedItem: NASAImageItem?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    loadingGrid
                } else if let error = viewModel.errorMessage {
                    errorState(error)
                } else if viewModel.hasSearched && viewModel.results.isEmpty {
                    noResultsState
                } else if !viewModel.hasSearched {
                    emptyState
                } else {
                    resultsGrid
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.astroBackground)
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search the universe..."
            )
            .onSubmit(of: .search) {
                Task { await viewModel.search() }
            }
            .sheet(item: $selectedItem) { item in
                NASAImageDetailSheet(item: item)
            }
        }
    }

    // MARK: - Results Grid

    private var resultsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(viewModel.results.enumerated()), id: \.element.id) { index, item in
                NASAImageCard(item: item)
                    .onTapGesture {
                        selectedItem = item
                    }
                    .opacity(1)
                    .animation(
                        .spring(duration: 0.4).delay(Double(index % 8) * 0.04),
                        value: viewModel.results.count
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 100)
    }

    // MARK: - NASA Image Card (for library results)

    struct NASAImageCard: View {
        let item: NASAImageItem

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                AsyncImage(url: item.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minHeight: 120, maxHeight: 160)
                            .clipped()
                    case .failure:
                        ZStack {
                            Color.astroSurface
                            Image(systemName: "photo.badge.exclamationmark")
                                .foregroundStyle(.astroTextSecondary)
                        }
                        .frame(height: 140)
                    case .empty:
                        ShimmerView()
                            .frame(height: 140)
                    @unknown default:
                        ShimmerView()
                            .frame(height: 140)
                    }
                }
                .frame(maxWidth: .infinity)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 16
                    )
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.astroCaption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.astroTextPrimary)
                        .lineLimit(2)

                    if !item.formattedDate.isEmpty {
                        DateBadge(text: item.formattedDate, style: .subtle)
                    }
                }
                .padding(12)
            }
            .astroCard()
        }
    }

    // MARK: - NASA Image Detail Sheet

    struct NASAImageDetailSheet: View {
        let item: NASAImageItem
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Image
                        AsyncImage(url: item.thumbnailURL) { phase in
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

                        // Title
                        Text(item.title)
                            .font(.astroTitle)
                            .foregroundStyle(.astroTextPrimary)

                        if !item.formattedDate.isEmpty {
                            DateBadge(text: item.formattedDate)
                        }

                        // Description
                        if !item.description.isEmpty {
                            Text(item.description)
                                .font(.astroBody)
                                .foregroundStyle(.astroTextSecondary)
                                .lineSpacing(5)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .background(Color.astroBackground)
                .navigationTitle("Details")
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

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "scope")
                .font(.system(size: 56))
                .foregroundStyle(.astroTextSecondary)
                .symbolEffect(.pulse, options: .repeating)

            Text("Search the universe...")
                .font(.astroTitle2)
                .foregroundStyle(.astroTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }

    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.astroTextSecondary)
            Text("No results found")
                .font(.astroTitle2)
                .foregroundStyle(.astroTextPrimary)
            Text("Try a different search term.")
                .font(.astroBody)
                .foregroundStyle(.astroTextSecondary)
        }
        .padding(.top, 80)
    }

    private var loadingGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                ShimmerCard(height: 220)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(.astroAccent)
            Text("Search failed")
                .font(.astroTitle2)
                .foregroundStyle(.astroTextPrimary)
            Text(message)
                .font(.astroBody)
                .foregroundStyle(.astroTextSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.search() }
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
}
