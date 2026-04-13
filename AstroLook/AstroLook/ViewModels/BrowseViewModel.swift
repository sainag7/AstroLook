import Foundation

@Observable
final class BrowseViewModel {
    var items: [APODItem] = []
    var isLoading = false
    var errorMessage: String?
    var startDate: Date = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
    var endDate: Date = .now

    func loadRange() async {
        isLoading = true
        errorMessage = nil

        do {
            // Clamp to max 30 days to avoid huge requests
            let maxStart = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? startDate
            let clampedStart = max(startDate, maxStart)

            items = try await NASAService.shared.fetchAPODRange(
                start: clampedStart,
                end: endDate
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
