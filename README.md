# 📰 InShorts - News Reader App

Modern iOS news reader with swipeable Tinder-style cards. Aggregates articles from 70+ Italian news sources across 9 categories.

## ✨ Features

- **Swipeable Cards** - Tinder-style interface for quick news browsing
- **9 Categories** - Politics, Sports, Business, Technology, Entertainment, World, Crime, Automotive, Lifestyle
- **Smart Summaries** - AI-generated summaries for quick reading
- **Offline First** - Instant load from cache, zero waiting
- **Unlimited Content** - 200-500 articles per category
- **Multi-Auth** - Google Sign In, Apple Sign In, Anonymous
- **Profile Customization** - Upload profile photos, personalize settings
- **Bookmark System** - Save unlimited articles
- **Background Refresh** - Auto-updates every 2 hours
- **Dark Mode** - Full light/dark theme support

## 🛠 Tech Stack

### iOS App
- **SwiftUI** - Modern declarative UI
- **Combine** - Reactive programming
- **Firebase Auth** - Google & Apple Sign In
- **Firebase Storage** - Article & photo storage
- **MVVM** - Clean architecture

### Backend
- **Firebase Cloud Functions** - Node.js/TypeScript
- **RSS Aggregation** - 70+ Italian news sources
- **Web Scraping** - Cheerio for article extraction
- **Smart Summarization** - HuggingFace AI models
- **Scheduled Cron** - Runs every 2 hours

## 📋 Requirements

- **Xcode** 15+
- **iOS** 16+
- **Node.js** 20+
- **Firebase** project
- **Apple Developer Account** (for Apple Sign In)

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/inshorts-news.git
cd Newssss
```

### 2. Firebase Setup
1. Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Download `GoogleService-Info.plist`
3. Add to Xcode project (drag into Newssss folder)
4. Enable Authentication providers:
   - Google Sign In
   - Apple Sign In
5. Enable Firebase Storage

### 3. iOS Setup
```bash
open Newssss.xcodeproj
```

In Xcode:
1. Select **Newssss** target
2. **Signing & Capabilities** → Add your Team
3. **Signing & Capabilities** → Add "Sign in with Apple" capability
4. Build & Run (⌘R)

### 4. Backend Deployment
```bash
cd firebase/functions
npm install
firebase login
firebase deploy --only functions
```

## 📱 App Architecture

```
Newssss/
├── App/
│   └── Newss.swift                  # App entry point
├── Core/
│   ├── Services/
│   │   ├── BackgroundRefreshService.swift
│   │   ├── BookmarkService.swift
│   │   └── SeenArticlesService.swift
│   ├── Managers/
│   │   ├── FirebaseAuthenticationManager.swift
│   │   ├── NetworkMonitor.swift
│   │   └── PersistenceManager.swift
│   └── UI/
│       └── Components/              # Reusable UI components
├── Features/
│   ├── Feed/
│   │   ├── Views/
│   │   │   ├── FeedView.swift      # Main feed
│   │   │   └── CardStackView.swift # Swipeable cards
│   │   └── ViewModels/
│   │       └── FeedViewModel.swift  # Feed logic
│   ├── Search/
│   │   └── Views/
│   │       └── SearchView.swift     # Search interface
│   ├── Profile/
│   │   └── Views/
│   │       ├── ProfileView.swift    # User profile
│   │       └── SignInOptionsView.swift # Auth screen
│   └── Settings/
│       └── Views/
│           └── SettingsView.swift   # App settings
└── Models/
    ├── Article.swift
    ├── Category.swift
    └── AppUser.swift
