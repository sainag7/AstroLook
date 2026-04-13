import Foundation
import FoundationModels

@available(iOS 26.0, *)
@Observable
final class FoundationModelsService {
    static let shared = FoundationModelsService()
    private init() {}

    private var cache: [String: String] = [:]

    func generateELI5(for explanation: String, id: String) async throws -> String {
        // Return cached result if available
        if let cached = cache[id] {
            return cached
        }

        let session = LanguageModelSession()

        let prompt = """
        Explain the following astronomy concept like I'm 5 years old. \
        Use simple words, fun comparisons, and keep it to 2-3 short sentences. \
        Make it feel magical and exciting.

        \(explanation)
        """

        let response = try await session.respond(to: prompt)
        let result = response.content
        cache[id] = result
        return result
    }

    func getCachedELI5(for id: String) -> String? {
        cache[id]
    }
}
