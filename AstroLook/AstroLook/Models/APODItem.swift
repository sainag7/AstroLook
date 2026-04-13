import Foundation

struct APODItem: Codable, Identifiable, Hashable {
    var id: String { date }
    let date: String
    let title: String
    let explanation: String
    let url: String
    let hdurl: String?
    let mediaType: String
    let copyright: String?

    enum CodingKeys: String, CodingKey {
        case date, title, explanation, url, hdurl, copyright
        case mediaType = "media_type"
    }

    var imageURL: URL? {
        URL(string: url)
    }

    var hdImageURL: URL? {
        if let hdurl { return URL(string: hdurl) }
        return imageURL
    }

    var isImage: Bool {
        mediaType == "image"
    }

    // Converts https://www.youtube.com/embed/VIDEO_ID?... → https://www.youtube.com/watch?v=VIDEO_ID
    var videoWatchURL: URL? {
        guard !isImage else { return nil }
        guard let embedURL = URL(string: url),
              let host = embedURL.host,
              host.contains("youtube") || host.contains("youtu.be") else {
            return URL(string: url)
        }
        let pathComponents = embedURL.pathComponents   // ["/", "embed", "VIDEO_ID"]
        if let idx = pathComponents.firstIndex(of: "embed"),
           idx + 1 < pathComponents.count {
            let videoID = pathComponents[idx + 1]
            return URL(string: "https://www.youtube.com/watch?v=\(videoID)")
        }
        return URL(string: url)
    }

    // YouTube CDN thumbnail for use as a preview image
    var thumbnailURL: URL? {
        guard !isImage else { return nil }
        guard let embedURL = URL(string: url),
              let host = embedURL.host,
              host.contains("youtube") || host.contains("youtu.be") else {
            return nil
        }
        let pathComponents = embedURL.pathComponents
        if let idx = pathComponents.firstIndex(of: "embed"),
           idx + 1 < pathComponents.count {
            let videoID = pathComponents[idx + 1]
            return URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg")
        }
        return nil
    }

    var formattedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inputFormatter.date(from: date) else { return self.date }
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy"
        return outputFormatter.string(from: date).uppercased()
    }

    var parsedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}
