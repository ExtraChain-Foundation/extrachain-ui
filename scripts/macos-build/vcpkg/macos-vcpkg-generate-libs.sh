#!/bin/bash

VCPKG_ROOT="$HOME/ExC/vcpkg"
ARM_LIB_DIR="$VCPKG_ROOT/installed/arm64-osx/lib"
X86_LIB_DIR="$VCPKG_ROOT/installed/x64-osx/lib"
BACKUP_DIR="$ARM_LIB_DIR/backup_arm"

# Проверяем существование директорий
if [ ! -d "$ARM_LIB_DIR" ]; then
    echo "Error: ARM lib directory not found: $ARM_LIB_DIR"
    exit 1
fi

if [ ! -d "$X86_LIB_DIR" ]; then
    echo "Error: x86 lib directory not found: $X86_LIB_DIR"
    exit 1
fi

# Создаем бэкап если его еще нет
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
    # Копируем только существующие файлы
    find "$ARM_LIB_DIR" -maxdepth 1 \( -name "*.a" -o -name "*.dylib" \) -exec cp {} "$BACKUP_DIR/" \; 2>/dev/null
fi

# Обрабатываем .a файлы
for arm_file in "$ARM_LIB_DIR"/*.a; do
    [ -e "$arm_file" ] || continue
    
    filename=$(basename "$arm_file")
    x86_file="$X86_LIB_DIR/$filename"
    
    if [ -f "$x86_file" ]; then
        echo "Processing: $filename"
        
        # Проверяем архитектуры перед объединением
        echo "  ARM file architectures: $(lipo -info "$arm_file" 2>/dev/null || echo "unknown")"
        echo "  x86 file architectures: $(lipo -info "$x86_file" 2>/dev/null || echo "unknown")"
        
        # Создаем universal бинарник
        if lipo -create "$arm_file" "$x86_file" -output "$ARM_LIB_DIR/tmp_$filename"; then
            mv "$ARM_LIB_DIR/tmp_$filename" "$arm_file"
            echo "  ✓ Created universal: $filename"
            echo "  Result: $(lipo -info "$arm_file")"
        else
            echo "  ✗ Failed to create universal for: $filename"
            rm -f "$ARM_LIB_DIR/tmp_$filename"
        fi
        echo ""
    else
        echo "Skipping $filename (no x86 version found)"
    fi
done

# Обрабатываем .dylib файлы отдельно
for arm_file in "$ARM_LIB_DIR"/*.dylib; do
    [ -e "$arm_file" ] || continue
    
    filename=$(basename "$arm_file")
    x86_file="$X86_LIB_DIR/$filename"
    
    if [ -f "$x86_file" ]; then
        echo "Processing dylib: $filename"
        
        if lipo -create "$arm_file" "$x86_file" -output "$ARM_LIB_DIR/tmp_$filename"; then
            mv "$ARM_LIB_DIR/tmp_$filename" "$arm_file"
            echo "  ✓ Created universal dylib: $filename"
        else
            echo "  ✗ Failed to create universal dylib for: $filename"
            rm -f "$ARM_LIB_DIR/tmp_$filename"
        fi
    fi
done

echo "Done! Universal binaries created in: $ARM_LIB_DIR"