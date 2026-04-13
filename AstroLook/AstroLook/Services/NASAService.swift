import Foundation

@Observable
final class NASAService {
    static let shared = NASAService()
    private init() {}

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: - APOD: Single Day

    func fetchAPOD(for date: Date? = nil) async throws -> APODItem {
        var components = URLComponents(string: Constants.apodBaseURL)!
        var queryItems = [URLQueryItem(name: "api_key", value: Constants.nasaAPIKey)]

        if let date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            queryItems.append(URLQueryItem(name: "date", value: formatter.string(from: date)))
        }

        components.queryItems = queryItems

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try validateResponse(response)
        return try decoder.decode(APODItem.self, from: data)
    }

    // MARK: - APOD: Date Range

    func fetchAPODRange(start: Date, end: Date) async throws -> [APODItem] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var components = URLComponents(string: Constants.apodBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: Constants.nasaAPIKey),
            URLQueryItem(name: "start_date", value: formatter.string(from: start)),
            URLQueryItem(name: "end_date", value: formatter.string(from: end))
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try validateResponse(response)
        let items = try decoder.decode([APODItem].self, from: data)
        return items.reversed() // Most recent first
    }

    // MARK: - NASA Image Library Search

    func searchImages(query: String, page: Int = 1) async throws -> [NASAImageItem] {
        var components = URLComponents(string: Constants.nasaImageLibraryBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "media_type", value: "image"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try validateResponse(response)
        let libraryResponse = try decoder.decode(NASAImageLibraryResponse.self, from: data)
        return libraryResponse.collection.items
    }

    // MARK: - Validation

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NASAError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NASAError.httpError(httpResponse.statusCode)
        }
    }
}

// MARK: - Errors

enum NASAError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from NASA servers."
        case .httpError(let code):
            return "Server error (HTTP \(code)). Please try again."
        case .decodingError:
            return "Failed to process the data from NASA."
        }
    }
}
