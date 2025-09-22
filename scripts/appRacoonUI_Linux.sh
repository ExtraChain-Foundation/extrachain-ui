#!/bin/bash

BIN_PATH="./appRacoonUI"
if [ ! -f "$BIN_PATH" ]; then
  echo "Error: $BIN_PATH not found."
  exit 1
fi

chmod a+x $BIN_PATH
sudo LD_LIBRARY_PATH=$(pwd)/lib $BIN_PATH "$@"