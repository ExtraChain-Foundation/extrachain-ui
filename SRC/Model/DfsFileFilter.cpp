#include "DfsFileFilter.h"
#include "managers/token_manager.h"
#include <QDesktopServices>
#include <QtCore/qdiriterator.h>

DfsFileFilterModel::DfsFileFilterModel(ExtraChainNode *node, bool filterDir, VariantModel *parent)
    : VariantModel(parent)
    , node(node)
    , _filterDir(filterDir)
    , _maxSpace(max_space_in_gb) {
    setModelRoles(
        { "isDir", "name", "fileId", "size", "progress", "path", "type", "base64", "encrypted", "created" });
    showMain();

    if (node->dfs()) {
        QObject::connect(node->dfs(), &DfsController::added, this, &DfsFileFilterModel::addFile);
        QObject::connect(node->dfs(), &DfsController::uploaded, [this](ActorId owner_id, Dfs::DirRow dirRow) {
            this->updateFileProgress(dirRow.actor_id, dirRow.file_id, 100);
        });
        QObject::connect(node->dfs(),
                         &DfsController::downloaded,
                         [this, &node](ActorId owner_id, Dfs::DirRow dirRow) {
                             this->updateFileProgress(dirRow.actor_id, dirRow.file_id, 100);
                             // eLog("File {} {}  downloaded", dirRow.actor_id, dirRow.file_id);
                             auto pathtoFile = fmt::format("dfs/{}/{}", dirRow.actor_id, dirRow.file_id);
                         });
        QObject::connect(node->dfs(),
                         &DfsController::uploadProgress,
                         this,
                         &DfsFileFilterModel::updateFileProgress);
        QObject::connect(node->dfs(),
                         &DfsController::downloadProgress,
                         this,
                         &DfsFileFilterModel::updateFileProgress);
    }
}

void DfsFileFilterModel::showMain() {
    _inFolder = false;
    clear();
    mainDir();
}

void DfsFileFilterModel::jumpToFolder(const QString &folder) {
    clear();
    currentDir     = folder.toStdString();
    m_currentActor = folder;
    emit currentActorChanged();

    eLog("Current dir: {}", currentDir);
    auto dirRows = Dfs::Tables::ActorDirFile::get_dir_rows(ActorId(currentDir));
    if (!dirRows.has_value())
        return;

    if (_filterDir) {
        append(toMap(DfsModelDirType::Folder, ".", "", 0, 100));
    }

    if (!_filterDir) {
        for (auto &dirRow : dirRows.value()) {
            if (dirRow.state != Dfs::FileState::Ready) {
                continue;
            }

            if (dirRow.folder.has_value() && !dirRow.folder->empty() && dirRow.folder->at(0) == ':') {
                continue;
            }

            int progress;
            try {
                progress = std::filesystem::file_size(Dfs::Path::filePath(ActorId(currentDir), dirRow.file_id))
                                   == dirRow.size
                               ? 100
                               : 0;
            } catch (std::exception &e) {
                progress = 0;
            }

            auto name = dirRow.name;

            if (dirRow.encryption) {
                auto actor          = node->accountController()->currentProfile().get_actor(ActorId(currentDir));
                auto encrypted_name = Utils::from_base64(name);
                if (actor.has_value() && encrypted_name.has_value()) {
                    auto res = actor->get().key().decrypt_self(ByteArray(encrypted_name.value()).toBytes());
                    if (res.has_value()) {
                        name = ByteArray(res.value()).toString();
                    }
                }
            }

            append(toMap(DfsModelDirType::File, name, dirRow.file_id, dirRow.size, progress, dirRow.encryption));
        }
    }

    _inFolder = true;
    calcUsedSpace();
}

void DfsFileFilterModel::openFile(const int &index) {
    return;
    QDir().mkpath("tmp/files");

    auto map    = get(index);
    auto fileId = map["fileId"].toString().toStdString();
    auto name   = map["name"].toString();

    auto path =
        QString::fromStdString(Dfs::Path::filePath(ActorId(currentDir), fileId).string()).replace("\\", "/");
    auto tempPath     = "tmp/files/" + name;
    auto fullTempPath = QDir::currentPath() + "/" + tempPath;

    if (!QFile::exists(tempPath) && QFile(path).size() != QFile(tempPath).size()) {
        QFile::copy(path, tempPath);
    }

    QUrl url = QUrl::fromLocalFile(fullTempPath);
    QDesktopServices::openUrl(url);
}

