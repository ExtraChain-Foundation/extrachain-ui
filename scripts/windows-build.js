#!/usr/bin/env node

const { execSync } = require('child_process');
const { existsSync, mkdirSync, readdirSync, copyFileSync } = require('fs');
const { join, resolve } = require('path');
const process = require('process');
const readline = require('readline');

function runCommand(command, errorMessage) {
    try {
        execSync(command, { stdio: 'inherit', shell: 'cmd' });
    } catch (error) {
        console.error('\x1b[31m%s\x1b[0m', `❌ ПОМИЛКА: ${errorMessage}`);
        console.error(error.message);
        process.exit(1);
    }
}

function findInnoSetup() {
    const possiblePaths = [
        'C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe',
        'C:\\Program Files\\Inno Setup 6\\ISCC.exe',
        process.env.ProgramFiles + '\\Inno Setup 6\\ISCC.exe',
        process.env['ProgramFiles(x86)'] + '\\Inno Setup 6\\ISCC.exe'
    ];

    for (const path of possiblePaths) {
        if (existsSync(path)) {
            return path;
        }
    }
    return null;
}

function findVcvarsall() {
    const possiblePaths = [
        'C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\VC\\Auxiliary\\Build\\vcvarsall.bat',
        'C:\\Program Files\\Microsoft Visual Studio\\2022\\Professional\\VC\\Auxiliary\\Build\\vcvarsall.bat',
        'C:\\Program Files\\Microsoft Visual Studio\\2022\\Enterprise\\VC\\Auxiliary\\Build\\vcvarsall.bat',
        'C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsall.bat',
        'C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\Community\\VC\\Auxiliary\\Build\\vcvarsall.bat',
        'C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\Professional\\VC\\Auxiliary\\Build\\vcvarsall.bat',
        'C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\Enterprise\\VC\\Auxiliary\\Build\\vcvarsall.bat',
        'C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsall.bat'
    ];

    for (const path of possiblePaths) {
        if (existsSync(path)) {
            return path;
        }
    }
    return null;
}

function setupMSVCEnvironment() {
    // Перевірка, чи вже налаштовано середовище MSVC
    try {
        execSync('cl', { stdio: 'ignore' });
        // Якщо cl.exe доступний, перевіряємо архітектуру
        if (process.env.VSCMD_ARG_TGT_ARCH === 'x64' || process.env.Platform === 'x64') {
            console.log('\x1b[36m%s\x1b[0m', '✅ MSVC x64 середовище вже налаштовано');
            return null;
        }
    } catch (error) {
        // cl.exe не знайдено, потрібно налаштувати середовище
    }

    const vcvarsallPath = findVcvarsall();
    if (!vcvarsallPath) {
        console.error('\x1b[31m%s\x1b[0m', '❌ ПОМИЛКА: Visual Studio 2022 не знайдено в системі');
        process.exit(1);
    }

    console.log('\x1b[36m%s\x1b[0m', '🔧 Налаштування середовища MSVC x64...');
    
    // Повертаємо шлях до vcvarsall.bat для використання в командах
    return vcvarsallPath;
}

function runCommandWithVcvars(command, vcvarsallPath, errorMessage) {
    try {
        let fullCommand = command;
        if (vcvarsallPath) {
            // Якщо потрібно налаштувати середовище, виконуємо vcvarsall.bat перед командою
            fullCommand = `"${vcvarsallPath}" x64 && ${command}`;
        }
        execSync(fullCommand, { stdio: 'inherit', shell: 'cmd' });
    } catch (error) {
        console.error('\x1b[31m%s\x1b[0m', `❌ ПОМИЛКА: ${errorMessage}`);
        console.error(error.message);
        process.exit(1);
    }
}

function checkTools() {
    try {
        execSync('cmake --version', { stdio: 'ignore' });
    } catch (error) {
        console.error('\x1b[31m%s\x1b[0m', '❌ ПОМИЛКА: CMake не знайдено в системі');
        process.exit(1);
    }

    // Перевірка Ninja
    try {
        execSync('ninja --version', { stdio: 'ignore' });
    } catch (error) {
        console.error('\x1b[31m%s\x1b[0m', '❌ ПОМИЛКА: Ninja не знайдено в системі');
        console.error('\x1b[33m%s\x1b[0m', '💡 Підказка: Встановіть Ninja через vcpkg або завантажте з https://github.com/ninja-build/ninja/releases');
        process.exit(1);
    }

    const innoSetupPath = findInnoSetup();
    if (!innoSetupPath) {
        console.error('\x1b[31m%s\x1b[0m', '❌ ПОМИЛКА: Inno Setup не знайдено в системі.\nБудь ласка, встановіть Inno Setup 6: https://jrsoftware.org/isdl.php');
        process.exit(1);
    }
    return innoSetupPath;
}

