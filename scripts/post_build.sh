#!/bin/bash
echo "Running post-build script..."

APP_PATH=/Users/andreea/Develop/extrachain/private_repos/raccoon-ui-win/RacoonUI/build/Qt_6_5_3_for_macOS-Release/appRacoonUI.app
echo "App path: $APP_PATH"
echo "Signing identity: $SIGNING_IDENTITY"

SIGNING_IDENTITY=$2
echo "Signing identity: $SIGNING_IDENTITY"
codesign --deep --force --verify --verbose --sign "Developer ID Application: Vladislav Halasiuk (7GBHZPM2W4)" "$APP_PATH"

echo "Start packing..."
pkgbuild --root "$APP_PATH" --identifier com.raccoonline.vpnapp --version 1.0 --install-location /Applications/RaccoonLine.app RaccoonLine.pkg

productsign --sign "Developer ID Installer: Vladislav Halasiuk (7GBHZPM2W4)" RaccoonLine.pkg SRaccoonLine.pkg

pkgutil --check-signature SRaccoonLine.pkg 