```

## ☁️ Backend Structure

```
firebase/functions/src/
├── unified-pipeline.ts     # Main RSS aggregation pipeline
├── cron-job.ts            # Scheduled job (every 2 hours)
├── shuffle-endpoint.ts    # API endpoints
└── count-articles.ts      # Monitoring tool
```

### How Backend Works

1. **Cron trigger** → Runs every 2 hours
2. **Fetch RSS** → 70+ news sources
3. **Extract content** → Web scraping with Cheerio
4. **Generate summaries** → AI-powered summarization
5. **Deduplicate** → Remove duplicates across sources
6. **Categorize** → Sort into 9 categories
7. **Upload JSON** → Firebase Storage
8. **iOS downloads** → App fetches and caches

## 🔐 Authentication

### Supported Methods
- ✅ Google Sign In
- ✅ Apple Sign In
- ✅ Anonymous (Guest)

### Apple Sign In Setup
1. **Apple Developer Portal**:
   - Enable "Sign in with Apple" for your App ID
2. **Firebase Console**:
   - Enable Apple provider in Authentication
3. **Xcode**:
   - Add "Sign in with Apple" capability

## 🎨 Key Features Implementation

### Cache-First Architecture
- Instant load from cache
- Zero blank screens
- Background updates don't block UI

### Infinite Content
- No artificial limits
- 200-500 articles per category
- Unlimited bookmarks

### Smart Article Tracking
- Permanent seen tracking
- Both swipe directions mark as seen
- Cross-category tracking

### Atomic Operations
- Cache replaced only after successful fetch
- No data loss
- Graceful error handling

## 📊 RSS Sources

70+ Italian news sources including:
- ANSA, La Repubblica, Corriere della Sera
- Il Sole 24 Ore, Il Post, Gazzetta dello Sport
- Sky TG24, RaiNews, Fanpage
- Wired Italia, HWUpgrade, Quattroruote

## 🛠 Configuration

### Modify RSS Sources
Edit `firebase/functions/src/unified-pipeline.ts`:
```typescript
const RSS_SOURCES = {
  politics: [
    {url: "https://...", name: "Source Name"},
    // Add more sources
  ],
  // Add more categories
}
```

### Modify Categories
Edit `Newssss/Models/Category.swift`:
```swift
enum Category: String, CaseIterable {
    case general, politics, sports
    // Add more categories
}
```

### Adjust Update Frequency
Edit `firebase/functions/src/cron-job.ts`:
```typescript
.schedule("every 2 hours")  // Change frequency
```

## 🧪 Testing

### iOS App
```bash
# Run on simulator
xcodebuild -project Newssss.xcodeproj -scheme Newssss -sdk iphonesimulator build

# Run tests
xcodebuild test -project Newssss.xcodeproj -scheme Newssss -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Backend
```bash
cd firebase/functions
npm run build
npm test  # If you have tests
```

### Manual Article Count Check
```bash
cd firebase/functions
npm run build
node lib/count-articles.js
```

## 📈 Monitoring

### View Logs
```bash
# iOS app logs
# Check Xcode console while running

# Backend logs
cd firebase
firebase functions:log
```

### Check Article Counts
Cloud Function endpoint:
```
https://us-central1-news-8b080.cloudfunctions.net/checkArticleCount
```

## 🐛 Troubleshooting

### Build Issues
- Clean build folder: Product → Clean Build Folder (⇧⌘K)
- Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Re-install pods if needed

### Authentication Issues
- Verify `GoogleService-Info.plist` is added
- Check Firebase Console → Authentication → Sign-in providers enabled
- Apple Sign In only works on real device, not simulator

### Backend Issues
- Check Firebase Console → Functions for error logs
- Verify all environment variables are set
- Check function timeout (540s max)

## 📦 Dependencies

### iOS (Swift Package Manager)
- Firebase iOS SDK
- Google Sign-In
- No CocoaPods needed

### Backend (npm)
- firebase-functions
- firebase-admin
- axios
- cheerio
- fast-xml-parser

## 🔒 Security

- User tokens encrypted
- Firebase security rules configured
- API keys not exposed in code
- Secure nonce generation for Apple Sign In

## 📝 Bundle ID

`dev.codewithpruthvi.Newssss`

## 📄 License

MIT License

## 👨‍💻 Author

**Pruthviraj Punada**
- Email: punadapruthvirajsingh@gmail.com
- GitHub: [@pruthvitech10](https://github.com/pruthvitech10)

## 🙏 Acknowledgments

- Firebase for backend infrastructure
- RSS news sources for content
- SwiftUI community for inspiration

---

**Made with ❤️ for news readers everywhere**
