# AstroLook

An iOS app for exploring NASA's Astronomy Picture of the Day (APOD) — a free archive of space images and videos published daily since June 16, 1995.

## Features

- **Today** — Full-bleed hero image or video for today's APOD with title, date, and astronomer's explanation
- **Browse** — Pick any date range and explore the archive as a thumbnail grid
- **On This Day** — See what NASA published 1, 5, and 10 years ago today
- **Favorites** — Save any APOD to your personal collection (persisted with SwiftData)
- **Search** — Search the NASA Image Library by keyword
- **ELI5** — On-device AI rewrites the technical explanation in plain language (iOS 26+)
- **Surprise Me** — Shuffle button that pulls a random APOD from the full 30-year archive
- **Video support** — Video APODs show a YouTube thumbnail with a tap-to-watch button
- **Home screen widget** — Small and medium WidgetKit widgets showing today's APOD image

## Screenshots

> _Coming soon_

## Requirements

- Xcode 16+
- iOS 18+ deployment target
- A free NASA API key — get one instantly at [api.nasa.gov](https://api.nasa.gov)

## Setup

1. Clone the repo
   ```bash
   git clone https://github.com/sainag7/AstroLook.git
   cd AstroLook
   ```

2. Add your API key
   ```bash
   cp AstroLook/AstroLook/Secrets.swift.example AstroLook/AstroLook/Secrets.swift
   ```
   Then open `Secrets.swift` and replace `YOUR_NASA_API_KEY_HERE` with your key.

3. Open the project in Xcode
   ```bash
   open AstroLook/AstroLook.xcodeproj
   ```

4. Select your simulator or device and press **Run** (⌘R)

## Tech Stack

| | |
|---|---|
| UI | SwiftUI |
| Architecture | MVVM with `@Observable` |
| Persistence | SwiftData |
| Networking | `URLSession` + `async/await` |
| Widgets | WidgetKit |
| On-device AI | Foundation Models (iOS 26) |
| Data | [NASA APOD API](https://api.nasa.gov) + NASA Image Library API |

## Project Structure

```
AstroLook/
├── Models/
│   ├── APODItem.swift          # APOD data model
│   └── FavoriteItem.swift      # SwiftData persistence model
├── Services/
│   ├── NASAService.swift       # All NASA API calls
│   └── FoundationModelsService.swift  # On-device ELI5 AI
├── ViewModels/
│   ├── TodayViewModel.swift
│   ├── BrowseViewModel.swift
│   ├── FavoritesViewModel.swift
│   ├── OnThisDayViewModel.swift
│   └── SearchViewModel.swift
├── Views/
│   ├── TodayView.swift
│   ├── BrowseView.swift
│   ├── DetailView.swift
│   ├── FavoritesView.swift
│   ├── SearchView.swift
│   └── Components/
└── AstroLookWidget/
    └── AstroLookWidget.swift   # WidgetKit timeline provider + views
```

## API Key Security

`Secrets.swift` is listed in `.gitignore` and is never committed. The repo only contains `Secrets.swift.example` as a template. Your key stays local.
