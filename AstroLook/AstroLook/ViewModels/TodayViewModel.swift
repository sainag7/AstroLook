import Foundation
import SwiftUI

@Observable
final class TodayViewModel {
    var apod: APODItem?
    var isLoading = false
    var errorMessage: String?
    var eli5Text: String?
    var isGeneratingELI5 = false
    var showExplanation = false

    func loadToday() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Try the dateless endpoint (returns "today" per NASA's server clock)
            // 2. If that 500s, retry with today's date explicitly — the API sometimes
            //    rejects the dateless form while accepting an explicit date string
            // 3. Only fall back to yesterday if both attempts fail
            do {
                apod = try await NASAService.shared.fetchAPOD()
            } catch NASAError.httpError(let code) where code == 500 {
                do {
                    apod = try await NASAService.shared.fetchAPOD(for: Date())
                } catch NASAError.httpError(let code2) where code2 == 500 {
                    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
                    apod = try await NASAService.shared.fetchAPOD(for: yesterday)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @available(iOS 26.0, *)
    func generateELI5() async {
        guard let apod, !isGeneratingELI5 else { return }

        // Check cache first
        if let cached = FoundationModelsService.shared.getCachedELI5(for: apod.id) {
            eli5Text = cached
            return
        }

        isGeneratingELI5 = true

        do {
            eli5Text = try await FoundationModelsService.shared.generateELI5(
                for: apod.explanation,
                id: apod.id
            )
        } catch {
            eli5Text = "Couldn't generate a simplified explanation right now. Try again later!"
        }

        isGeneratingELI5 = false
    }
}
