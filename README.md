# 🇮🇹 InShorts - Italian News App

**Lightning-fast Italian news aggregator with hybrid memory architecture**

A modern iOS news app delivering fresh Italian news across 10 categories with instant loading, smart categorization, and zero cache pollution.

## ⚡ Key Features

### 🚀 Hybrid Memory Architecture
- **Instant Loading:** 0.1 second category switching
- **Smart Pre-warming:** Background refresh every 20 minutes  
- **No Disk Cache:** Pure in-memory storage, cleared on app close
- **Always Fresh:** Direct RSS feed fetching from 76 Italian sources

### 🎯 10 News Categories
1. **📰 General** - Everyday news (gold rates, prices, fashion, real estate)
2. **��️ Politics** - 206 articles from 9 verified sources
3. **💼 Business** - Economy, markets, finance (8 sources)
4. **💻 Technology** - Tech news, innovation (8 sources)
5. **🎬 Entertainment** - Cinema, music, TV (7 sources)
6. **⚽ Sports** - Calcio, Serie A, F1 (7 sources)
7. **🌍 World** - International news (8 sources)
8. **⚖️ Crime** - Cronaca, justice (8 sources)
9. **🚗 Automotive** - Cars, motorcycles, racing (7 sources)
10. **🍝 Lifestyle** - Food, travel, wellness (7 sources)

### 🔒 Ultra-Strict Category Enforcement
- **100+ keywords per category** for validation
- **Zero cross-contamination** between categories
- **Priority-based assignment** (Politics > Sports > Tech > etc.)
- **Duplicate removal** - each article appears in ONLY ONE category

### 🔍 Smart Search & Discovery
- **Instant Search:** Search through 1,500+ articles in memory
- **Breaking News:** Top 10 most recent articles from important categories
- **Quick Access:** My Feed, All News, Top Stories, Trending
- **Category Shortcuts:** Politics, Sports, Technology, Entertainment

## 📊 Performance

**Speed:**
- First launch: 5-8 seconds (cold start)
- Subsequent launches: 0.1 seconds (instant!)
- Category switch: 0.1 seconds
- Search: Instant (in-memory)

**Capacity:**
- ~1,500 articles in memory
- 76 RSS feed sources
- 10 categories
- Background refresh every 20 minutes

## 🏗️ Architecture

### Core Services
- **NewsMemoryStore:** In-memory article storage
- **BackgroundRefreshService:** Auto-refresh every 20 minutes
- **CategoryEnforcer:** Strict category validation with 100+ keywords
- **ItalianNewsService:** Unified news fetching interface

### Category Services (Dedicated)
- ItalianPoliticsNewsService (9 sources)
- ItalianSportsNewsService (7 sources)
- ItalianTechnologyNewsService (8 sources)
- ItalianEntertainmentNewsService (7 sources)
- ItalianBusinessNewsService (8 sources)
- ItalianWorldNewsService (8 sources)
- ItalianCrimeNewsService (8 sources)
- ItalianAutomotiveNewsService (7 sources)
- ItalianLifestyleNewsService (7 sources)
- ItalianGeneralNewsService (8 sources)

### Key Technologies
- **SwiftUI** - Modern iOS UI framework
- **Async/Await** - Concurrent news fetching
- **RSS Parsing** - Direct feed parsing
- **Combine** - Reactive programming
- **Background Tasks** - iOS BGTaskScheduler

## 🚀 Getting Started

### Prerequisites
- Xcode 14.0+
- iOS 15.0+
- Swift 5.7+

### Installation

1. Clone the repository
```bash
git clone https://github.com/pruthvitech10/InShorts-News-App.git
cd InShorts-News-App
```

2. Open in Xcode
```bash
open Newssss.xcodeproj
```

3. Build and Run
- Press `Cmd + R`
- App will fetch news on first launch
- Background refresh starts automatically

### No API Keys Required!
All news sources use public RSS feeds - just run the app!

## 📱 Features

### Feed View
- Swipeable card interface
- Infinite scrolling
- Auto-load more at article 80
- Bookmark articles
- Share articles
- Reading history

### Search View
- Instant search through all articles
- Breaking news section
- Category shortcuts
- Search suggestions

### Category View
- My Feed (personalized)
- All News (all categories)
- Top Stories (important news)
- Trending (popular topics)

### Settings
- Category selection
- Notification preferences
- App version info

## 🔧 Configuration

### Background Refresh Interval
Default: 20 minutes

To change, edit `BackgroundRefreshService.swift`:
```swift
private let refreshInterval: TimeInterval = 20 * 60 // 20 minutes
```

### Memory Store
Articles stored in RAM, cleared on app close.

To view stats:
```swift
let totalArticles = NewsMemoryStore.shared.getTotalArticleCount()
let categoryCount = NewsMemoryStore.shared.getCategoryCount()
```

## 📝 Code Structure

```
Newssss/
├── Core/
│   ├── Services/
│   │   ├── NewsMemoryStore.swift
│   │   ├── BackgroundRefreshService.swift
│   │   ├── CategoryEnforcer.swift
│   │   └── CategoryValidator.swift
│   ├── Managers/
│   │   ├── ItalianNewsService.swift
│   │   ├── ItalianPoliticsNewsService.swift
│   │   ├── ItalianSportsNewsService.swift
│   │   └── ... (other category services)
│   └── UI/
│       └── Components/
│           ├── SwipeableCardView.swift
│           └── CardStackView.swift
├── Features/
│   ├── Feed/
│   │   ├── Views/
│   │   │   ├── FeedView.swift
│   │   │   └── CategoryFeedView.swift
│   │   └── ViewModels/
│   │       └── FeedViewModel.swift
│   └── Search/
│       ├── Views/
│       │   └── SearchView.swift
│       └── ViewModels/
│           └── SearchViewModel.swift
└── Models/
    ├── Article.swift
    └── Category.swift
```

## 🎨 UI Components

### SwipeableCardView
- Tinder-style swipe interface
- Left swipe: Skip article
- Right swipe: Mark as seen
- Tap: Read full article
- Bookmark button

### CardStackView
- Manages card stack
- Infinite scrolling
- Auto-load more articles
- Smooth animations

## 🔍 Search Features

### Keyword Matching
Searches in:
- Article titles
- Article descriptions
- Article content

### Breaking News
Shows top 10 most recent articles from:
- Politics
- World
- Business
- General

## 📊 Category Keywords

Each category validated with 100+ keywords:

**Politics:** governo, parlamento, politica, elezioni, ministro...
**Sports:** calcio, serie a, champions, gol, allenatore...
**Technology:** tecnologia, smartphone, app, software, ai...
**Entertainment:** cinema, film, musica, spettacolo, tv...
**Business:** economia, azienda, borsa, finanza, mercato...
**Crime:** cronaca, crimine, polizia, arresto, processo...
**Automotive:** auto, ferrari, moto, formula 1, pilota...
**World:** mondo, internazionale, world, global, paese...
**Lifestyle:** moda, cucina, viaggio, benessere, casa...

## 🛠️ Development

### Running Tests
```bash
xcodebuild test -scheme Newssss -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Building for Release
```bash
xcodebuild archive -scheme Newssss -archivePath build/Newssss.xcarchive
```

## 📄 License

This project is licensed under the MIT License.

## 👤 Author

**Pruthvirajsinh Punada**
- GitHub: [@pruthvitech10](https://github.com/pruthvitech10)

## 🙏 Acknowledgments

- Italian news sources for providing public RSS feeds
- SwiftUI community for UI inspiration
- iOS community for best practices

---

**Built with ❤️ for Italian news readers**

🇮🇹 **Forza Italia!**
