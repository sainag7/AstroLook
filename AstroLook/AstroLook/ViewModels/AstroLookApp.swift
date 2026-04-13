import SwiftUI
import SwiftData

@main
struct AstroLookApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: FavoriteItem.self)
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "photo.stack.fill")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            FavoritesView()
                .tabItem {
                    Label("Galaxy", systemImage: "heart.fill")
                }
        }
        .tint(.astroAccent)
        .preferredColorScheme(.dark)
    }
}