void DfsFileFilterModel::exportFile(const int &index, const QString &exportPath) {
    QDir().mkpath("tmp/files");

    auto map    = get(index);
    auto fileId = map["fileId"].toString().toStdString();
    auto name   = map["name"].toString();

    QString path =
        QString::fromStdString(Dfs::Path::filePath(ActorId(currentDir), fileId).string()).replace("\\", "/");
    QString tempPath       = QString("tmp/files/%1/%2").arg(QString::fromStdString(currentDir)).arg(name);
    QString exportPathFile = QString("%1/%2").arg(exportPath, name);
    QString fullTempPath   = QDir::currentPath() + "/" + tempPath;

    QFile sourceFile(path);
    QFile tempFile(tempPath);

    // if (!tempFile.exists() || sourceFile.size() != tempFile.size()) {
    //     if (sourceFile.copy(tempPath)) {
    //         eLog("Temporary file created at: {}", tempPath);
    //     } else {
    //         eLog("Failed to create temporary file: {}", tempPath);
    //         emit message("Failed export file.");
    //         return;
    //     }
    // }

    if (QFile::exists(exportPathFile)) {
        emit message("The file already exists at the specified path.");
        return;
    }

    // bool copied = QFile::copy(fullTempPath, exportPathFile);
    auto fs_path = FsPath::create(exportPath.toStdString());
    if (!fs_path.has_value()) {
        return;
    }

    auto exported = node->dfs()->export_file(ActorId(currentDir), fileId, fs_path.value());
    bool copied   = exported.has_value();
    emit message(copied ? "File exported" : fmt::format("Failed export file: {}", exported.error()).c_str());
    eLog("Export file to folder: {}. Export path: {}. Result: {}",
         fullTempPath,
         exportPathFile,
         copied ? "saved" : "not saved");
}

QString DfsFileFilterModel::exportData(const int &index) {
    QDir().mkpath("tmp/files");
    auto map    = get(index);
    auto fileId = map["fileId"].toString().toStdString();

    auto dfs_path_result = Dfs::Path::file_path(ActorId(currentDir), fileId);
    if (!dfs_path_result) {
        qDebug() << "Invalid DFS path";
        return "";
    }

    QString tempPath = QString("tmp/files/dfs/%1").arg(QString::fromStdString(currentDir));
    QString pathToFileInTmpFolder =
        QDir::currentPath() + "/" + QDir(tempPath).path() + "/" + map["name"].toString();
    if (!QFile::exists(pathToFileInTmpFolder)) {
#ifdef Q_OS_IOS
        QDir dir;
        if (!dir.exists(tempPath)) {
            if (dir.mkpath(tempPath)) {
                qDebug() << "Directory created successfully:" << tempPath;
            } else {
                qWarning() << "Failed to create directory:" << tempPath;
            }
        } else {
            qDebug() << tempPath << " is exist by hash" << fileId;
        }
#endif
        QString pathToTmpDir = QDir::currentPath() + "/" + QDir(tempPath).path();
        auto    fs_path      = FsPath::create(pathToTmpDir.toStdString());
        node->dfs()->export_file(ActorId(currentDir), fileId, fs_path.value());
    }
    return pathToFileInTmpFolder;
}

void DfsFileFilterModel::addFile(ActorId owner_id, Dfs::DirRow dirRow) {
    if (currentDir.empty()) {
        showMain();
        return;
    }

    if (currentDir != dirRow.actor_id.to_string())
        return;

    if (dirRow.folder.has_value() && !dirRow.folder->empty() && dirRow.folder->at(0) == ':') {
        return;
    }

    jumpToFolder(dirRow.actor_id.toQString());
    emit fileAdded();
    int  progress =
        std::filesystem::file_size(Dfs::Path::filePath(dirRow.actor_id, dirRow.file_id)) == dirRow.size ? 100 : 0;
    calcUsedSpace();
    // append(toMap(DfsModelDirType::File, visual, fileHash, size, progress));
}

