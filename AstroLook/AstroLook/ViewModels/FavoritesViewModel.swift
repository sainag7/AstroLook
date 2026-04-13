import Foundation
import SwiftData
import SwiftUI

@Observable
final class FavoritesViewModel {
    var showDeleteConfirmation = false
    var itemToDelete: FavoriteItem?

    func saveFavorite(
        from apod: APODItem,
        eli5Summary: String? = nil,
        context: ModelContext
    ) {
        // Check if already saved
        let date = apod.date
        let descriptor = FetchDescriptor<FavoriteItem>(
            predicate: #Predicate { $0.date == date }
        )

        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return // Already saved
        }

        let item = FavoriteItem(
            title: apod.title,
            date: apod.date,
            explanation: apod.explanation,
            imageURL: apod.url,
            hdImageURL: apod.hdurl,
            eli5Summary: eli5Summary
        )

        context.insert(item)
        try? context.save()
    }

    func isFavorited(date: String, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<FavoriteItem>(
            predicate: #Predicate { $0.date == date }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    func removeFavorite(date: String, context: ModelContext) {
        let descriptor = FetchDescriptor<FavoriteItem>(
            predicate: #Predicate { $0.date == date }
        )
        if let items = try? context.fetch(descriptor) {
            for item in items {
                context.delete(item)
            }
            try? context.save()
        }
    }

    func deleteFavorite(_ item: FavoriteItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
    }
}
