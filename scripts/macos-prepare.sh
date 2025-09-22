#!/bin/bash

###############################################################################
# Функції для зручності
###############################################################################

# Перевірка результату виконання команди
check_result() {
    if [ $? -ne 0 ]; then
        echo "❌ Помилка: $1"
        exit 1
    else
        echo "✅ Успішно: $1"
    fi
}

# Безпечне розмонтування
safe_unmount() {
    local mount_point="$1"
    local max_attempts=5
    local attempt=1
    
    # Закриваємо Finder (пробуємо зняти блокування)
    osascript -e 'tell application "Finder" to close every window'
    killall Finder 2>/dev/null
    sleep 2
    
    while [ $attempt -le $max_attempts ]; do
        echo "Спроба розмонтування $attempt із $max_attempts..."
        
        # Убиваємо всі процеси, які можуть блокувати точку монтування
        for pid in $(lsof "$mount_point" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u); do
            echo "Завершуємо процес $pid"
            kill -15 "$pid" 2>/dev/null
            sleep 1
            kill -9 "$pid" 2>/dev/null
        done
        
        # Пробуємо різні методи розмонтування
        if diskutil unmount "$mount_point" 2>/dev/null; then
            echo "✅ Успішно розмонтовано через diskutil"
            return 0
        fi
        
        if diskutil unmount force "$mount_point" 2>/dev/null; then
            echo "✅ Успішно розмонтовано через diskutil force"
            return 0
        fi
        
        if hdiutil detach "$mount_point" 2>/dev/null; then
            echo "✅ Успішно розмонтовано через hdiutil"
            return 0
        fi
        
        if hdiutil detach "$mount_point" -force 2>/dev/null; then
            echo "✅ Успішно розмонтовано через hdiutil force"
            return 0
        fi
        
        # Максимально агресивне розмонтування на останній спробі
        if [ $attempt -eq $max_attempts ]; then
            echo "Пробуємо максимально агресивне розмонтування..."
            sync
            killall Finder DragonDrop Dock 2>/dev/null
            sleep 3
            diskutil unmountDisk force "$mount_point" 2>/dev/null || \
            hdiutil detach -force "$mount_point" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "✅ Успішно розмонтовано агресивним методом"
                return 0
            fi
        fi
        
        sleep 3
        ((attempt++))
    done
    
    echo "❌ Не вдалося розмонтувати після $max_attempts спроб"
    echo "Список процесів, що використовують точку монтування:"
    lsof "$mount_point"
    return 1
}

###############################################################################
# Конфігурація
###############################################################################
APP_NAME="RaccoonLine"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"
TEMP_DMG="temp_$DMG_NAME"
MOUNT_PATH="/Volumes/$APP_NAME"

# Apple Developer ID (приклад)
DEVELOPER_ID="Developer ID Application: RACCOON TECHNOLOGY LTD (247P3AB63W)"

# Профіль keychain для notarytool
KEYCHAIN_PROFILE="RaccoonMacOsDmg"

# Шляхи до Qt та іншого
QML_SRC_DIR="$HOME/ExC/raccoon-ui/UI"
EXTRA_LIBS_PATH="$HOME/ExC/extrachain-3rdparty/ExtraChain_macOS_dylib"

SINGBOX_SRC="../../raccoon-core/third-party/sing-box-1.11.15/preBuildLib/mac/universal/sing-box.dylib"

###############################################################################
# Автоматичний вибір доступної версії Qt
###############################################################################
echo "🔍 Пошук встановлених версій Qt..."
versions=()
while IFS= read -r -d $'\0' path; do
    version=$(basename "$path")
    if [[ -d "$path/macos" ]]; then
        versions+=("$version")
    fi
done < <(find "$HOME/Qt" -maxdepth 1 -mindepth 1 -type d -print0)

