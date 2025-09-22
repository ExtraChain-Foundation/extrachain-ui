#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse
import os
import re
from pathlib import Path

def update_raccoon_version_h(file_path, new_version):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Обновляем версию в C++ файле
    updated = re.sub(
        r'static const std::string raccoon_version = "[^"]+";',
        f'static const std::string raccoon_version = "{new_version}";',
        content
    )
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(updated)

def update_macos_prepare(file_path, new_version):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Обновляем обе версии в plist
    updated = re.sub(
        r'<key>CFBundleShortVersionString</key>\s*<string>[^<]+</string>',
        f'<key>CFBundleShortVersionString</key>\\n    <string>{new_version}</string>',
        content
    )
    updated = re.sub(
        r'<key>CFBundleVersion</key>\s*<string>[^<]+</string>',
        f'<key>CFBundleVersion</key>\\n    <string>{new_version}</string>',
        updated
    )
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(updated)

def update_windows_inno(file_path, new_version):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Обновляем версию в Inno Setup скрипте
    updated = re.sub(
        r'#define MyAppVersion "[^"]+"',
        f'#define MyAppVersion "{new_version}"',
        content
    )
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(updated)

def update_android_manifest(file_path, new_version):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Обновляем versionName в Android манифесте
    updated = re.sub(
        r'android:versionName="[^"]+"',
        f'android:versionName="{new_version}"',
        content
    )
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(updated)

def update_cmake_lists(file_path, new_version):
    # Разбиваем версию на компоненты (например, "0.3.6.1" -> ["0", "3", "6", "1"])
    version_parts = new_version.split('.')
    
    # Убедимся, что у нас есть все компоненты (минимум 3, максимум 4)
    while len(version_parts) < 3:
        version_parts.append('0')
    
    major, minor, patch = version_parts[0], version_parts[1], version_parts[2]
    tweak = version_parts[3] if len(version_parts) > 3 else None
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Обновляем каждую часть версии
    updated = re.sub(
        r'set\(PROJECT_VERSION_MAJOR \d+\)',
        f'set(PROJECT_VERSION_MAJOR {major})',
        content
    )
    updated = re.sub(
        r'set\(PROJECT_VERSION_MINOR \d+\)',
        f'set(PROJECT_VERSION_MINOR {minor})',
        updated
    )
    updated = re.sub(
        r'set\(PROJECT_VERSION_PATCH \d+\)',
        f'set(PROJECT_VERSION_PATCH {patch})',
        updated
    )
    
    # Обрабатываем TWEAK компонент
    if tweak is not None:
        # Если TWEAK есть в версии, обновляем существующий или добавляем новый
        if re.search(r'set\(PROJECT_VERSION_TWEAK \d+\)', content):
            # Обновляем существующий TWEAK
            updated = re.sub(
                r'set\(PROJECT_VERSION_TWEAK \d+\)',
                f'set(PROJECT_VERSION_TWEAK {tweak})',
                updated
            )
        else:
            # Добавляем новый TWEAK после PATCH
            updated = re.sub(
                r'(set\(PROJECT_VERSION_PATCH \d+\))',
                f'\\1\nset(PROJECT_VERSION_TWEAK {tweak})',
                updated
            )
        
        # Обновляем строку PROJECT_VERSION чтобы включить TWEAK
        if '${PROJECT_VERSION_TWEAK}' not in updated:
            updated = re.sub(
                r'set\(PROJECT_VERSION "\$\{PROJECT_VERSION_MAJOR\}\.\$\{PROJECT_VERSION_MINOR\}\.\$\{PROJECT_VERSION_PATCH\}"\)',
                'set(PROJECT_VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}.${PROJECT_VERSION_TWEAK}")',
                updated
            )
    else:
        # Если TWEAK нет в новой версии, удаляем его из CMakeLists.txt
        updated = re.sub(r'set\(PROJECT_VERSION_TWEAK \d+\)\n?', '', updated)
        
        # Убираем TWEAK из строки PROJECT_VERSION
        updated = re.sub(
            r'set\(PROJECT_VERSION "\$\{PROJECT_VERSION_MAJOR\}\.\$\{PROJECT_VERSION_MINOR\}\.\$\{PROJECT_VERSION_PATCH\}\.\$\{PROJECT_VERSION_TWEAK\}"\)',
            'set(PROJECT_VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")',
            updated
        )
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(updated)

def main():
    parser = argparse.ArgumentParser(description=u'Оновлення версії у файлах проекту')
    parser.add_argument('new_version', help='New version number (e.g., 0.2.3 or 0.2.3.1)')
    parser.add_argument('--project-root', default='..',
                       help='Path to project root directory (default: parent directory)')
    
    args = parser.parse_args()
    
    # Проверяем формат версии
    version_pattern = r'^\d+\.\d+\.\d+(\.\d+)?$'
    if not re.match(version_pattern, args.new_version):
        print(u'❌ Ошибка: неверный формат версии. Используйте формат MAJOR.MINOR.PATCH или MAJOR.MINOR.PATCH.TWEAK')
        return 1
    
    # Получаем абсолютный путь к корню проекта
    project_root = Path(args.project_root).resolve()
    
    # Определяем пути к файлам
    files_to_update = {
        'raccoon_version.h': update_raccoon_version_h,
        os.path.join('scripts', 'macos-prepare.sh'): update_macos_prepare,
        os.path.join('scripts', 'windows-inno.iss'): update_windows_inno,
        os.path.join('scripts', 'windows-inno-messenger.iss'): update_windows_inno,
        os.path.join('android', 'AndroidManifest.xml'): update_android_manifest,
        'CMakeLists.txt': update_cmake_lists
    }
    
    print(f'🚀 Обновляю версию на {args.new_version}...')
    
    # Обновляем каждый файл
    for rel_path, update_func in files_to_update.items():
        file_path = project_root / rel_path
        if file_path.exists():
            print(u'📝 Оновлюю {}...'.format(rel_path))
            update_func(file_path, args.new_version)
            print(u'✅ Успішно оновлено {}'.format(rel_path))
        else:
            print(u'⚠️  Увага: файл {} не знайдено'.format(rel_path))
    
    print(f'🎉 Версия успешно обновлена на {args.new_version}!')

if __name__ == '__main__':
    main()