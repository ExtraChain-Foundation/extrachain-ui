# macOS and iOS

1. Generate cmake in QT with CMAKE_GENERATOR=Xcode, CMAKE_OSX_SYSROOT iphoneos or macosx. Only for IOS: VCPKG_TARGET_TRIPLET arm64-ios
  
2. Open RaccoonLine.xcodeproj

    - Go to the Signing & Capabilities tab for the RaccoonLine target.
    - Ensure that Team are set correctly.
    - Ensure that Bundle Identifier is unique and set correctly.
    - Click on + Capability, add Network Extensions, ensure PacketTunnel is checked and Swift.
  
3. Open File → Project Settings, set Derived Data to Project-relative Location, click Advanced... and select Xcode Default.
    
4. Add Tunnel Extension
    - In Xcode, got to File → New → Target, select Network Extension (under either iOS or macOS tab, depending on which platform you want)
    - Set Product Name to "PacketTunnel"
    - Ensure Provider Type is set to Packet Tunnel
    - Ensure Embed in Application is set to RaccoonLine
    - Ensure Team is set correctly. Click Finish. In case Xcode prompts you to activate a schema, select Cancel.
    - Go to the Build Settings tab for the Tunnel Extension target.
        - put the full path to the file inside "Code Signing Entitlements" variable and for "Info.plist File" variable. The folder in the same build directory as your xcodeproj file.
    - Go to the Signing & Capabilities tab for the Tunnel Extension target.
        - Ensure that Team and Bundle Identifier set correctly and there are no errors.
        - Ensure that in Network Extension area Packet Tunnel is checked.
        - In App Sandbox area need to check: "Incoming Connections (Server)", "Outgoing Connections (Client)" 

5. Try to build an APP, there should be any errors

6. Add WireGuardKit package
    - In Xcode, go to File → Add Packages.
    - Click Add local, and provide path to the folder: <full_path>/raccoon-core/third-party/wireguard-apple
    - Select Add to Target: None, and click Add package

7. Create WireGuardGoBridge
    - In Xcode, go to File → New → Target, select External Build System under the Other tab, click Next.
    - Set Product Name as "WireGuardGoBridge" and Build Tool as: /usr/bin/make. Click Finish.
    - Go to the Info tab for the WireGuardGoBridge target.
    - Set directory: <full_path>/raccoon-core/third-party/wireguard-apple/Sources/WireGuardKitGo
    - Go to the Build Settings tab for the WireGuardGoBridge target.
    - Set SDKROOT to "macosx" for MacOS and "iphoneos" for IOS.
    - Click "+" → Add User-Defined Setting. Create variable PATH with ":/usr/local/go/bin". - path to golang executable in the system.
    - Select the Tunnel Extension target. Go to the Build Phases tab.
    - Under the Target Dependencies add WireGuardGoBridge.
    - Under the Link Binary With Libraries add WireGuardKit.
    
8. (NO need for now) Disable bitcode (only for iOS build)
    - Go to the project's Build Settings, search for "bitcode", and set Enable Bitcode to "No".
    

9. Modify code in Tunnel Extension (our PacketTunnel)
    - copy source files from raccoon-ui/SRC/MacOs/NetworkExtension to the <build_dir>/<Tunnel_Extension_folder>
    
10. Recheck that PacketTunnel target has Network Extension in the Signing & Capabilities tab with Packet Tunnel selected

## Qt Kits
```
-DCMAKE_TOOLCHAIN_FILE:FILEPATH=../vcpkg/scripts/buildsystems/vcpkg.cmake
-DVCPKG_CHAINLOAD_TOOLCHAIN_FILE:UNINITIALIZED=%{Qt:QT_INSTALL_PREFIX}/lib/cmake/Qt6/qt.toolchain.cmake
-DVCPKG_TARGET_TRIPLET:UNINITIALIZED=arm64-ios
```

# Android

## Qt Kits CMake Configurator for Android arm64-v8a:
```
-DCMAKE_TOOLCHAIN_FILE:UNINITIALIZED=../vcpkg/scripts/buildsystems/vcpkg.cmake
-DVCPKG_CHAINLOAD_TOOLCHAIN_FILE:UNINITIALIZED=../ndk/26.1.10909125/build/cmake/android.toolchain.cmake
-DVCPKG_TARGET_TRIPLET:UNINITIALIZED=arm64-android
-DCMAKE_MAKE_PROGRAM:UNINITIALIZED=C:/Qt/Tools/Ninja/ninja.exe
```
*Note: For CMAKE_TOOLCHAIN_FILE and VCPKG_CHAINLOAD_TOOLCHAIN_FILE, use your own paths*

## Configuration Steps:
1. Launch Raccoon with this kit
2. Navigate to Project → Android Qt 6.* Clang arm64-v8a → Build → Initial Config
3. In CMAKE_TOOLCHAIN_FILE, clean up the path to Android, leaving only the vcpkg path
4. Click "Re-configure with Initial Parameters"

## Potential Modification:
You might need to modify `vcpkg/triplets/arm64-android.cmake`:

```cmake
set(ANDROID_NDK_PATH ".../ndk/26.1.10909125" CACHE STRING "")

set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_CMAKE_SYSTEM_NAME Android)
set(VCPKG_CMAKE_SYSTEM_VERSION 28)
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${ANDROID_NDK_PATH}/build/cmake/android.toolchain.cmake")
set(VCPKG_MAKE_BUILD_TRIPLET "--host=aarch64-linux-android")
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_CMAKE_CONFIGURE_OPTIONS
    -DANDROID_ABI=arm64-v8a
    -DANDROID_PLATFORM=android-23
)
```
