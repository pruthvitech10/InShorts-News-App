# 📱 News App - Complete Documentation

## 🎯 Project Overview

A modern iOS news aggregation app with an automated backend pipeline that fetches, summarizes, and delivers news articles from 27 RSS sources across 9 categories.

### **Key Features:**
- ✅ Automated news aggregation from 27 RSS sources
- ✅ 30-40 word AI-generated summaries for each article
- ✅ Real-time updates every 10 minutes
- ✅ Offline support with local caching
- ✅ No duplicate articles
- ✅ 24-hour article retention
- ✅ SwiftUI-based iOS app
- ✅ Firebase backend integration

---

## 🏗️ Architecture

### **Backend (Node.js + Firebase)**
```
firebase/functions/src/
├── index.ts              # Main entry point
├── cron-job.ts           # 10-minute cron scheduler
└── unified-pipeline.ts   # Complete news pipeline
```

### **iOS App (Swift + SwiftUI)**
```
Newssss/
├── Core/
│   ├── Constants/        # App constants
│   ├── Extensions/       # Swift extensions
│   ├── Managers/         # Business logic managers
│   ├── Services/         # Network & data services
│   ├── UI/              # Reusable UI components
│   └── Utilities/       # Helper utilities
├── Features/            # Feature modules
├── Models/              # Data models
└── Resources/           # Assets & config
```

---

## 🔄 Backend Pipeline

### **Overview**
The backend runs every 10 minutes and processes news from 27 RSS sources across 9 categories.

### **Pipeline Steps:**

1. **Fetch Articles** - Downloads from 27 RSS sources
2. **Extract Content** - Scrapes full article text using Cheerio
3. **Generate Summaries** - Creates 30-40 word summaries
4. **Deduplicate** - Removes duplicate articles by URL
5. **Filter** - Keeps only articles from last 24 hours
6. **Generate JSON** - Creates category-specific JSON files
7. **Upload** - Saves to Firebase Storage (overwrites old)
8. **Verify** - Confirms upload with `getMetadata()`
9. **Log** - Detailed logging for monitoring

### **Categories:**
- Politics
- Sports
- Technology
- Entertainment
- Business
- World
- Crime
- Automotive
- Lifestyle

### **JSON Structure:**
```json
{
  "category": "sports",
  "updated_at": "2025-11-17T15:00:00.000Z",
  "articles": [
    {
      "title": "Article Title",
      "url": "https://example.com/article",
      "summary": "30-40 word AI-generated summary here",
      "image": "https://example.com/image.jpg",
      "published_at": "2025-11-17T14:00:00.000Z"
    }
  ]
}
```

### **Performance:**
- **Cycle Time:** ~4 minutes (well under 10-minute limit)
- **Articles per Run:** ~135 articles (15 per source × 9 categories)
- **Storage:** Firebase Storage (public URLs)

---

## 📱 iOS Client

### **Architecture:**

#### **FirebaseNewsService.swift**
Main service for fetching news from Firebase Storage.

**Features:**
- Direct public URL fetching
- Local caching for instant loads
- Timestamp-based cache validation
- Automatic offline support
- URL-based deduplication
- Parallel category fetching

**Key Methods:**
```swift
// Fetch single category
func fetchCategory(_ category: String) async throws -> [Article]

// Fetch all categories
func fetchAllCategories() async throws -> [String: [Article]]

// Clear cache
func clearCache()
```

#### **Caching Strategy:**
1. Check local cache
2. Compare `updated_at` timestamps
3. If same: use cache (instant load)
4. If different: download new data
5. If offline: use cache automatically

**Cache Location:** `~/Library/Caches/NewsCache/`

### **Data Models:**

#### **FirebaseNewsResponse**
```swift
struct FirebaseNewsResponse: Codable {
    let category: String
    let updated_at: String
    let articles: [FirebaseArticle]
}
```

#### **FirebaseArticle**
```swift
struct FirebaseArticle: Codable {
    let title: String
    let url: String
    let summary: String        // 30-40 word summary
    let image: String?
    let published_at: String
}
```

#### **Article** (App Model)
```swift
struct Article: Codable, Identifiable {
    let id: UUID
    let source: Source
    let title: String
    let description: String?   // Contains summary
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?
    var metadata: [String: String]?
}
```

### **Performance:**
- **First Load:** ~2-3 seconds
- **Cached Load:** Instant (0.1s)
- **Offline Load:** Instant (0.1s)

---

## 🚀 Setup Instructions

### **Backend Setup:**

1. **Install Dependencies:**
```bash
cd firebase/functions
npm install
```

2. **Deploy to Firebase:**
```bash
npm run deploy
```

3. **Verify Deployment:**
```bash
# Check logs
firebase functions:log

# Manual trigger
curl https://us-central1-news-8b080.cloudfunctions.net/runBackendManual
```

### **iOS Setup:**

1. **Open Project:**
```bash
open Newssss.xcodeproj
```

2. **Install Dependencies:**
- Firebase SDK (via SPM)
- No other dependencies needed

3. **Configure Firebase:**
- Add `GoogleService-Info.plist` to project
- Enable Firebase Storage in console

4. **Build & Run:**
- Select target device/simulator
- Press Cmd+R to build and run

---

## 📊 Data Flow

