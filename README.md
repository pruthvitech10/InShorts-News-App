# InShorts - Italian News App

A SwiftUI news reader focused on Italian sources. The app fetches every article directly from RSS feeds, stores the data in memory for instant display, and refreshes everything silently every twenty minutes.

## Highlights
- Hybrid in-memory architecture: cold launch fetches, subsequent launches read from RAM (≈0.1 s category switch).
- Ten dedicated Italian categories (politics, sports, business, technology, entertainment, world, crime, automotive, lifestyle, general).
- Background fetch wipes and refills the memory store every 20 minutes, no disk cache or stale content.
- CategoryEnforcer validates each article with 100+ keywords and guarantees that no story appears in two categories.
- Search screen scans all in-memory articles instantly and provides a Breaking News rail sourced from the most important categories.

## Data Pipeline
1. `BackgroundRefreshService` schedules a BGTask every 20 minutes.
2. `Italian…NewsService` files fetch RSS feeds per category (76 feeds in total).
3. `CategoryEnforcer` filters and deduplicates the payload.
4. `NewsMemoryStore` publishes the cleaned articles for the UI.
5. `FeedViewModel` and `SearchViewModel` render cached data immediately and trigger silent refreshes when content is older than 30 minutes.

## Architecture
```
Newssss
├── Core
│   ├── Config (AppConfig, Constants)
│   ├── Managers (NewsAggregator, Bookmark, SwipeHistory, Translation, etc.)
│   ├── Services (BackgroundRefresh, CategoryEnforcer, NewsMemoryStore, RSSFetch, Location, NetworkMonitor)
│   ├── UI Components (CardStackView, SafariView, Loading/Error states)
│   └── Extensions & Utilities (Date formatting, validation, view modifiers)
├── Features
│   ├── Feed (views + view model)
│   ├── Search (views + view model)
│   ├── ArticleDetail
│   └── Profile/Settings
├── Models (Article, Category, UserSettings, Toast)
└── README.md
```

## Getting Started
1. `git clone https://github.com/pruthvitech10/InShorts-News-App.git`
2. `cd InShorts-News-App`
3. Open `Newssss.xcodeproj` in Xcode 15+.
4. Build & run on iOS 15+ simulator or device. No API keys are required because all feeds are public.

## Development Notes
- The project uses Swift Concurrency throughout (async/await).
- All networking goes through `RSSFetchService` which wraps URLSession and parses XML into `Article` models.
- `NewsMemoryStore` is the single source of truth for the UI. When the app terminates, memory is cleared and everything reloads on next launch.
- Tests can be added with `xcodebuild test -scheme Newssss -destination 'platform=iOS Simulator,name=iPhone 15'`.

## License
MIT
