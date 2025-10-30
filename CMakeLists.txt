cmake_minimum_required(VERSION 3.26)

set(PROJECT_NAME ExtrachainUI)

set(PROJECT_VERSION_MAJOR 0)
set(PROJECT_VERSION_MINOR 1)
set(PROJECT_VERSION_PATCH 0)
set(PROJECT_VERSION_TWEAK 0)
set(PROJECT_VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}.${PROJECT_VERSION_TWEAK}")

project(ExtrachainUI VERSION ${PROJECT_VERSION} LANGUAGES C CXX)


# Option to build the console version for users.
option(EXTRACHAIN_CONSOLE "Build the console version" OFF) # TODO: rename to EXTRACHAIN_*
option(EXTRACHAIN_CLIENT_CONSOLE "Build the console version for users" OFF)
option(EXTRACHAIN_PLAY_MARKET "Build the console version for users" OFF)
option(EXTRACHAIN_MESSENGER "Messenger client" OFF)

set(QT_COMPONENTS Core Network)
if(NOT EXTRACHAIN_CONSOLE)
    list(APPEND QT_COMPONENTS Concurrent Quick Core5Compat Gui WebSockets LabsQmlModels Network Svg QuickControls2 LinguistTools)
endif()

find_package(Qt6 REQUIRED COMPONENTS ${QT_COMPONENTS})
qt_standard_project_setup(REQUIRES 6.9)


# Global definition: applies to all targets in this directory and subdirectories.
add_compile_definitions($<$<BOOL:${EXTRACHAIN_CONSOLE}>:EXTRACHAIN_CONSOLE>)
add_compile_definitions($<$<BOOL:${EXTRACHAIN_CLIENT_CONSOLE}>:EXTRACHAIN_CLIENT_CONSOLE>)
add_compile_definitions($<$<BOOL:${EXTRACHAIN_PLAY_MARKET}>:EXTRACHAIN_PLAY_MARKET>)
add_compile_definitions($<$<BOOL:${EXTRACHAIN_MESSENGER}>:EXTRACHAIN_MESSENGER>)

# Build type message
if(EXTRACHAIN_CONSOLE)
    message(STATUS "Build type: Console version")
else()
    message(STATUS "Build type: GUI version")
endif()

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Check for required tools and dependencies
if(NOT DEFINED CMAKE_TOOLCHAIN_FILE OR CMAKE_TOOLCHAIN_FILE STREQUAL "")
    message(WARNING "Set path to vcpkg.cmake. <PATH/TO/VCPKG>/scripts/buildsystems/vcpkg.cmake")
    message(FATAL_ERROR "CMAKE_TOOLCHAIN_FILE must be set Initial Configuration.")
endif()

set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(USE_QZXING OFF)

