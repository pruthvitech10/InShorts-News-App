# InShorts News

iOS news reader with swipeable cards. Aggregates articles from Italian news sources and displays them in a Tinder-style interface.

## Features

- Swipe through news articles (right to bookmark, left to skip)
- 9 categories: Politics, Sports, Business, Technology, Entertainment, World, Crime, Automotive, Lifestyle
- Auto-generated summaries for quick reading
- Offline caching
- Background refresh every 20 minutes
- Multi-language UI support

## Stack

- SwiftUI + Combine
- Firebase (Auth, Storage)
- RSS feed aggregation via Cloud Functions
- MVVM architecture

## Setup

### Requirements
- Xcode 15+
- iOS 16+
- Node.js 18+ (for backend)
- Firebase project

### Installation

1. Clone and open in Xcode:
```bash
git clone <repo-url>
cd Newssss
open Newssss.xcodeproj
```

2. Add Firebase config:
   - Download `GoogleService-Info.plist` from Firebase Console
   - Add to Xcode project root
   - Enable Authentication and Storage in Firebase

3. Deploy backend:
```bash
cd firebase/functions
npm install
npm run deploy
```

4. Build and run in Xcode

## Project Structure

```
Newssss/
├── App/              # Entry point
├── Models/           # Data structures
├── Core/
│   ├── Services/     # Network, location, storage
│   ├── Managers/     # Auth, bookmarks, persistence
│   └── UI/           # Reusable components
└── Features/
    ├── Feed/         # Main feed
    ├── Search/       # Search & breaking news
    ├── Profile/      # User profile
    └── Settings/     # App settings

firebase/functions/
├── unified-pipeline.ts  # RSS aggregation
├── shuffle-endpoint.ts  # API endpoints
└── cron-job.ts         # Scheduled updates
```

## How It Works

1. Cloud Function runs hourly
2. Fetches from 70+ RSS feeds
3. Extracts article text
4. Generates summaries
5. Deduplicates and categorizes
6. Uploads JSON to Firebase Storage
7. iOS app downloads and caches

## Configuration

Edit RSS sources in `firebase/functions/src/unified-pipeline.ts`.

Modify categories in `Newssss/Models/Category.swift`.

## Contact

Pruthviraj Punada - pruthviraj1022004@gmail.com
