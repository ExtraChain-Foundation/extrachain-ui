#!/bin/bash

# Define paths
APP_PATH="RaccoonLine.app"
FRAMEWORKS_PATH="$CODESIGNING_FOLDER_PATH/Contents/Frameworks"
LIBS_SOURCE_PATH="$HOME/ExC/extrachain-3rdparty/ExtraChain_macOS_dylib"

$HOME/Qt/6.8.1/macos/bin/macdeployqt $CODESIGNING_FOLDER_PATH -qmldir=$HOME/ExC/raccoon-ui/UI
if [ $? -ne 0 ]; then
    echo "Error: macdeployqt failed."
    exit 1
fi

mkdir -p $FRAMEWORKS_PATH
cp $LIBS_SOURCE_PATH/*.dylib $FRAMEWORKS_PATH
if [ $? -ne 0 ]; then
    echo "Error: Copying libraries failed."
fi
echo "All steps completed successfully"
exit 0

