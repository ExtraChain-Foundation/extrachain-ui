#pragma once

#include <QObject>
#include <QDir>
#include "dfs/dfs_controller.h"
#include "managers/extrachain_node.h"
#include "SRC/Model/DfsModel.h"
#include "utils/db_connector.h"
#include "dfs/dfs_utils.h"

constexpr int max_space_in_gb = 15;

class DfsFileFilterModel : public VariantModel {
    Q_OBJECT
    Q_PROPERTY(int maxSpace READ maxSpace WRITE setMaxSpace NOTIFY maxSpaceChanged FINAL)
    Q_PROPERTY(double usedSpace READ usedSpace WRITE setUsedSpace NOTIFY usedSpaceChanged)

public:
    DfsFileFilterModel(ExtraChainNode *node, bool filterDir, VariantModel *parent = nullptr);

    void    setFilterDir(bool newFilterDir);
    int     maxSpace() const;
    void    setMaxSpace(int newMaxSpace);
    QString toBase64(const std::string &fileId, const QString &nameFile, const QString &extension);
    double  usedSpace() const;
    void    setUsedSpace(const double &newUsedSpace);

public slots:
    void    showMain();
    void    jumpToFolder(const QString &folder);
    void    openFile(const int &index);
    void    exportFile(const int &index, const QString &exportPath);
    QString exportData(const int &index);
    void    addFile(ActorId owner_id, Dfs::DirRow dirRow);
    void    updateFileProgress(ActorId actorId, std::string fileId, int progress);
    void    refresh(const QString &currentActor);
    void    searchIn(const QString &text);
    void    setInFolder(bool inFolder);
    void    calcUsedSpace();

signals:
    void fileAdded();
    void currentActorChanged();
    void maxSpaceChanged();
    void message(const QString &message);
    void sendExportedData(const QString);
    void usedSpaceChanged();

private:
    QVariantMap toMap(DfsModelDirType isDir,
                      std::string     name,
                      std::string     file_id,
                      qint64          size,
                      int             progress,
                      bool            encrypted = false,
                      bool            isImage   = false);
    void        mainDir();

    ExtraChainNode    *node = nullptr;
    std::string        currentDir;
    QString            m_currentActor;
    bool               _filterDir = true, _inFolder = false;
    QList<QVariantMap> _cacheList;
    QString            _usedSpaceInGb;
    int                _maxSpace;
    double             _usedSpace;
};