function findQtInstallations() {
    const possibleQtPaths = [
        'C:\\Qt',
        process.env.QTDIR ? process.env.QTDIR : null,
        process.env.Qt6_DIR ? process.env.Qt6_DIR : null,
        process.env.Qt5_DIR ? process.env.Qt5_DIR : null
    ].filter(Boolean);

    let qtVersions = [];

    for (const basePath of possibleQtPaths) {
        if (existsSync(basePath)) {
            try {
                const items = readdirSync(basePath);
                for (const item of items) {
                    if (/^[56]\.\d+\.\d+/.test(item)) {
                        const msvcDirs = readdirSync(join(basePath, item))
                            .filter(dir => dir.toLowerCase().includes('msvc'));
                        
                        if (msvcDirs.length > 0) {
                            qtVersions.push({
                                version: item,
                                path: join(basePath, item, msvcDirs[0]),
                                fullPath: basePath
                            });
                        }
                    }
                }
            } catch (error) {
                console.warn(`⚠️ Пропуск директорії ${basePath}: ${error.message}`);
            }
        }
    }

    return qtVersions;
}

async function selectQtVersion(versions) {
    if (versions.length === 0) {
        console.error('\x1b[31m%s\x1b[0m', '❌ ПОМИЛКА: Qt не знайдено в системі');
        process.exit(1);
    }

    if (versions.length === 1) {
        console.log('\x1b[36m%s\x1b[0m', `🔍 Знайдена версія Qt: ${versions[0].version}`);
        return versions[0];
    }

    console.log('\x1b[36m%s\x1b[0m', '📋 Доступні версії Qt:');
    versions.forEach((qt, index) => {
        console.log(`${index + 1}. Qt ${qt.version} (${qt.path})`);
    });

    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    return new Promise((resolve) => {
        rl.question('🔍 Оберіть номер версії Qt: ', (answer) => {
            rl.close();
            const index = parseInt(answer) - 1;
            if (index >= 0 && index < versions.length) {
                resolve(versions[index]);
            } else {
                console.error('\x1b[31m%s\x1b[0m', '❌ ПОМИЛКА: Невірний вибір');
                process.exit(1);
            }
        });
    });
}

function openOutputFolder(buildDir) {
    const outputDir = join(buildDir, 'Output');
    if (existsSync(outputDir)) {
        console.log('\x1b[36m%s\x1b[0m', '📂 Відкриття папки з інсталятором...');
        try {
            execSync(`explorer "${outputDir}"`, { stdio: 'ignore' });
        } catch (error) {
            console.warn('\x1b[33m%s\x1b[0m', `⚠️ Не вдалося відкрити папку Output: ${error.message}`);
            console.log('\x1b[36m%s\x1b[0m', `📁 Інсталятор знаходиться в: ${outputDir}`);
        }
    } else {
        console.warn('\x1b[33m%s\x1b[0m', '⚠️ Папка Output не знайдена');
    }
}

