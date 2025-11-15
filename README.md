# InShorts News App 📰

A modern, beautiful iOS news aggregator app built with SwiftUI that fetches breaking news from 5 different APIs.

![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

- 📰 **Multi-Source News**: Aggregates from 5 different news APIs
- 🔄 **Smart Rotation**: Automatic API key rotation for unlimited access
- 🎨 **Beautiful UI**: Modern card-based interface with smooth animations
- 🔖 **Bookmarks**: Save your favorite articles
- 🔍 **Search**: Find articles across all sources
- 🌍 **Location-Based**: Get local news based on your location
- 📱 **Native iOS**: Built with SwiftUI for iOS 15+
- 🚀 **Fast & Efficient**: Caching and optimized API calls

## 📸 Screenshots

> Add your app screenshots here

## 🚀 Quick Start

See [SETUP.md](SETUP.md) for detailed setup instructions.

### Prerequisites
- Xcode 15.0+
- iOS 15.0+
- Free API keys from news providers (no credit card required)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/newssss.git
   cd newssss
   ```

2. **Set up API keys**
   ```bash
   cd Newssss
   cp Config.xcconfig.example Config.xcconfig
   # Edit Config.xcconfig and add your API keys
   ```

3. **Open in Xcode**
   ```bash
   open Newssss.xcodeproj
   ```

4. **Build and Run**
   - Press `Cmd + R` in Xcode

## 🔑 API Keys

This app uses 5 free news APIs. Get your keys here:

| API | Free Tier | Sign Up |
|-----|-----------|---------|
| GNews | 100 req/day | [gnews.io](https://gnews.io/) |
| NewsData.io | 500 req/day | [newsdata.io](https://newsdata.io/register) |
| NewsAPI.org | 100 req/day | [newsapi.org](https://newsapi.org/register) |
| RapidAPI | Varies | [rapidapi.com](https://rapidapi.com/hub) |
| NewsDataHub | Check site | [newsdatahub.com](https://newsdatahub.com/dashboards) |

**All APIs are FREE with no credit card required!**

## 🏗️ Architecture

- **SwiftUI** for modern, declarative UI
- **MVVM** architecture pattern
- **Async/Await** for network calls
- **Actors** for thread-safe state management
- **Combine** for reactive programming

## 📁 Project Structure

```
Newssss/
├── App/                    # App entry point
├── Core/
│   ├── Config/            # Configuration
│   ├── Managers/          # Business logic
│   ├── Services/          # API services
│   └── Utilities/         # Helper utilities
├── Features/
│   ├── Feed/              # Main news feed
│   ├── Search/            # Search functionality
│   ├── Bookmarks/         # Saved articles
│   └── Profile/           # User profile
└── Models/                # Data models
```

## 🔒 Security

- ✅ API keys stored in gitignored `Config.xcconfig`
- ✅ Firebase config in gitignored `GoogleService-Info.plist`
- ✅ No hardcoded secrets in source code
- ✅ Safe to publish on GitHub

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Important:** Never commit `Config.xcconfig` or `GoogleService-Info.plist`!

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- News APIs for providing free access
- SwiftUI community for inspiration
- All contributors

## 📧 Contact

For questions or support, please open an issue on GitHub.

---

Made with ❤️ using SwiftUI
