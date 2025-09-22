#include "DfsModel.h"

#include "dfs/dfs_controller.h"
#include "managers/extrachain_node.h"
#include "managers/account_controller.h"
#include <QDesktopServices>

DfsModel::DfsModel(ExtraChainNode &node, VariantModel *parent)
    : VariantModel(parent)
    , node(node) {
    setModelRoles({ "isDir", "name", "hash", "size", "progress", "path", "type" });
    showMain();

    QObject::connect(node.dfs(), &DfsController::added, this, &DfsModel::addFile);
    QObject::connect(node.dfs(), &DfsController::uploaded, [this](ActorId owner_id, Dfs::DirRow dirRow) {
        this->updateFileProgress(dirRow.actor_id, dirRow.file_id, 100);
    });
    QObject::connect(node.dfs(), &DfsController::downloaded, [this](ActorId owner_id, Dfs::DirRow dirRow) {
        this->updateFileProgress(dirRow.actor_id, dirRow.file_id, 100);
    });
    QObject::connect(node.dfs(), &DfsController::uploadProgress, this, &DfsModel::updateFileProgress);
    QObject::connect(node.dfs(), &DfsController::downloadProgress, this, &DfsModel::updateFileProgress);
    //    QObject::connect(node.dfs(), &DfsController::uploadProgress,
    //                     [](ActorId actorId, std::string fileHash, int progress) {
    //                         eInfo("[From/DFS] Upload progress: {} {}   {}", actorId
    //, QString::fromStdString(fileHash), progress);
    //                     });
}

void DfsModel::showMain() {
    clear();
    mainDir();
}

void DfsModel::jumpToFolder(const QString &folder) {
    clear();
    currentDir           = folder.toStdString();
    auto currentDirActor = ActorId(currentDir);
    m_currentActor       = folder;
    emit currentActorChanged();

    auto dirRows = Dfs::Tables::ActorDirFile::get_dir_rows(currentDirActor);
    if (!dirRows.has_value())
        return;

    append(toMap(DfsModelDirType::Folder, ".", "", 0, 100));

    for (auto &dirRow : dirRows.value()) {
        if (dirRow.state != Dfs::FileState::Ready) {
            continue;
        }

        try {
            int progress =
                std::filesystem::file_size(Dfs::Path::filePath(currentDirActor, dirRow.file_id)) == dirRow.size
                    ? 100
                    : 0;
            append(toMap(DfsModelDirType::File, dirRow.visual_path(), dirRow.file_id, dirRow.size, progress));
        } catch (...) {
            eWarning("[DfsModel] Error in jumpToFolder");
        }
    }
}

void DfsModel::openFile(int index) {
    Q_UNUSED(index)
#ifndef Q_OS_ANDROID
    QDir().mkpath("tmp/files");

    auto map  = get(index);
    auto hash = map["hash"].toString().toStdString();
    auto name = map["name"].toString();

    auto path = QString::fromStdString(Dfs::Path::filePath(ActorId(currentDir), hash).string()).replace("\\", "/");
    auto tempPath     = "tmp/files/" + name;
    auto fullTempPath = QDir::currentPath() + "/" + tempPath;

    if (!QFile::exists(tempPath) && QFile(path).size() != QFile(tempPath).size()) {
        QFile::copy(path, tempPath);
    }

    QUrl url = QUrl::fromLocalFile(fullTempPath);
    QDesktopServices::openUrl(url);
#endif
}

void DfsModel::removeFile(int index) {
    auto map  = get(index);
    auto hash = map["hash"].toString().toStdString();

    auto path = QString::fromStdString(fmt::format("{}/{}",
                                                   QDir::currentPath().toStdString(),
                                                   Dfs::Path::filePath(ActorId(currentDir), hash).string()))
                    .replace("\\", "/");

    const auto mainActor = node.accountController()->system_actor().id();
    // node.dfs()->remove_stored_file(mainActor, file id);
    remove(index, 1);
}

void DfsModel::addFile(ActorId owner_id, Dfs::DirRow dirRow) {
    if (currentDir.empty()) {
        showMain();
        return;
    }
    if (currentDir != dirRow.actor_id.to_string())
        return;

    jumpToFolder(dirRow.actor_id.toQString());
    emit fileAdded();
    int  progress = 0;
    try {
        progress =
            std::filesystem::file_size(Dfs::Path::filePath(dirRow.actor_id, dirRow.hash)) == dirRow.size ? 100 : 0;
    } catch (std::exception &) {
    }

    append(toMap(DfsModelDirType::File, dirRow.visual_path(), dirRow.file_id, dirRow.size, progress));
}

void DfsModel::updateFileProgress(ActorId actorId, std::string fileName, int progress) {
    if (currentDir != actorId.to_string())
        return;

    QString hash = QString::fromStdString(fileName);
    for (int i = 0; i != count(); i++) {
        auto map = get(i);
        if (map["hash"].toString() == hash) {
            set(i, "progress", progress);
        }
    }
}

QVariantMap DfsModel::toMap(DfsModelDirType isDir, std::string name, std::string hash, qint64 size, int progress) {
    auto path =
        QDir::currentPath() + "/"
        + QString::fromStdString(Dfs::Path::filePath(ActorId(currentDir), name).string()).replace("\\", "/");
    auto url  = QUrl::fromLocalFile(path).toString();
    auto type = Utils::fileMimeSuffix(path);

    return { { "isDir", int(isDir) },
             { "name", QString::fromStdString(name) },
             { "hash", QString::fromStdString(hash) },
             { "size", size },
             { "progress", progress },
             { "path", url },
             { "type", type } };
}

void DfsModel::mainDir() {
    currentDir     = "";
    m_currentActor = "";
    emit currentActorChanged();

    DbConnector dirsFile(Dfs::Basic::dirsPath);
    dirsFile.open();
    auto actors = dirsFile.select("SELECT actor_id FROM " + Dfs::Tables::DirsFile::TableName);
    for (auto &row : actors) {
        append(toMap(DfsModelDirType::Actor, row["actor_id"], "", 0, 0));
    }
}

const QString &DfsModel::currentActor() const {
    return m_currentActor;
}
