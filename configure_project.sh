#!/bin/bash

echo "🔧 Configuring Xcode project to use Config.xcconfig..."

PROJECT_FILE="/Users/pruthvirajsinhpunada/Desktop/News/Newssss/Newssss.xcodeproj/project.pbxproj"

# Backup the project file
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

# Check if Config.xcconfig is already referenced
if grep -q "Config.xcconfig" "$PROJECT_FILE"; then
    echo "✅ Config.xcconfig is already referenced in project"
else
    echo "❌ Config.xcconfig not found in project - needs manual configuration"
    echo ""
    echo "Please follow these steps in Xcode:"
    echo "1. Open Newssss.xcodeproj"
    echo "2. Click on the Newssss project (blue icon)"
    echo "3. Select the Newssss PROJECT (not target)"
    echo "4. Go to Info tab"
    echo "5. Under Configurations:"
    echo "   - For Debug: Select 'Newssss/Config'"
    echo "   - For Release: Select 'Newssss/Config'"
    echo ""
    echo "If Config doesn't appear:"
    echo "   - Click + to add Config.xcconfig"
    echo "   - Navigate to Newssss/Config.xcconfig"
fi

# Clean and rebuild
echo ""
echo "🧹 Cleaning build..."
cd /Users/pruthvirajsinhpunada/Desktop/News/Newssss
xcodebuild clean -project Newssss.xcodeproj -scheme Newssss > /dev/null 2>&1

echo "✅ Done! Now rebuild in Xcode (Cmd+Shift+K then Cmd+B)"
