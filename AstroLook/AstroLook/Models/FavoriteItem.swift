import Foundation
import SwiftData

@Model
final class FavoriteItem {
    var title: String
    var date: String
    var explanation: String
    var imageURL: String
    var hdImageURL: String?
    var eli5Summary: String?
    var savedAt: Date

    init(
        title: String,
        date: String,
        explanation: String,
        imageURL: String,
        hdImageURL: String? = nil,
        eli5Summary: String? = nil
    ) {
        self.title = title
        self.date = date
        self.explanation = explanation
        self.imageURL = imageURL
        self.hdImageURL = hdImageURL
        self.eli5Summary = eli5Summary
        self.savedAt = .now
    }

    var formattedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        guard let parsed = inputFormatter.date(from: date) else { return date }
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy"
        return outputFormatter.string(from: parsed).uppercased()
    }

    var imageURLValue: URL? {
        URL(string: imageURL)
    }
}
