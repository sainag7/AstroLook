import WidgetKit
import SwiftUI
import UIKit

// MARK: - Widget Entry

struct AstroEntry: TimelineEntry {
    let date: Date
    let title: String
    let explanation: String
    let imageData: Data?
    let apodDate: String
}

// MARK: - Timeline Provider

struct AstroTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AstroEntry {
        AstroEntry(
            date: .now,
            title: "Astronomy Picture of the Day",
            explanation: "Loading today's cosmic wonder...",
            imageData: nil,
            apodDate: "APR 8, 2026"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AstroEntry) -> Void) {
        completion(AstroEntry(
            date: .now,
            title: "The Milky Way Over Monument Valley",
            explanation: "An incredible view of our galaxy stretching across the desert sky.",
            imageData: nil,
            apodDate: "APR 8, 2026"
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AstroEntry>) -> Void) {
        Task {
            do {
                let apod: APODItem
                do {
                    apod = try await fetchAPOD(for: nil)
                } catch NASAWidgetError.http(500) {
                    do {
                        apod = try await fetchAPOD(for: Date())
                    } catch NASAWidgetError.http(500) {
                        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
                        apod = try await fetchAPOD(for: yesterday)
                    }
                }

                let imageData = apod.isImage ? await downloadImage(from: apod.url) : nil
                let entry = AstroEntry(
                    date: .now,
                    title: apod.title,
                    explanation: apod.explanation,
                    imageData: imageData,
                    apodDate: apod.formattedDate
                )
                let tomorrow = Calendar.current.startOfDay(
                    for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
                )
                completion(Timeline(entries: [entry], policy: .after(tomorrow)))
            } catch {
                let entry = AstroEntry(
                    date: .now,
                    title: "Unable to load",
                    explanation: "Check your connection and try again.",
                    imageData: nil,
                    apodDate: ""
                )
                let retryDate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
                completion(Timeline(entries: [entry], policy: .after(retryDate)))
            }
        }
    }

    // MARK: - Networking

    private func downloadImage(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        return try? await URLSession.shared.data(from: url).0
    }

    private func fetchAPOD(for date: Date?) async throws -> APODItem {
        let apiKey = "tlt1STiFBFttpWK158gEzuYwbZOZ5w79lTCdA08d"
        var urlString = "https://api.nasa.gov/planetary/apod?api_key=\(apiKey)"
        if let date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            urlString += "&date=\(formatter.string(from: date))"
        }
        let url = URL(string: urlString)!
        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        guard statusCode == 200 else {
            throw NASAWidgetError.http(statusCode)
        }

        return try JSONDecoder().decode(APODItem.self, from: data)
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: AstroEntry

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Full-bleed background — pinned to exact widget dimensions
            if let data = entry.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 169, height: 169)
                    .clipped()
            } else {
                placeholderBackground
            }

            // Dark gradient so text is always readable
            LinearGradient(
                colors: [Color(hex: "0A0A0F").opacity(0.85), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(width: 169, height: 169)

            if !entry.apodDate.isEmpty {
                Text(entry.apodDate)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "7B61FF").opacity(0.6))
                    .clipShape(Capsule())
                    .padding(12)
            }
        }
        .frame(width: 169, height: 169)
        .clipped()
        .containerBackground(for: .widget) {
            Color(hex: "0A0A0F")
        }
    }

    private var placeholderBackground: some View {
        ZStack {
            Color(hex: "0A0A0F")
            Image(systemName: "sparkle")
                .font(.largeTitle)
                .foregroundStyle(Color(hex: "7B61FF").opacity(0.3))
        }
        .frame(width: 169, height: 169)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: AstroEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left: square image crop, pinned to exact dimensions
            if let data = entry.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 169, height: 169)
                    .clipped()
            } else {
                placeholderImage
            }

            // Right: text content filling remaining width
            VStack(alignment: .leading, spacing: 6) {
                if !entry.apodDate.isEmpty {
                    Text(entry.apodDate)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(hex: "7B61FF").opacity(0.5))
                        .clipShape(Capsule())
                }

                Text(entry.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(entry.explanation)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "8A8A9A"))
                    .lineLimit(3)

                Spacer()
            }
            .padding(12)
            .frame(width: 195, alignment: .leading)
        }
        .frame(width: 364, height: 169)
        .clipped()
        .containerBackground(for: .widget) {
            Color(hex: "0A0A0F")
        }
    }

    private var placeholderImage: some View {
        ZStack {
            Color(hex: "12121A")
            Image(systemName: "sparkle")
                .font(.title)
                .foregroundStyle(Color(hex: "7B61FF").opacity(0.4))
        }
        .frame(width: 169, height: 169)
    }
}

// MARK: - Entry View Router

struct AstroWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: AstroEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct AstroLookWidget: Widget {
    let kind = "AstroLookWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AstroTimelineProvider()) { entry in
            AstroWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Cosmos")
        .description("Today's NASA Astronomy Picture of the Day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct AstroLookWidgetBundle: WidgetBundle {
    var body: some Widget {
        AstroLookWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall, widget: {
    AstroLookWidget()
}, timeline: {
    AstroEntry(
        date: .now,
        title: "The Milky Way Over Monument Valley",
        explanation: "An incredible view of our galaxy stretching across the desert sky, captured on a moonless night.",
        imageData: nil,
        apodDate: "APR 8, 2026"
    )
})

#Preview("Medium", as: .systemMedium, widget: {
    AstroLookWidget()
}, timeline: {
    AstroEntry(
        date: .now,
        title: "The Milky Way Over Monument Valley",
        explanation: "An incredible view of our galaxy stretching across the desert sky, captured on a moonless night.",
        imageData: nil,
        apodDate: "APR 8, 2026"
    )
})

// MARK: - Widget-local Color Helper

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

// MARK: - Widget-local Models

struct APODItem: Codable {
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

    var isImage: Bool { mediaType == "image" }

    var formattedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        guard let parsed = inputFormatter.date(from: date) else { return date }
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy"
        return outputFormatter.string(from: parsed).uppercased()
    }
}

enum NASAWidgetError: Error {
    case http(Int)
}
