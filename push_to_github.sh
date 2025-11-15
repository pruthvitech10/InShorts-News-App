#!/bin/bash

echo "🔍 Checking what will be committed..."
echo ""

# Show status
git status

echo ""
echo "⚠️  IMPORTANT: Verify Config.xcconfig is NOT listed above!"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Add all files
echo "📦 Adding files..."
git add .

# Commit
echo "💾 Committing..."
git commit -m "Initial commit: InShorts News App

- Modern SwiftUI news aggregator
- Integrates 5 news APIs (GNews, NewsData.io, NewsAPI, RapidAPI, NewsDataHub)
- Automatic API key rotation
- Beautiful card-based UI
- Bookmark functionality
- Search across all sources
- Location-based news
- Secure API key management (gitignored)
- Ready for production"

echo ""
echo "✅ Committed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Create a new repository on GitHub: https://github.com/new"
echo "2. Copy the repository URL (e.g., https://github.com/yourusername/InShorts-News-App.git)"
echo "3. Run these commands:"
echo ""
echo "   git remote add origin YOUR_REPO_URL"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
