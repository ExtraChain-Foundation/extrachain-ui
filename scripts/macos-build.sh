#!/bin/bash

# Шляхи
QT_PATH="$HOME/Qt/6.9.2/macos"
VCPKG_PATH="$HOME/ExC/vcpkg"

# Перевіряємо шляхи
if [ ! -d "$QT_PATH" ]; then
    echo "Помилка: Qt не знайдено в $QT_PATH"
    exit 1
fi

if [ ! -d "$VCPKG_PATH" ]; then
    echo "Помилка: vcpkg не знайдено в $VCPKG_PATH"
    exit 1
fi

# Створюємо директорію для збірки
cd ../
BUILD_DIR="build_release"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Отримуємо кількість ядер мінус 1
NCPU=$(($(sysctl -n hw.ncpu) - 1))

# Конфігуруємо проект
cmake -DCMAKE_PREFIX_PATH="$QT_PATH/lib/cmake" \
      -DCMAKE_TOOLCHAIN_FILE="$VCPKG_PATH/scripts/buildsystems/vcpkg.cmake" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_OSX_ARCHITECTURES:STRING="arm64;x86_64" \
      -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
      -DCMAKE_CXX_FLAGS="-O3 -flto=thin" \
      -DCMAKE_EXE_LINKER_FLAGS="-flto=thin" \
      -DVCPKG_TARGET_TRIPLET:STRING=arm64-osx \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
      -DCMAKE_OSX_SYSROOT=$(xcrun --show-sdk-path) \
      ..

# Збираємо проект
make -j$NCPU

if [ $? -eq 0 ]; then
    echo "Збірка успішно завершена!"
else
    echo "Помилка при збірці!"
    exit 1
fi

cp ../scripts/macos-prepare.sh macos-prepare.sh