async function main() {
    console.log('\x1b[36m%s\x1b[0m', '🔍 Перевірка інструментів...');
    
    // Налаштування середовища MSVC
    const vcvarsallPath = setupMSVCEnvironment();
    
    const innoSetupPath = checkTools();

    const qtVersions = findQtInstallations();
    const selectedQt = await selectQtVersion(qtVersions);
    
    process.env.CMAKE_PREFIX_PATH = selectedQt.path;
    console.log('\x1b[36m%s\x1b[0m', `🚀 Використовується Qt ${selectedQt.version}`);

    process.chdir('..');
    const projectDir = process.cwd();
    
    // Функція для знаходження доступного імені для старої папки
    function findAvailableOldDirName(baseDir, baseName) {
        let counter = '';
        let newName = `${baseName}-old${counter}`;
        
        while (existsSync(join(baseDir, newName))) {
            counter = counter === '' ? ' 1' : ` ${parseInt(counter) + 1}`;
            newName = `${baseName}-old${counter}`;
        }
        
        return newName;
    }

    const buildDir = join(projectDir, 'build_release');
    if (existsSync(buildDir)) {
        const oldDirName = findAvailableOldDirName(projectDir, 'build_release');
        console.log('\x1b[36m%s\x1b[0m', `📁 Перейменування старої директорії build_release в ${oldDirName}...`);
        try {
            const oldPath = join(projectDir, oldDirName);
            execSync(`move "${buildDir}" "${oldPath}"`, { stdio: 'ignore' });
        } catch (error) {
            console.error('\x1b[31m%s\x1b[0m', `❌ ПОМИЛКА: Не вдалося перейменувати стару директорію: ${error.message}`);
            process.exit(1);
        }
    }

    console.log('\x1b[36m%s\x1b[0m', '📁 Створення нової директорії build_release...');
    mkdirSync(buildDir);

    process.chdir(buildDir);

    const vcpkgToolchain = resolve(projectDir, '../vcpkg/scripts/buildsystems/vcpkg.cmake');
    
    if (!existsSync(vcpkgToolchain)) {
        console.error('\x1b[31m%s\x1b[0m', `❌ ПОМИЛКА: Не знайдено файл vcpkg toolchain: ${vcpkgToolchain}`);
        process.exit(1);
    }

    console.log('\x1b[33m%s\x1b[0m', '⚙️ Конфігурація проєкту...');
    const cmakeCommand = [
        'cmake ..',
        '-G "Ninja"',
        '-DCMAKE_BUILD_TYPE=Release',
        '-DCMAKE_C_COMPILER=cl',
        '-DCMAKE_CXX_COMPILER=cl',
        '-DVCPKG_TARGET_TRIPLET=x64-windows',
        `-DCMAKE_PREFIX_PATH="${selectedQt.path}"`,
        `-DCMAKE_TOOLCHAIN_FILE="${vcpkgToolchain}"`
    ].join(' ');

    runCommandWithVcvars(cmakeCommand, vcvarsallPath, 'Помилка при конфігурації проєкту');

    console.log('\x1b[33m%s\x1b[0m', '🔨 Збірка проєкту...');
    runCommandWithVcvars('cmake --build . --config Release', vcvarsallPath, 'Помилка при збірці проєкту');

    // Запуск windeployqt
    console.log('\x1b[33m%s\x1b[0m', '📦 Копіювання залежностей Qt...');
    const windeployqt = join(selectedQt.fullPath, selectedQt.version, 'msvc2022_64', 'bin', 'windeployqt.exe');
    const qmldir = join(projectDir, 'UI');
    runCommand(`"${windeployqt}" --qmldir "${qmldir}" RaccoonLine.exe`, 'Помилка при копіюванні залежностей Qt');

/*
    // Копіювання VC++ Redistributable
    console.log('\x1b[33m%s\x1b[0m', '📦 Копіювання VC++ Redistributable...');
    const vcRedistSrc = join(projectDir, '..', 'VC_redist.x64.exe');
    const vcRedistDest = join(buildDir, 'VC_redist.x64.exe');
    
    try {
        copyFileSync(vcRedistSrc, vcRedistDest);
    } catch (error) {
        console.error('\x1b[31m%s\x1b[0m', `❌ ПОМИЛКА: Не вдалося скопіювати VC_redist.x64.exe: ${error.message}`);
        process.exit(1);
    }
*/

    // Копіювання та запуск Inno Setup скрипта
    console.log('\x1b[33m%s\x1b[0m', '📝 Створення інсталятора...');
    const innoScript = join(projectDir, 'scripts', 'windows-inno.iss');
    const innoScriptDest = join(buildDir, 'windows-inno.iss');
    
    try {
        copyFileSync(innoScript, innoScriptDest);
    } catch (error) {
        console.error('\x1b[31m%s\x1b[0m', `❌ ПОМИЛКА: Не вдалося скопіювати Inno Setup скрипт: ${error.message}`);
        process.exit(1);
    }

    runCommand(`"${innoSetupPath}" "${innoScriptDest}"`, 'Помилка при створенні інсталятора');

    console.log('\x1b[32m%s\x1b[0m', '✅ Збірка та створення інсталятора успішно завершені!');
    
    // Відкриття папки з інсталятором
    openOutputFolder(buildDir);
}

main();