if [ ${#versions[@]} -eq 0 ]; then
    echo "❌ Помилка: Qt не знайдено в $HOME/Qt"
    exit 1
elif [ ${#versions[@]} -eq 1 ]; then
    QT_PATH="$HOME/Qt/${versions[0]}/macos"
    echo "✅ Єдина версія Qt знайдена: ${versions[0]}"
else
    echo "Оберіть версію Qt:"
    select version in "${versions[@]}"; do
        if [ -n "$version" ]; then
            QT_PATH="$HOME/Qt/$version/macos"
            echo "✅ Обрано версію Qt: $version"
            break
        fi
    done
fi

###############################################################################
# Створюємо entitlements.plist (мінімальний для Hardened Runtime + JIT)
###############################################################################
cat > entitlements.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Якщо потрібен JIT (наприклад, QtQml/JS), залишаємо. Інакше можна видалити. -->
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
</dict>
</plist>
EOF

###############################################################################
# Створюємо Info.plist
###############################################################################
cat > Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
   "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleAllowMixedLocalizations</key>
    <true/>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>RaccoonLine</string>
    <key>CFBundleIconName</key>
    <string>Icon</string>
    <key>CFBundleIconFile</key>
    <string>raccoon.icns</string>
    <key>CFBundleIdentifier</key>
    <string>com.raccoonline.vpnnet</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>RaccoonLine</string>
    <key>CFBundleDisplayName</key>
    <string>RaccoonLine</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.5.0.5</string>
    <key>CFBundleVersion</key>
    <string>0.5.0.5</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>MacOSX</string>
    </array>
    <key>DTCompiler</key>
    <string>com.apple.compilers.llvm.clang.1_0</string>
    <key>DTPlatformName</key>
    <string>macosx</string>
    <key>DTPlatformVersion</key>
    <string>14.0</string>
    <key>DTSDKBuild</key>
    <string>23F73</string>
    <key>DTSDKName</key>
    <string>macosx14.5</string>
    <key>DTXcode</key>
    <string>1540</string>
    <key>DTXcodeBuild</key>
    <string>15F31d</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSRequiresNativeExecution</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    
    <key>SUFeedURL</key>
    <string>https://raccoonline.com/api/assets/apps/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>Ka1C/9jFo8tXkOiygaPDa9Du+59EUhkdJjeRzG54nKA=</string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUScheduledCheckInterval</key>
    <integer>3600</integer>
</dict>
</plist>
EOF

###############################################################################
# Крок 1: macdeployqt
###############################################################################
echo "Крок 1: Запуск macdeployqt..."
"$QT_PATH/bin/macdeployqt" "$APP_BUNDLE" \
    -qmldir="$QML_SRC_DIR"
check_result "macdeployqt"

###############################################################################
# Крок 2: Копіювання Info.plist всередину .app
###############################################################################
echo "Крок 2: Копіювання Info.plist..."
cp Info.plist "$APP_BUNDLE/Contents/Info.plist"
check_result "Копіювання Info.plist"

# Перевіряємо Info.plist
plutil -lint "$APP_BUNDLE/Contents/Info.plist"
check_result "Перевірка Info.plist"

###############################################################################
# Крок 3: Копіювання додаткових бібліотек (якщо потрібно)
###############################################################################
# echo "Крок 3: Копіювання додаткових бібліотек..."
# mkdir -p "$APP_BUNDLE/Contents/Frameworks/"
# cp "$EXTRA_LIBS_PATH"/* "$APP_BUNDLE/Contents/Frameworks/"
# check_result "Копіювання бібліотек"

###############################################################################
# Крок 3.5: Вкладаємо sing-box.dylib і фіксим шляхи завантаження (install_name)
###############################################################################
echo "Крок 3.5: Вкладання sing-box.dylib + install_name_tool..."

APP_EXEC="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"
SINGBOX_DST="$FRAMEWORKS_DIR/sing-box.dylib"

# Проверки
[ -f "$SINGBOX_SRC" ] || { echo "❌ Не знайдено $SINGBOX_SRC"; exit 1; }
[ -f "$APP_EXEC" ]    || { echo "❌ Не знайдено $APP_EXEC"; exit 1; }

mkdir -p "$FRAMEWORKS_DIR"
cp -f "$SINGBOX_SRC" "$SINGBOX_DST"
check_result "Копіювання sing-box.dylib у .app"

# (необов'язково) привести install_name самої бібліотеки до акуратного ID
install_name_tool -id "@rpath/sing-box.dylib" "$SINGBOX_DST" 2>/dev/null

# Переписуємо залежність у основному бінарі з "sing-box.dylib" на локальний шлях у бандлі
# Використовуємо @loader_path (не треба чіпати rpath)
install_name_tool -change "sing-box.dylib" \
    "@loader_path/../Frameworks/sing-box.dylib" \
    "$APP_EXEC" || true

# Перевіримо залежності
echo "otool -L (після правок):"
otool -L "$APP_EXEC" | sed 's/^/   /'

###############################################################################
# Крок 4: Підпис Qt-фреймворків та dylib всередині .app
###############################################################################
echo "Крок 4: Підпис Qt-фреймворків..."
SPARKLE_PATH="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"

codesign --force \
    --sign "$DEVELOPER_ID" \
    --options runtime \
    --timestamp \
    --deep \
    "$SPARKLE_PATH/Versions/Current/Updater.app"
check_result "Підпис Sparkle Updater.app"

# Підписуємо XPC сервіси
codesign --force \
    --sign "$DEVELOPER_ID" \
    --options runtime \
    --timestamp \
    --deep \
    "$SPARKLE_PATH/Versions/Current/XPCServices/Downloader.xpc"
check_result "Підпис Sparkle Downloader.xpc"

codesign --force \
    --sign "$DEVELOPER_ID" \
    --options runtime \
    --timestamp \
    --deep \
    "$SPARKLE_PATH/Versions/Current/XPCServices/Installer.xpc"
check_result "Підпис Sparkle Installer.xpc"

# Підписуємо бінарники
codesign --force \
    --sign "$DEVELOPER_ID" \
    --options runtime \
    --timestamp \
    "$SPARKLE_PATH/Versions/Current/Sparkle"
check_result "Підпис Sparkle binary"

# Тільки Current версію підписуємо
codesign --force \
    --sign "$DEVELOPER_ID" \
    --options runtime \
    --timestamp \
    "$SPARKLE_PATH/Versions/Current"
check_result "Підпис Current версії"

find "$APP_BUNDLE/Contents" \( -name "*.framework" -o -name "*.dylib" \) -type f | while read framework; do
    # Пропускаємо Sparkle.framework
    if [[ "$framework" != *"Sparkle.framework"* ]]; then
        codesign --force \
            --sign "$DEVELOPER_ID" \
            --options runtime \
            --timestamp \
            "$framework"
        check_result "Підпис фреймворка/бібліотеки: $(basename "$framework")"
    fi
done

###############################################################################
# Крок 5: Підпис Qt-плагінів (папка PlugIns)
###############################################################################
echo "Крок 5: Підпис Qt плагінів..."
find "$APP_BUNDLE/Contents/PlugIns" -type f | while read plugin; do
    codesign --force \
        --sign "$DEVELOPER_ID" \
        --options runtime \
        --timestamp \
        "$plugin"
    check_result "Підпис плагіна: $(basename "$plugin")"
done

###############################################################################
# Крок 6: Підпис основного додатку (з entitlements)
###############################################################################
echo "Крок 6: Підпис основного .app..."
codesign --force \
    --sign "$DEVELOPER_ID" \
    --options runtime \
    --entitlements entitlements.plist \
    --timestamp \
    --deep \
    --preserve-metadata=identifier,entitlements,flags \
    "$APP_BUNDLE"
check_result "Підпис основного додатку"

###############################################################################
# Крок 7: Перевірка підпису .app
###############################################################################
echo "Крок 7: Перевірка підпису додатку..."
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
check_result "Перевірка підпису додатку"

###############################################################################
# Крок 8: Створення ZIP для нотаризації додатку
###############################################################################
echo "Крок 8: Створення тимчасового zip для нотаризації..."
APP_ZIP="$APP_NAME.zip"
ditto -c -k --keepParent "$APP_BUNDLE" "$APP_ZIP"
check_result "Створення zip"

###############################################################################
# Крок 9: Нотаризація .app (ZIP)
###############################################################################
echo "Крок 9: Відправка на нотаризацію..."
xcrun notarytool submit "$APP_ZIP" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait
check_result "Нотаризація"

###############################################################################
# Крок 10: Stapler (скріплення) .app
###############################################################################
echo "Крок 10: Застосування stapler до додатку..."
xcrun stapler staple "$APP_BUNDLE"
check_result "Stapler"

# Перевірка після нотаризації (spctl)
spctl --assess --type exec -v "$APP_BUNDLE"
check_result "Перевірка Gatekeeper .app"

###############################################################################
# Крок 11: Створення DMG
###############################################################################
echo "Крок 11: Створення DMG..."
[ -f "$DMG_NAME" ] && rm "$DMG_NAME"
[ -f "$TEMP_DMG" ] && rm "$TEMP_DMG"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$APP_BUNDLE" \
    -ov -format UDRW \
    "$TEMP_DMG"
check_result "Створення тимчасового DMG"

echo "Монтування DMG..."
hdiutil attach "$TEMP_DMG" -mountpoint "$MOUNT_PATH"
check_result "Монтування DMG"

echo "Налаштування зовнішнього вигляду DMG (Finder)..."
ln -s /Applications "$MOUNT_PATH/Applications"
check_result "Створення посилання на /Applications"

# Налаштування положення іконок і т.д. (скрипт Finder):
echo '
   tell application "Finder"
     tell disk "'$APP_NAME'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 900, 450}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 72
           set position of item "'$APP_NAME.app'" of container window to {120, 180}
           set position of item "Applications" of container window to {380, 180}
           close
           open
           update without registering applications
           delay 5
           close
     end tell
   end tell
' | osascript

echo "Розмонтування DMG..."
safe_unmount "$MOUNT_PATH"
check_result "Розмонтування DMG"

echo "Створюємо копію тимчасового DMG..."
cp "$TEMP_DMG" "${TEMP_DMG}_copy"
check_result "Копіювання тимчасового DMG"

# Конвертуємо копію
hdiutil convert "${TEMP_DMG}_copy" -format UDZO -o "$DMG_NAME"
convert_result=$?

# Видаляємо тимчасові файли
rm -f "${TEMP_DMG}_copy"

if [ $convert_result -ne 0 ]; then
    echo "❌ Помилка: Конвертація DMG"
    exit 1
fi

check_result "Конвертація DMG"

###############################################################################
# Крок 12: Підпис DMG (без sandbox-ентітлів!)
###############################################################################
echo "Крок 12: Підпис DMG..."
codesign --force \
    --sign "$DEVELOPER_ID" \
    --options runtime \
    --timestamp \
    "$DMG_NAME"
check_result "Підпис DMG"

###############################################################################
# Крок 13: Нотаризація DMG
###############################################################################
echo "Крок 13: Нотаризація DMG..."
xcrun notarytool submit "$DMG_NAME" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait
check_result "Нотаризація DMG"

###############################################################################
# Крок 14: Stapler DMG
###############################################################################
echo "Крок 14: Застосування stapler до DMG..."
xcrun stapler staple "$DMG_NAME"
check_result "Stapler для DMG"

###############################################################################
# Очищення тимчасових файлів
###############################################################################
echo "Очищення тимчасових файлів..."
rm -f "$APP_ZIP" Info.plist entitlements.plist

###############################################################################
# Підсумкова перевірка
###############################################################################
echo "✨ Готово! Додаток та DMG створені, підписані, нотаризовані."
echo "📝 Перевірте результати:"
echo "1. Підпис додатку:"
codesign -dvv "$APP_BUNDLE"
echo
echo "2. Підпис DMG:"
codesign -dvv "$DMG_NAME"
echo
echo "3. Перевірка stapler для DMG:"
stapler validate "$DMG_NAME"
echo
echo "4. Перевірка вбудовання sing-box та шляху завантаження:"
if [ -f "$APP_BUNDLE/Contents/Frameworks/sing-box.dylib" ]; then
  echo "   ✅ sing-box.dylib присутній у .app"
else
  echo "   ❌ sing-box.dylib відсутній у .app"; exit 1
fi

if otool -L "$APP_BUNDLE/Contents/MacOS/$APP_NAME" | grep -q "@loader_path/../Frameworks/sing-box.dylib"; then
  echo "   ✅ шлях OK: @loader_path/../Frameworks/sing-box.dylib"
else
  echo "   ❌ некоректний шлях до sing-box у бінарі"; exit 1
fi
echo
echo "5. Додатково Gatekeeper-перевірка DMG (spctl -a -v):"
spctl -a -t open --context context:primary-signature -v "RaccoonLine.dmg"

exit 0
