import Foundation

@Observable
final class SearchViewModel {
    var results: [NASAImageItem] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?
    var hasSearched = false

    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        hasSearched = true

        do {
            results = try await NASAService.shared.searchImages(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
