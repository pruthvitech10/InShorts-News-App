#!/bin/sh
# This script reads the Config.xcconfig file and generates a Plist file
# that will be merged with the main Info.plist at build time.

# Path to the source xcconfig file
XCCONFIG_FILE="${PROJECT_DIR}/Newssss/Config.xcconfig"

# Path to the destination plist file
DEST_PLIST="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}.config"

# Check if xcconfig file exists
if [ ! -f "$XCCONFIG_FILE" ]; then
    echo "warning: Config.xcconfig not found at $XCCONFIG_FILE. API keys will be missing."
    exit 0
fi

# Clean destination file
> "$DEST_PLIST"

# Write Plist header
echo '<?xml version="1.0" encoding="UTF-8"?>' >> "$DEST_PLIST"
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> "$DEST_PLIST"
echo '<plist version="1.0">' >> "$DEST_PLIST"
echo '<dict>' >> "$DEST_PLIST"

# Read each line from xcconfig and convert to Plist entry
while IFS='=' read -r key value || [ -n "$key" ]; do
    # Trim whitespace and remove comments
    key=$(echo "$key" | sed 's/ //g' | sed 's/^\/\///')
    value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/;//')

    # Skip empty lines or comments
    if [[ -z "$key" || "$key" == \#* ]]; then
        continue
    fi

    echo "    <key>$key</key>" >> "$DEST_PLIST"
    echo "    <string>$value</string>" >> "$DEST_PLIST"

done < <(grep -v '^\s*$' "$XCCONFIG_FILE")

# Write Plist footer
echo '</dict>' >> "$DEST_PLIST"
echo '</plist>' >> "$DEST_PLIST"

echo "Generated config plist at $DEST_PLIST"
