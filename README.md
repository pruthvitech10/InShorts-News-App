# InShorts - Your Daily News Companion

A modern, fast, and beautiful news aggregation app for iOS that delivers the latest headlines in a clean, swipeable card interface. Built with SwiftUI and powered by Firebase.

## ✨ Features

### 📰 Smart News Aggregation
- Real-time news from multiple trusted sources
- AI-powered article summarization
- Automatic categorization (Politics, Business, Technology, Sports, etc.)
- Intelligent deduplication to avoid repetitive content

### 🎯 Personalized Experience
- Swipe-based card interface for quick browsing
- Bookmark your favorite articles
- Breaking news section with instant updates
- Multi-language support (English, Hindi, Spanish, French, German)

### 🚀 Performance Optimized
- Lightning-fast app launch (2-3 seconds)
- Efficient caching for offline reading
- Background refresh for fresh content
- Optimized image loading and memory management

### 🎨 Beautiful Design
- Clean, modern interface following iOS design guidelines
- Dark mode support
- Smooth animations and transitions
- Intuitive navigation

### 🔐 Privacy First
- Google Sign-In integration
- Secure data handling
- No tracking or data selling
- Full control over your data

## 📱 Screenshots

[Add your app screenshots here]

## 🛠 Tech Stack

### iOS App
- **SwiftUI** - Modern declarative UI framework
- **Combine** - Reactive programming
- **Firebase Auth** - User authentication
- **Firebase Storage** - News data storage
- **MVVM Architecture** - Clean, maintainable code structure

### Backend
- **Firebase Functions** - Serverless backend
- **TypeScript** - Type-safe server code
- **RSS Feed Aggregation** - Multi-source news gathering
- **Cron Jobs** - Automated news updates every 2 hours

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 16.0 or later
- Node.js 18+ (for Firebase Functions)
- Firebase account

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/inshorts-clone.git
cd inshorts-clone
```

2. Install iOS dependencies
```bash
cd Newssss
# Open Newssss.xcodeproj in Xcode
```

3. Set up Firebase
- Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
- Download `GoogleService-Info.plist` and add it to the Xcode project
- Enable Google Sign-In in Firebase Authentication
- Enable Firebase Storage

4. Install backend dependencies
```bash
cd firebase/functions
npm install
```

5. Deploy Firebase Functions
```bash
npm run deploy
```

6. Build and run the app in Xcode

## 📖 Configuration

### Firebase Setup
1. Update `firebase/functions/src/unified-pipeline.ts` with your RSS feed sources
2. Configure storage rules in Firebase Console
3. Set up authentication providers

### App Configuration
- Update `Info.plist` with your Firebase configuration
- Customize app icon and branding in Assets.xcassets
- Modify categories in `Models/Category.swift`

## 🏗 Architecture

The app follows MVVM (Model-View-ViewModel) architecture:

```
Newssss/
├── App/                    # App entry point
├── Core/
│   ├── Services/          # Network, Storage, Location services
│   ├── Managers/          # Auth, Translation, Localization
│   └── UI/                # Reusable UI components
├── Features/
│   ├── Feed/              # Main news feed
│   ├── Search/            # Search and Breaking News
│   ├── Profile/           # User profile and settings
│   └── Settings/          # App settings
└── Models/                # Data models

firebase/functions/
├── src/
│   ├── unified-pipeline.ts    # News aggregation logic
│   ├── shuffle-endpoint.ts    # API endpoints
│   └── cron-job.ts           # Scheduled tasks
```

## 🔄 News Update Flow

1. **Cron Job** runs every 2 hours
2. Fetches articles from RSS feeds
3. Scrapes full article content
4. Generates AI summaries
5. Categorizes and deduplicates
6. Stores in Firebase Storage as JSON
7. iOS app fetches and displays

## 🎯 Key Features Explained

### Smart Caching
The app uses a multi-layer caching strategy:
- **Memory Cache**: Instant access to recent articles
- **Disk Cache**: Persistent storage for offline reading
- **Background Refresh**: Updates content when app is idle

### Breaking News
- Aggregates latest articles from all categories
- Sorts by publication date
- Updates in real-time
- Displays top 10 most recent stories

### Search
- Searches across all cached articles
- Fetches missing categories on-demand
- Relevance-based sorting
- Fast, responsive results

## 🌍 Localization

Supported languages:
- English (en)
- Hindi (hi)
- Spanish (es)
- French (fr)
- German (de)

Add new languages by updating `Localizable.strings` files.

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- News sources for providing RSS feeds
- Firebase for backend infrastructure
- SwiftUI community for inspiration and support

## 📧 Contact

Pruthviraj Punada - pruthviraj1022004@gmail.com

Project Link: [https://github.com/yourusername/inshorts-clone](https://github.com/yourusername/inshorts-clone)

---

Made with ❤️ for news enthusiasts
