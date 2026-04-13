import Foundation

struct HistoricalAPOD: Identifiable {
    var id: String { apod.id }
    let apod: APODItem
    let yearsAgo: Int
    var yearLabel: String { yearsAgo == 1 ? "1 Year Ago" : "\(yearsAgo) Years Ago" }
}

@Observable
final class OnThisDayViewModel {
    private static let apodEpoch: Date = {
        var c = DateComponents()
        c.year = 1995; c.month = 6; c.day = 16
        return Calendar.current.date(from: c)!
    }()

    var items: [HistoricalAPOD] = []
    var isLoading = false

    func load() async {
        isLoading = true
        items = []

        let calendar = Calendar.current
        let today = Date()

        let datePairs: [(yearsAgo: Int, date: Date)] = [1, 5, 10].compactMap { years in
            guard let d = calendar.date(byAdding: .year, value: -years, to: today),
                  d >= Self.apodEpoch else { return nil }
            return (years, d)
        }

        var results: [HistoricalAPOD] = []
        await withTaskGroup(of: HistoricalAPOD?.self) { group in
            for pair in datePairs {
                group.addTask {
                    guard let apod = try? await NASAService.shared.fetchAPOD(for: pair.date) else { return nil }
                    let isImage = await MainActor.run { apod.isImage }
                    guard isImage else { return nil }
                    return HistoricalAPOD(apod: apod, yearsAgo: pair.yearsAgo)
                }
            }
            for await result in group {
                if let h = result { results.append(h) }
            }
        }

        items = results.sorted { $0.yearsAgo < $1.yearsAgo }
        isLoading = false
    }
}
