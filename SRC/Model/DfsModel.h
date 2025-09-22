#ifndef DFSMODEL_H
#define DFSMODEL_H

#include "chain/actor.h"
#include "dfs/dfs_utils.h"
#include "utils/variant_model.h"

class ExtraChainNode;

enum class DfsModelDirType {
    File,
    Actor,
    Folder
};

class DfsModel : public VariantModel {
    Q_OBJECT

    Q_PROPERTY(QString currentActor READ currentActor NOTIFY currentActorChanged)

public:
    explicit DfsModel(ExtraChainNode &node, VariantModel *parent = nullptr);
    const QString &currentActor() const;

public slots:
    void showMain();
    void jumpToFolder(const QString &folder);
    void openFile(int index);
    void removeFile(int index);

private slots:
    void addFile(ActorId owner_id, Dfs::DirRow dirRow);
    void updateFileProgress(ActorId actorId, std::string fileName, int progress);

signals:
    void fileAdded();

    void currentActorChanged();

private:
    QVariantMap toMap(DfsModelDirType isDir, std::string name, std::string hash, qint64 size, int progress);
    void        mainDir();

    ExtraChainNode &node;
    std::string     currentDir;
    QString         m_currentActor;
};

#endif // DFSMODEL_H