void DfsFileFilterModel::updateFileProgress(ActorId actorId, std::string fileName, int progress) {
    if (currentDir != actorId.to_string())
        return;

    QString fileId = QString::fromStdString(fileName);
    for (int i = 0; i != count(); i++) {
        auto map = get(i);
        if (map["fileId"].toString() == fileId) {
            set(i, "progress", progress);
        }
    }
}

void DfsFileFilterModel::refresh(const QString &currentActor) {
    jumpToFolder(currentActor);
}

void DfsFileFilterModel::searchIn(const QString &text) {
    if (_filterDir && _inFolder) {
        // reset model
        //  clear();
        //  for(auto& item : _cacheList) {
        //      append(item);
        //  }
        return;
    }

    auto isValidFileExtensionPattern = [](const QString &pattern) -> bool {
        return QRegularExpression(R"(^\*\.[a-zA-Z0-9]+$)").match(pattern).hasMatch();
    };

    eLog("find in files");
    if (_cacheList.isEmpty())
        _cacheList = list();

    QList<QVariantMap> founded;
    QString            searchText = text.toLower();

    bool    isByExtension = isValidFileExtensionPattern(text);
    QString ext           = isByExtension ? text.mid(1) : QString();

    std::ranges::copy_if(_cacheList, std::back_inserter(founded), [&](const QVariantMap &item) {
        QString nameFile = item["name"].toString().toLower();
        eLog("{}", item);

        return isByExtension ? nameFile.endsWith(ext) : nameFile.contains(searchText);
    });

    clear();
    for (auto &item : founded) {
        append(item);
    }
}

void DfsFileFilterModel::setInFolder(bool inFolder) {
    _inFolder = inFolder;

    if (!inFolder && !_filterDir) {
        clear();
        _cacheList.clear();
    }
}

QVariantMap DfsFileFilterModel::toMap(DfsModelDirType isDir,
                                      std::string     name,
                                      std::string     file_id,
                                      qint64          size,
                                      int             progress,
                                      bool            encrypted,
                                      bool            isImage) {
    auto path =
        QDir::currentPath() + "/"
        + QString::fromStdString(Dfs::Path::filePath(ActorId(currentDir), name).string()).replace("\\", "/");
    auto    url    = QUrl::fromLocalFile(path).toString();
    auto    type   = Utils::fileMimeSuffix(path);
    QString base64 = toBase64(file_id, QString::fromStdString(name), type);

    QFileInfo fi(
        QDir::currentPath() + "/"
        + QString::fromStdString(Dfs::Path::filePath(ActorId(currentDir), file_id).string()).replace("\\", "/"));
    QDateTime created = QDateTime::currentDateTime();
    if (fi.exists()) {
        created = fi.birthTime();
    }
    return { { "isDir", int(isDir) },
             { "name", QString::fromStdString(name) },
             { "fileId", QString::fromStdString(file_id) },
             { "size", size },
             { "progress", progress },
             { "path", path },
             { "type", type },
             { "base64", base64 },
             { "encrypted", encrypted },
             { "created", created.toString("MMM dd, hh:mm") } };
}