```
┌─────────────────────────────────────┐
│  BACKEND (Every 10 minutes)         │
│  unified-pipeline.ts                │
├─────────────────────────────────────┤
│  1. Fetch RSS (27 sources)          │
│  2. Extract & summarize (30-40w)    │
│  3. Deduplicate by URL              │
│  4. Filter last 24 hours            │
│  5. Generate JSON per category      │
│  6. Upload to Firebase Storage      │
│  7. Verify with getMetadata()       │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  FIREBASE STORAGE                   │
│  gs://news-8b080.../news/           │
├─────────────────────────────────────┤
│  news_politics.json                 │
│  news_sports.json                   │
│  news_technology.json               │
│  ... (9 files total)                │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  iOS APP                            │
│  FirebaseNewsService.swift          │
├─────────────────────────────────────┤
│  1. Fetch from public URL           │
│  2. Check updated_at timestamp      │
│  3. Use cache if unchanged          │
│  4. Download if changed             │
│  5. Save to local cache             │
│  6. Deduplicate by URL              │
│  7. Display in UI                   │
│                                     │
│  Offline: Load from cache           │
└─────────────────────────────────────┘
```

---

## 🔧 Configuration

### **Backend Configuration:**

**File:** `firebase/functions/src/unified-pipeline.ts`

```typescript
// Cron schedule
.schedule("every 10 minutes")

// Article retention
const RETENTION_HOURS = 24;

// RSS sources (27 sources across 9 categories)
const RSS_SOURCES: Record<string, Array<{url: string; name: string}>> = {
  politics: [...],
  sports: [...],
  // ... etc
};
```

### **iOS Configuration:**

**File:** `Newssss/Core/Constants/AppConstants.swift`

```swift
struct AppConstants {
    static let categories = [
        "politics", "sports", "technology",
        "entertainment", "business", "world",
        "crime", "automotive", "lifestyle"
    ]
    
    static let firebaseStorageURL = 
        "https://firebasestorage.googleapis.com/v0/b/news-8b080.firebasestorage.app/o/news%2Fnews_"
}
```

---

## 🧪 Testing

### **Backend Testing:**

```bash
# Manual trigger
curl https://us-central1-news-8b080.cloudfunctions.net/runBackendManual

# Expected response
{
  "success": true,
  "summary": {
    "total_categories": 9,
    "successful": 9,
    "total_articles": 135
  }
}
```

### **iOS Testing:**

```swift
// Test fetch
Task {
    let articles = try await FirebaseNewsService.shared.fetchCategory("sports")
    print("✅ Fetched \(articles.count) articles")
}

// Test cache
FirebaseNewsService.shared.clearCache()
let cached = try await FirebaseNewsService.shared.fetchCategory("sports")
```

---

## 📈 Monitoring

### **Backend Logs:**
```bash
# View logs
firebase functions:log

# Filter by function
firebase functions:log --only newsAggregatorCron
```

### **Key Metrics:**
- Pipeline execution time (~4 minutes)
- Articles fetched per category
- Upload success rate
- Verification status

### **iOS Metrics:**
- Cache hit rate
- Network request count
- Load times
- Offline usage

---

## 🐛 Troubleshooting

### **Backend Issues:**

**Problem:** Pipeline takes too long
- **Solution:** Reduce articles per source (currently 15)
- **File:** `unified-pipeline.ts` line 169

**Problem:** Upload fails
- **Solution:** Check Firebase Storage permissions
- **Command:** `firebase functions:log`

**Problem:** Summaries too short/long
- **Solution:** Adjust word count limits
- **File:** `unified-pipeline.ts` line 285-290

### **iOS Issues:**

**Problem:** Articles not loading
- **Solution:** Check Firebase Storage URL
- **File:** `FirebaseNewsService.swift` line 89

**Problem:** Cache not working
- **Solution:** Clear cache and retry
- **Code:** `FirebaseNewsService.shared.clearCache()`

**Problem:** Duplicates appearing
- **Solution:** Verify deduplication logic
- **File:** `FirebaseNewsService.swift` line 237-244

---

## 📝 Development Notes

### **Backend:**
- Uses TypeScript for type safety
- Cheerio for web scraping
- Firebase Admin SDK for storage
- Modular function design

### **iOS:**
- SwiftUI for UI
- Async/await for networking
- Codable for JSON parsing
- MVVM architecture pattern

### **Best Practices:**
- ✅ Error handling at every step
- ✅ Detailed logging
- ✅ Type-safe models
- ✅ Modular code structure
- ✅ Offline-first approach
- ✅ Performance optimization

---

## 🔒 Security

### **Backend:**
- Firebase Admin SDK with service account
- Public read-only Storage URLs
- No API keys exposed

### **iOS:**
- Firebase SDK with GoogleService-Info.plist
- Local-only cache storage
- No sensitive data stored

---

## 📦 Dependencies

### **Backend:**
```json
{
  "firebase-admin": "^12.0.0",
  "firebase-functions": "^4.5.0",
  "axios": "^1.6.0",
  "fast-xml-parser": "^4.3.0",
  "cheerio": "^1.0.0-rc.12"
}
```

### **iOS:**
```
- Firebase SDK (via Swift Package Manager)
- No other external dependencies
```

---

## 🎯 Future Enhancements

### **Potential Improvements:**
- [ ] Add more RSS sources
- [ ] Implement user preferences
- [ ] Add push notifications
- [ ] Support more languages
- [ ] Add article sharing
- [ ] Implement search functionality
- [ ] Add article bookmarking
- [ ] Support dark mode themes

---

## 📄 License

This project is for educational purposes.

---

## 👥 Support

For issues or questions:
1. Check troubleshooting section
2. Review Firebase logs
3. Verify configuration files
4. Test with manual trigger

---

## 🎉 Summary

**Backend:**
- ✅ Automated pipeline (10-minute cycle)
- ✅ 27 RSS sources, 9 categories
- ✅ 30-40 word summaries
- ✅ Firebase Storage integration
- ✅ Complete verification

**iOS:**
- ✅ SwiftUI modern interface
- ✅ Smart caching
- ✅ Offline support
- ✅ No duplicates
- ✅ Fast performance

**Status:** Production-ready ✅
