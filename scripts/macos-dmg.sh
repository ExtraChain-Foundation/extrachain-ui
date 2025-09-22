#!/bin/bash

# Define application name and DMG file names
APP_NAME="RaccoonLine"
OUTPUT_DMG="RaccoonLine.dmg"
TEMP_DMG="temp_$OUTPUT_DMG"

# Create a temporary DMG using hdiutil
# -volname: sets volume name
# -srcfolder: specifies source folder to package
# -ov: allows overwriting existing file
# -format UDRW: creates read/write disk image
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$APP_NAME.app" \
    -ov -format UDRW \
    "$TEMP_DMG"

# Define mount point and attach the temporary DMG
MOUNT_DIR="/Volumes/$APP_NAME"
hdiutil attach "$TEMP_DMG"

# Create symbolic link to Applications folder for easy app installation
ln -s /Applications "$MOUNT_DIR/Applications"

# Configure Finder window appearance using AppleScript
# This sets up how the DMG window will look when opened:
# - Sets icon view
# - Hides toolbar and status bar
# - Sets window position and size
# - Configures icon size and arrangement
echo '
   tell application "Finder"
     tell disk "'$APP_NAME'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 885, 430}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 128
           close
           open
           update without registering applications
           delay 5
           close
     end tell
   end tell
' | osascript

# Ensure all changes are written to disk
sync

# Unmount the temporary DMG
hdiutil detach "$MOUNT_DIR"

# Convert temporary DMG to compressed format
# UDZO format provides better compression
hdiutil convert "$TEMP_DMG" -format UDZO -o "$OUTPUT_DMG"

# Sign the DMG with Developer ID
codesign --force --sign "Developer ID Application: *** (***)" "$OUTPUT_DMG"

# Clean up by removing temporary DMG
rm "$TEMP_DMG"

# Print completion message
echo "Done! Created and signed $OUTPUT_DMG"

# Verify application signing with detailed output
# --deep: verifies nested code components
# -vvv: provides verbose output about the verification process
echo "Verifying application signature..."
codesign -vvv --deep "$APP_NAME.app"

# Verify DMG signing
echo "Verifying DMG signature..."
codesign -vvv --deep "$OUTPUT_DMG"
