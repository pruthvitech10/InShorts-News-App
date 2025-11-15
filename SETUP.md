# InShorts News App - Setup Instructions

A modern iOS news aggregator app built with SwiftUI that fetches news from 5 different APIs.

## Prerequisites
- Xcode 15.0 or later
- iOS 15.0 or later
- Swift 5.9 or later
- macOS 13.0 or later

## Features
- 📰 Aggregates news from 5 different APIs
- 🔄 Automatic API key rotation
- 📱 Modern SwiftUI interface
- 🔖 Bookmark articles
- 🔍 Search functionality
- 🌍 Location-based news
- 🎨 Beautiful card-based UI

## API Keys Setup

This app requires API keys from multiple news providers. **All keys are FREE** with no credit card required.

### Step 1: Get Your API Keys

#### 1. GNews.io (100 requests/day)
- Visit: https://gnews.io/
- Click "Get API Key"
- Sign up for free
- Copy your API key

#### 2. NewsData.io (500 requests/day)
- Visit: https://newsdata.io/register
- Sign up for free
- Copy your API key from dashboard

#### 3. NewsAPI.org (100 requests/day, development only)
- Visit: https://newsapi.org/register
- Sign up for free
- Copy your API key

#### 4. RapidAPI (Multiple news APIs)
- Visit: https://rapidapi.com/hub
- Sign up for free
- Search for "Real-Time News Data" API
- Subscribe to free tier
- Copy your API key from the API dashboard

#### 5. NewsDataHub (Professional news aggregator)
- Visit: https://newsdatahub.com/dashboards
- Sign up for free
- Copy your API key

### Step 2: Configure API Keys

1. **Copy the example config file:**
   ```bash
   cd Newssss
   cp Config.xcconfig.example Config.xcconfig
   ```

2. **Open `Config.xcconfig` and replace placeholder values with your real API keys:**
   ```
   GNEWS_API_KEYS = your_actual_gnews_key_here
   NEWSDATA_IO_KEYS = your_actual_newsdata_key_here
   NEWS_API_KEYS = your_actual_newsapi_key_here
   RAPIDAPI_KEYS = your_actual_rapidapi_key_here
   NEWSDATAHUB_API_KEYS = your_actual_newsdatahub_key_here
   ```

3. **⚠️ IMPORTANT SECURITY NOTE:**
   - `Config.xcconfig` is already in `.gitignore`
   - **NEVER** commit `Config.xcconfig` to git
   - Only commit `Config.xcconfig.example` (template with placeholders)

### Step 3: Firebase Setup (Optional)

Firebase is optional. The app works without it in anonymous mode.

If you want Firebase Authentication:

1. Go to https://console.firebase.google.com/
2. Create a new project (or use existing)
3. Add an iOS app with bundle ID: `dev.codewithpruthvi.Newssss`
4. Download `GoogleService-Info.plist`
5. Drag `GoogleService-Info.plist` into the `Newssss` folder in Xcode
6. **⚠️ NEVER commit `GoogleService-Info.plist` to git!** (already in `.gitignore`)

**Without Firebase:** The app will automatically work in anonymous mode.

### Step 4: Build and Run

1. Open `Newssss.xcodeproj` in Xcode
2. Select your target device or simulator
3. Clean build folder: `Cmd + Shift + K`
4. Build: `Cmd + B`
5. Run: `Cmd + R`

## Project Structure

```
Newssss/
├── App/
│   └── Newss.swift              # App entry point
├── Core/
│   ├── Config/
│   │   ├── AppConfig.swift      # App configuration
│   │   └── Constants.swift      # Constants
│   ├── Managers/
│   │   ├── APIKeyRotationService.swift  # API key management
│   │   ├── NewsAggregatorService.swift  # News aggregation
│   │   └── ...
│   ├── Services/
│   │   ├── LocationService.swift
│   │   └── ...
│   └── Utilities/
│       └── Logger.swift
├── Features/
│   ├── Feed/
│   ├── Search/
│   ├── Bookmarks/
│   └── Profile/
└── Models/
    └── Article.swift
```

## Troubleshooting

### "No API keys found" error
**Solution:**
- Verify `Config.xcconfig` exists in the `Newssss` folder
- Check that API keys are properly formatted (no extra spaces)
- Clean build folder: `Cmd + Shift + K`
- Rebuild: `Cmd + B`

### "Firebase not configured" warning
**This is normal!** The app works without Firebase.
- If you want Firebase, follow Step 3 above
- Otherwise, ignore this warning - the app will work in anonymous mode

### "Network error" or "Failed to load articles"
**Possible causes:**
- Check your internet connection
- Verify API keys are correct (no typos)
- Check if you've exceeded free tier limits (wait 24 hours)
- Try cleaning and rebuilding the app

### App crashes on launch
**Solution:**
- Make sure you've completed Steps 1-4
- Check Xcode console for specific error messages
- Verify bundle ID matches: `dev.codewithpruthvi.Newssss`

## Security Best Practices

### ✅ What IS committed to GitHub:
- All source code
- `Config.xcconfig.example` (template with placeholders)
- `SETUP.md` (this file)
- `.gitignore` (excludes sensitive files)

### ❌ What is NOT committed (gitignored):
- `Config.xcconfig` (contains real API keys)
- `GoogleService-Info.plist` (Firebase configuration)
- Build artifacts
- User data

### For Contributors:
When contributing to this project:
1. Never commit `Config.xcconfig` with real keys
2. Never commit `GoogleService-Info.plist`
3. Use `Config.xcconfig.example` as reference
4. Test with your own API keys locally

## API Rate Limits

Free tier limits:
- **GNews**: 100 requests/day
- **NewsData.io**: 500 requests/day  
- **NewsAPI.org**: 100 requests/day
- **RapidAPI**: Varies by API (usually 100-500/day)
- **NewsDataHub**: Check their dashboard

**Tips to stay within limits:**
- The app caches articles for 60 seconds
- Multiple API keys are rotated automatically
- Location-based news reduces redundant requests

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

For issues or questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review this SETUP.md file

## Credits

Built with ❤️ using SwiftUI and modern iOS development practices.

---

**Happy coding! 🚀**
