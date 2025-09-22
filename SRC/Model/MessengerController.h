#pragma once

#include <QObject>
#include <QtCore/qvariant.h>
#include "chat/message.h"
#include "dfs/dfs_utils.h"
#include "managers/extrachain_node.h"
#include "utils/variant_model.h"
#include <QAbstractListModel>
#include <QDir>
#include "DfsFileFilter.h"

class BlurHashEncoder;
class UserModel : public VariantModel {
    Q_OBJECT

public:
    explicit UserModel(VariantModel *parent = nullptr);

public slots:
    void newActor(ActorId actorId);
};

class ChatListModel : public VariantModel {
    Q_OBJECT

public:
    explicit ChatListModel(VariantModel *parent = nullptr);
};

class ChatModel : public VariantModel {
    Q_OBJECT

public:
    explicit ChatModel(VariantModel *parent = nullptr);
};

class MessengerController : public QObject {
    Q_OBJECT

public:
    Q_PROPERTY(UserModel *userModel READ userModel WRITE setUserModel NOTIFY userModelChanged)
    Q_PROPERTY(ChatListModel *chatListModel READ chatListModel WRITE setChatListModel NOTIFY chatListModelChanged)
    Q_PROPERTY(ChatModel *chatModel READ chatModel WRITE setChatModel NOTIFY chatModelChanged)

    MessengerController() {};
    MessengerController(ExtraChainNode *nde, QObject *parent = nullptr);

    UserModel     *userModel() const;
    ChatListModel *chatListModel() const;
    ChatModel     *chatModel() const;

    void        setUserModel(UserModel *newUserModel);
    void        setChatListModel(ChatListModel *newChatListModel);
    void        setChatModel(ChatModel *newChatModel);
    QVariantMap chatToMap(const Chat::Chat &chat);
    void        addMessage(const Chat::Message &message);
    void        addMessages(const std::vector<Chat::Message> &messages);

public slots:
    void                                 updateChatListModel();
    void                                 updateChatModel(QString fileOwnerId, QString fileId, bool quick);
    void                                 sendMessage(QString text);
    void                                 replyMessage(const QString &text, const QString &messageId);
    void                                 sendGif(const QString &gifUrl, const QString &messageId = QString());
    void                                 sendImage(const QString &pathToFile,
                                                   const QString &localPath,
                                                   const QString &messageId = QString(),
                                                   const QString &caption   = QString());
    void                                 sendVideo(const QString &pathToFile,
                                                   const QString &messageId = QString(),
                                                   const QString &caption   = QString());
    void                                 sendFile(const QString &pathToFile,
                                                  const QString &messageId = QString(),
                                                  const QString &caption   = QString());
    void                                 editMessage(const QString &text, const QString &messageId);
    void                                 removeMessage(QString id);
    bool                                 createChat(QString actorWith);
    QString                              currentDir();
    QString                              getFileNameFromMessage(const QString &message);
    void                                 exportFile(const QString &message, const QString &export_path);
    QString                              storeImageToCache(const QString &messageData, const bool &isBlurState);
    int                                  heightHashBlur(const QString &messageData);
    int                                  widthHashBlur(const QString &messageData);
    void                                 updateCacheInput(const QString &cahtId, const QString &message);
    QString                              getCachedMessage(const QString &chatId) const;
    void                                 addFiles(const QStringList &files,
                                                  const bool         messenger_send_as_file = false,
                                                  const QString     &chatId                 = "",
                                                  const QString     &replyMessageId         = QString(),
                                                  const QString     &caption                = QString());
    std::expected<void, ExportFileError> export_file(const ActorId              &owner_id,
                                                     const std::string          &file_id,
                                                     const FsPath               &output_folder,
                                                     const std::string          &name_file,
                                                     const Dfs::DataSecurityKey &dsk);
    void                                 getIndexByMessageId(const QString &messageId);
signals:
    void userModelChanged();
    void chatListModelChanged();
    void chatModelChanged();
    void error(const QString &errorMessage);
    void newChatAdded(QString actor);
    void newMessageAdded(QString actor);
    void exported(const QString message);
    void messengerAddedFile(const QString &pathToFile,
                            const QString &selectedFile,
                            const bool    &asFile,
                            const QString &parentMessageId,
                            const QString &caption);
    void moveToIndex(const int &index);
    void runAnimation(const int &index);

private:
    ExtraChainNode        *node;
    UserModel             *_userModel     = nullptr;
    ChatListModel         *_chatListModel = nullptr;
    ChatModel             *_chatModel     = nullptr;
    ActorId                owner_id;
    std::string            file_id;
    std::string            my_chats_file_id;
    QMap<QString, QString> _cacheInputMessages;
    QString                _current_owner_id, _current_file_id;
};

class MessegeDelegateType : public QObject {
    Q_OBJECT
public:
    enum TypeDelegate {
        Text,
        Created,
        Invite,
        Join,
        Image,
        Gif,
        Video,
        File
    };
    Q_ENUM(TypeDelegate)
};

class BlurHashEncoder {
public:
    static QString encode(const QImage &image, int componentsX = 4, int componentsY = 3);
};