if(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    add_definitions(-DEXTRACHAIN_RELEASE_WITH_DEBUG_INFO)
endif()


if(NOT EXTRACHAIN_CONSOLE)
    set(BUILD_WITH_QT6 ON)

    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../extrachain-3rdparty/qtkeychain ${CMAKE_CURRENT_BINARY_DIR}/qtkeychain)
        add_subdirectory(
            ${CMAKE_CURRENT_SOURCE_DIR}/../extrachain-3rdparty/BlurhashQt
            ${CMAKE_CURRENT_BINARY_DIR}/BlurhashQt
        )

    if(USE_QZXING)
        set(QZXING_USE_QML ON)
        set(QZXING_USE_ENCODER ON)
        set(QZXING_USE_DECODER_QR_CODE ON)
        set(QZXING_MULTIMEDIA OFF)
        add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../extrachain-3rdparty/QZXing ${CMAKE_CURRENT_BINARY_DIR}/QZXing)
    endif()

    set(BUILD_SHARED_LIBS OFF)

    if(CMAKE_OSX_SYSROOT STREQUAL "iphoneos")
        message("Start configure ios")
        set(CMAKE_SYSTEM_NAME iOS)
        set(CMAKE_OSX_DEPLOYMENT_TARGET "16.3")
        set(CMAKE_SYSTEM_NAME iOS)

        set(BUILD_SHARED_LIBS OFF)

        set(CMAKE_SYSTEM_NAME iOS)
        set(CMAKE_OSX_SYSROOT iphoneos)
        set(CMAKE_OSX_ARCHITECTURES "arm64")

        set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/ios/extrachain.icns")
        set(STORYBOARD_FILE "${CMAKE_SOURCE_DIR}/ios/Storyboard.storyboard")
        set(ASSETS_FOLDER "${CMAKE_SOURCE_DIR}/ios/Media.xcassets")

        set_source_files_properties(${app_icon_macos} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
        set_source_files_properties(${ASSETS_FOLDER} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

        set(IOS_FILES
            ios/FilePicker.h
            ios/FilePicker.mm
            ios/ImagePicker.h
            ios/ImagePicker.mm
        )
        set(IOS_LIBS "-framework CoreLocation -framework Foundation -framework UIKit -framework LocalAuthentication")
    endif()
endif()

include("${CMAKE_SOURCE_DIR}/CMAKE/Functions.cmake")
include("${CMAKE_SOURCE_DIR}/CMAKE/Qml.cmake")
include("${CMAKE_SOURCE_DIR}/CMAKE/Deploy.cmake")

# Define source files
set(BASE_SOURCES
    SRC/Helper.h
    SRC/HelperMacOs.h
    SRC/helper_linux.cpp
    SRC/helper_linux.h
    SRC/file_downloader.h
    SRC/updater.h
    SRC/updater.cpp
    extrachain_version.h
    SRC/consolecommandprocessor.h
    SRC/consolecommandprocessor.cpp
    main.cpp
    SRC/ipnetwork.h
    SRC/ipnetwork.cpp
)

if (ANDROID)
    set(ANDROID_FILES
        SRC/platforms/android/singboxcontroller.h
        SRC/platforms/android/singboxcontroller.cpp)
endif()

set(GUI_SOURCES
    SRC/Model/wallet_new/WalletUIController.cpp
    SRC/Model/wallet_new/WalletUIController.h
    SRC/Model/DfsFileFilter.cpp
    SRC/Model/DfsFileFilter.h
    SRC/Model/DfsModel.cpp
    SRC/Model/DfsModel.h
    SRC/Model/MessengerController.h
    SRC/Model/MessengerController.cpp
    SRC/Model/NotificationController.h
    SRC/ClientController.cpp
    SRC/ClientController.h
    SRC/etutils.cpp
    SRC/etutils.h
    SRC/profile.cpp
    SRC/profile.h
    SRC/profiledata.cpp
    SRC/profiledata.h
    SRC/ExtraChainController.cpp
    SRC/ExtraChainController.h
    SRC/ShareUtils.cpp
    SRC/ShareUtils.hpp
    SRC/keychainclass.cpp
    SRC/keychainclass.h
    SRC/platforms/android/androidutils.h
    SRC/platforms/android/androidutils.cpp
    SRC/statusbarhelper.cpp
    SRC/statusbarhelper.h

    ${ANDROID_FILES}
)

if(APPLE)
    set(MACOS_SOURCES
        SRC/MacOs/MacosUtils.h
        SRC/MacOs/MacosUtils.mm
    )
    if(CMAKE_GENERATOR STREQUAL "Xcode")
        add_compile_definitions(USE_SWIFT)
        set(MACOS_SOURCES ${MACOS_SOURCES}
            SRC/MacOs/swift_connector.swift
        )
    endif()
endif()

# Resources setup
if(NOT EXTRACHAIN_CONSOLE)
    qt6_add_resources(RESOURCES Resource.qrc)
endif()


# ExtraChain setup
set(EXTRACHAIN_STATIC_BUILD true)
add_compile_definitions(IS_R)
include(${EXTRACHAIN_CORE}/CMakeLists.txt)

# Main executable
if(NOT EXTRACHAIN_CONSOLE)
    qt_add_executable(${PROJECT_NAME} WIN32
        MACOSX_BUNDLE
        ${GUI_SOURCES}
        ${MACOS_SOURCES}
        ${BASE_SOURCES}
        ${RESOURCES}
        ${IOS_FILES}
    )
else()
    qt_add_executable(${PROJECT_NAME}
        ${BASE_SOURCES}
    )
endif()

# QML module setup
if(NOT EXTRACHAIN_CONSOLE)
    add_compile_definitions(IS_RC)
    if(WIN32)
        set(QML_SCAN_OPTION NO_IMPORT_SCAN)
    else()
        set(QML_SCAN_OPTION "")
    endif()
    qt_add_qml_module(${PROJECT_NAME}
        URI App
        QML_FILES
        Main.qml
        # RESOURCES
        UI/Colors.qml
        UI/MessageWindow.qml
        ${UI_PAGES}
        ${UI_ADDITIONAL_COMPONENTS}
        ${UI_CONTROLS}
        ${UI_FONTS}
        ${PAGES}
        ${TEXT_COMPONENTS}
        ${POPUPS}
        ${CONTROL_COMPONENTS}
        ${DELEGATE_COMPONENTS}
        ${OTHER_UI_ELEMENTS}
        ${UI_WALLET_PAGES}
        ${UI_WALLET_CREATE}

        NO_RESOURCE_TARGET_PATH
        RESOURCES android/AndroidManifest.xml android/build.gradle android/res/values/libs.xml android/res/xml/qtprovider_paths.xml
        ${QML_SCAN_OPTION}
    )
endif()

set(TRANSLATION_SOURCES
      Main.qml
      UI/Colors.qml
      UI/MessageWindow.qml
      ${UI_PAGES}
      ${UI_ADDITIONAL_COMPONENTS}
      ${UI_CONTROLS}
      ${UI_FONTS}
      ${PAGES}
      ${TEXT_COMPONENTS}
      ${POPUPS}
      ${CONTROL_COMPONENTS}
      ${DELEGATE_COMPONENTS}
      ${OTHER_UI_ELEMENTS}
      ${UI_WALLET_PAGES}
      ${UI_WALLET_CREATE}
  )

qt_add_translations(${PROJECT_NAME}
  TS_FILES
      translations/${PROJECT_NAME}_uk.ts
      translations/${PROJECT_NAME}_ru.ts
  SOURCES
      Main.qml
      UI/Colors.qml
      UI/MessageWindow.qml
      ${TRANSLATION_SOURCES}
  LUPDATE_OPTIONS -no-obsolete
  LRELEASE_OPTIONS -compress
  QM_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/translations
)

if(TARGET ${PROJECT_NAME}_lupdate)
    set_property(TARGET ${PROJECT_NAME}_lupdate PROPERTY FOLDER "Translations")
endif()

if(TARGET ${PROJECT_NAME}_lrelease)
    set_property(TARGET ${PROJECT_NAME}_lrelease PROPERTY FOLDER "Translations")
endif()

set_property(TARGET ${PROJECT_NAME} PROPERTY QT_EXCLUDE_SOURCES_FROM_TRANSLATION
    "${CMAKE_SOURCE_DIR}/../extrachain-3rdparty"
    "${CMAKE_SOURCE_DIR}/build"
)

target_include_directories(${PROJECT_NAME} PUBLIC ${EXTRACHAIN_CORE_INCLUDES})
target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../extrachain-3rdparty/BlurhashQt/src)

if(WIN32)
    set(APP_ICON_RESOURCE_WINDOWS "${CMAKE_CURRENT_SOURCE_DIR}/UI/Images/windows_icon.rc")
    target_sources(${PROJECT_NAME} PRIVATE ${APP_ICON_RESOURCE_WINDOWS})
    set(PLATFORM_LINK ntdll Iphlpapi Crypt32 ws2_32 bcrypt)
elseif(APPLE)
    set_source_files_properties(${STORYBOARD_FILE} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
    set_target_properties(ExtrachainUI PROPERTIES
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1"
    )

    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE_GUI_IDENTIFIER com.extrachainui.ui
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/ios/Info.plist
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        XCODE_ATTRIBUTE_UILaunchStoryboardName "Storyboard"
    )

    set(MACOSX_BUNDLE_ICON_FILE extrachain.icns)
    set_source_files_properties(${CMAKE_SOURCE_DIR}/extrachain.icns PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
    target_sources(ExtrachainUI PRIVATE ${STORYBOARD_FILE} ${ASSETS_FOLDER} ${CMAKE_SOURCE_DIR}/extrachain.icns)

    target_link_libraries(${PROJECT_NAME} PRIVATE ${IOS_LIBS})

    if(CMAKE_BUILD_TYPE STREQUAL "Release" AND NOT (CMAKE_SYSTEM_NAME STREQUAL "iOS") AND NOT CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
        set(SPARKLE_PATH "/opt/homebrew/Caskroom/sparkle/2.6.4/Sparkle.framework")

        set(CMAKE_FRAMEWORK_PATH ${CMAKE_FRAMEWORK_PATH} ${SPARKLE_PATH})
        set(CMAKE_OSX_FRAMEWORK_PATH ${CMAKE_OSX_FRAMEWORK_PATH} ${SPARKLE_PATH})

        target_compile_options(${PROJECT_NAME} PRIVATE
            "-iframework${SPARKLE_PATH}/Headers"
        )

        include_directories(SRC)

        target_link_libraries(${PROJECT_NAME} PRIVATE
            "-F ${SPARKLE_PATH}/.."
            "-framework Sparkle"
        )

        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/../Frameworks"
        )
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND cp -R -P  # -P -- save symlinks
            "${SPARKLE_PATH}"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/../Frameworks/"
        )

        set_target_properties(${PROJECT_NAME} PROPERTIES
            INSTALL_RPATH "@executable_path/../Frameworks;${Qt6_DIR}/../../../lib;"
            BUILD_WITH_INSTALL_RPATH TRUE
        )
    endif()

    set_property(GLOBAL PROPERTY XCODE_EMIT_EFFECTIVE_PLATFORM_NAME ON)
elseif(UNIX AND NOT APPLE)
    # find_package(Boost 1.86 REQUIRED COMPONENTS
    #     stacktrace_basic
    #     stacktrace_backtrace
    #     stacktrace_addr2line
    #     stacktrace_noop
    # )

    if(ANDROID)
        set(PLATFORM_LINK dl)
        set_target_properties(${PROJECT_NAME} PROPERTIES
            QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android
        )
    else()
        set(PLATFORM_LINK dl pthread)
    endif()
endif()

# Additional compiler definitions and linking
target_compile_definitions(${PROJECT_NAME} PRIVATE
    CMAKE_GENERATOR="${CMAKE_GENERATOR}"
)
if(USE_QZXING)
    target_compile_definitions(${PROJECT_NAME} PRIVATE USE_QZXING=1)
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Network
    ${EXTRACHAIN_CORE_LINK}
    ${PLATFORM_LINK}
    extrachain
)

