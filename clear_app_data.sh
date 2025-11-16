#!/bin/bash

# Clear App Data Script
# This will delete all app data, cache, and preferences

echo "🗑️  Clearing all app data..."

# Get the app bundle identifier
BUNDLE_ID="dev.codewithpruthvi.Newssss"

# Kill the app if running
echo "📱 Stopping app..."
xcrun simctl terminate booted $BUNDLE_ID 2>/dev/null

# Delete app from simulator
echo "🗑️  Deleting app from simulator..."
xcrun simctl uninstall booted $BUNDLE_ID 2>/dev/null

# Clear derived data
echo "🗑️  Clearing Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Newssss-*

# Clear build folder
echo "🗑️  Clearing build folder..."
cd "$(dirname "$0")"
rm -rf build/

# Clear simulator caches
echo "🗑️  Clearing simulator caches..."
xcrun simctl erase all 2>/dev/null || echo "⚠️  Could not erase all simulators (some may be running)"

echo "✅ All app data cleared!"
echo "📱 Now rebuild and run the app for a fresh start"
