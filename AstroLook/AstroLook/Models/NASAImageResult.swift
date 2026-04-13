import Foundation

// MARK: - NASA Image & Video Library API Response

struct NASAImageLibraryResponse: Codable {
    let collection: NASACollection
}

struct NASACollection: Codable {
    let items: [NASAImageItem]
}

struct NASAImageItem: Codable, Identifiable, Hashable {
    var id: String {
        data.first?.nasaID ?? UUID().uuidString
    }

    let data: [NASAImageData]
    let links: [NASAImageLink]?

    var title: String {
        data.first?.title ?? "Untitled"
    }

    var description: String {
        data.first?.description ?? ""
    }

    var dateCreated: String {
        data.first?.dateCreated ?? ""
    }

    var thumbnailURL: URL? {
        guard let href = links?.first?.href else { return nil }
        return URL(string: href)
    }

    var formattedDate: String {
        guard let raw = data.first?.dateCreated else { return "" }
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = inputFormatter.date(from: raw) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM d, yyyy"
            return outputFormatter.string(from: date).uppercased()
        }
        // Fallback: try without fractional seconds
        inputFormatter.formatOptions = [.withInternetDateTime]
        if let date = inputFormatter.date(from: raw) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM d, yyyy"
            return outputFormatter.string(from: date).uppercased()
        }
        return raw
    }

    static func == (lhs: NASAImageItem, rhs: NASAImageItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct NASAImageData: Codable, Hashable {
    let title: String?
    let description: String?
    let nasaID: String
    let dateCreated: String?
    let mediaType: String?

    enum CodingKeys: String, CodingKey {
        case title, description
        case nasaID = "nasa_id"
        case dateCreated = "date_created"
        case mediaType = "media_type"
    }
}

struct NASAImageLink: Codable, Hashable {
    let href: String
    let rel: String?
    let render: String?
}