QString DfsFileFilterModel::toBase64(const std::string &fileId,
                                     const QString     &nameFile,
                                     const QString     &extension) {
    if (
#ifdef Q_OS_ANDROID
        true ||
#endif
        nameFile == "."
        || (extension != "png" && extension != "jpg" && extension != "jpeg" && extension != "gif")) {
        return "";
    }

    auto path =
        QDir::currentPath() + "/"
        + QString::fromStdString(Dfs::Path::filePath(ActorId(currentDir), fileId).string()).replace("\\", "/");

    QString tempPath           = QString("tmp/files/dfs/%1").arg(QString::fromStdString(currentDir));
    auto    actor_folder       = DfsB::DFS_FOLDER + Utils::platformDelimeter() + ActorId(currentDir).to_string();
    QString pathToTmpExportDir = QDir::currentPath() + "/" + QDir(tempPath).path();

    QDir dir;
    if (!dir.exists(pathToTmpExportDir)) {
        if (dir.mkpath(pathToTmpExportDir)) {
            qDebug() << "Directory created successfully:" << pathToTmpExportDir;
        } else {
            qWarning() << "Failed to create directory:" << pathToTmpExportDir;
        }
    } else {
        qDebug() << pathToTmpExportDir << " is exist" << fileId;
    }

    auto fs_path = FsPath::create(pathToTmpExportDir.toStdString());
    if (!fs_path.has_value()) {
        return "";
    }

    auto actor = ActorId::create(currentDir);
    if (!actor.has_value()) {
        return "";
    }
    auto res            = node->dfs()->export_file(actor.value(), fileId, fs_path.value());
    auto dir_row_result = Dfs::Tables::ActorDirFile::get_dir_row(actor.value(), fileId);

    if (res.has_value() || res.error() == ExportFileError::OutputFileExists) {
        QFile f(pathToTmpExportDir + "/" + dir_row_result->name.c_str());
        if (f.exists()) {
            if (f.open(QIODevice::ReadOnly)) {
                QByteArray data = f.readAll();
                f.close();

                QString mimeType;
                if (extension == "png") {
                    mimeType = "image/png";
                } else if (extension == "jpg" || extension == "jpeg") {
                    mimeType = "image/jpeg";
                } else if (extension == "gif") {
                    mimeType = "image/gif";
                } else {
                    qWarning() << "Unsupported image format:" << extension;
                    return "";
                }

                return QString("data:%1;base64,%2").arg(mimeType, QString::fromLatin1(data.toBase64()));
            } else {
                qWarning() << "Could not open file";
            }
        } else {
            qWarning() << "File does not exist";
        }
    }

    return "";
}

void DfsFileFilterModel::calcUsedSpace() {
    QString folderPath = QString::fromStdString(Dfs::Path::actorPath(ActorId(currentDir)).string());
    QDir    folder(folderPath);

    if (!folder.exists()) {
        return;
    }

    qint64       totalSize = 0;
    QDirIterator it(folderPath, QDir::Files | QDir::NoSymLinks, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        it.next();
        QFileInfo fileInfo(it.filePath());
        totalSize += fileInfo.size();
    }

    double sizeInGB   = static_cast<double>(totalSize) / (1024 * 1024 * 1024);
    double multiplier = std::pow(10.0, 2);
    auto   sizeInGBM  = std::round(sizeInGB * multiplier) / multiplier;
    qDebug() << "sizeInGB:" << sizeInGBM << QString::number(sizeInGBM);
    setUsedSpace(sizeInGBM);
}

void DfsFileFilterModel::mainDir() {
    clear();
    if (!_filterDir)
        return;
    currentDir     = "";
    m_currentActor = "";
    emit currentActorChanged();
    // eLog("main_dir");

    if (!std::filesystem::exists(Dfs::Basic::dirsPath)) {
        return;
    }
    DbConnector dirsFile(Dfs::Basic::dirsPath);
    dirsFile.open();
    auto actors = dirsFile.select("SELECT actor_id FROM " + Dfs::Tables::DirsFile::TableName);
    for (auto &row : actors) {
        append(toMap(DfsModelDirType::Actor, row["actor_id"], "", 0, 0));
    }
}

int DfsFileFilterModel::maxSpace() const {
    return _maxSpace;
}

void DfsFileFilterModel::setMaxSpace(int newMaxSpace) {
    if (_maxSpace == newMaxSpace)
        return;
    _maxSpace = newMaxSpace;
    emit maxSpaceChanged();
}

double DfsFileFilterModel::usedSpace() const {
    return _usedSpace;
}

void DfsFileFilterModel::setUsedSpace(const double &newUsedSpace) {
    //     if (qFuzzyCompare(_usedSpaceInGb, newUsedSpaceInGb))
    //         return;
    _usedSpace = newUsedSpace;
    emit usedSpaceChanged();
}