if(NOT EXTRACHAIN_CONSOLE)
    if(APPLE)
        target_link_libraries(${PROJECT_NAME} PRIVATE
            Qt6::Network
            Qt6::Concurrent
            Qt6::Svg
            Qt6::Quick
            Qt6::QuickControls2
            Qt6::GuiPrivate
            Qt6::Core5Compat
            Qt6::WebSockets
            Qt6::LabsQmlModels
            qt6keychain
            blurhash-qt
        )

        if(USE_QZXING)
            target_link_libraries(${PROJECT_NAME} PRIVATE qzxing)
        endif()
    else()
        target_link_libraries(${PROJECT_NAME} PRIVATE
            Qt6::Concurrent
            Qt6::Gui
            Qt6::Quick
            Qt6::QuickControls2
            Qt6::Core5Compat
            Qt6::Svg
            qt6keychain
            blurhash-qt
        )

        if(USE_QZXING)
            target_link_libraries(${PROJECT_NAME} PRIVATE qzxing)
        endif()
    endif()
endif()

# Installation
include(GNUInstallDirs)
install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if (ANDROID)
    include(${ANDROID_SDK_ROOT}/android_openssl/CMakeLists.txt)
    set_property(TARGET ${PROJECT_NAME} PROPERTY QT_ANDROID_EXTRA_LIBS ${ANDROID_EXTRA_LIBS})

    # Find the libbox.so file and copy it to the right location
    find_library(LIBBOX_LIBRARY
        NAMES box
        PATHS ${CMAKE_CURRENT_SOURCE_DIR}/android/libs/${ANDROID_ABI}
        NO_DEFAULT_PATH
    )

    if(LIBBOX_LIBRARY)
        message(STATUS "Found libbox at: ${LIBBOX_LIBRARY}")
        target_link_libraries(appTestAndroidSing PRIVATE ${LIBBOX_LIBRARY})
    else()
        message(WARNING "libbox.so not found in android/libs/${ANDROID_ABI}/")
    endif()
endif()

