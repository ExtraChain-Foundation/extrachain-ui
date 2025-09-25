#pragma once

#include <QBrush>
#include <QDesktopServices>
#include <QImage>
#include <QImageReader>
#include <QJSValue>
#include <QPainter>
#include <QPen>

#include <encryption/encryption_tools.h>

#include "chain/actor.h"
#include "dfs/dfs_controller.h"
#include "managers/account_controller.h"
#include "managers/thread_pool.h"
#include "SRC/etutils.h"
#include "SRC/profile.h"
#include "SRC/profiledata.h"
#include "SRC/ShareUtils.hpp"
// #include "SRC/Model/wallet/walletcontroller.h"
#include "utils/autologinhash.h"

#include "SRC/updater.h"

/**
 * @brief ClientController
 * Class for interacting with UI
 */

class ClientController : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool networkStatus READ networkStatus WRITE setNetworkStatus NOTIFY networkStatusChanged)
    Q_PROPERTY(int networkSockets READ networkSockets WRITE setNetworkSockets NOTIFY networkSocketsChanged)
    Q_PROPERTY(bool serverError READ serverError WRITE setServerError NOTIFY serverErrorChanged)
    Q_PROPERTY(Profile profile READ profile WRITE setProfile NOTIFY profileChanged)
    Q_PROPERTY(double appWidth READ appWidth WRITE setAppWidth NOTIFY appWidthChanged)
    Q_PROPERTY(bool isApp READ isApp WRITE setIsApp NOTIFY isAppChanged)
    Q_PROPERTY(QString authHash READ authHash WRITE setAuthHash NOTIFY authHashChanged)

    Q_PROPERTY(bool subscribed READ subscribed NOTIFY subscribedChanged)
    Q_PROPERTY(bool subscribeActive READ subscribeActive NOTIFY subscribeActiveChanged)
    Q_PROPERTY(bool usernameActive READ usernameActive NOTIFY usernameActiveChanged)

    bool prepareMediaForPostsEvents(QVariantMap &map);

    // std::shared_ptr<WalletController> wallet;
    std::shared_ptr<WelcomePage> welcomePage;
    ActorId                      currentActorId;
    std::shared_ptr<ShareUtils>  shareUtils;
    std::shared_ptr<EtUtils>     etUtils;
    bool                         m_networkStatus = false;
    bool                         m_needWipe      = false;
    void                         connectSignals();

public:
    ClientController(QObject *parent = nullptr);
    ~ClientController();

    // RecentActivitiesModel *getRecentActivitiesModel();
    // WalletController *getWallet();
    // WalletListModel *getWalletListModel() const;
    // AvailableWalletsModel *getAvailableWalletsModel() const;
    WelcomePage *getWelcomePage() const;
    Profile      profile() const;

    bool    networkStatus() const;
    bool    needWipe();
    bool    serverError() const;
    int     networkSockets() const;
    void    setShareUtils(const std::shared_ptr<ShareUtils> &value);
    double  appWidth() const;
    bool    isApp() const;
    int     getAuthStatus() const;
    void    setAuthStatus(int value);
    void    setNode(ExtraChainNode *newNode);
    void    setEtUtils(const std::shared_ptr<EtUtils> &newEtUtils);
    QString authHash() const;
    void    setAuthHash(const QString &newAuthHash);
    void    loadHash();

    Q_INVOKABLE void changeTranslation(const QString &language);

    Q_INVOKABLE bool isProfileEmpty() {
        return AccountController::profiles_list().empty();
    }

    Q_INVOKABLE QString calcRoccSummary();
    Q_INVOKABLE QString calcActiveUsers();

    Q_INVOKABLE QString checkUpdate();
    Q_INVOKABLE bool    downloadUpdate();
    Q_INVOKABLE void    installUpdate();

    Q_INVOKABLE bool isBlockchainLight();
    Q_INVOKABLE void setBlockchainLight(bool isLight);

    Q_INVOKABLE bool isDfsLight();
    Q_INVOKABLE void setDfsLight(bool isLight);

    std::string usernames_file_id;
    std::string sub_file_id;

    Q_INVOKABLE QVariantList loadUserNames();
    Q_INVOKABLE QString      loadUserName(QString actorId);
    // actorIds
    Q_INVOKABLE bool addUsername(QString username);
    Q_INVOKABLE bool existsUsername(QString username);
    Q_INVOKABLE bool removeUsername();

    Q_INVOKABLE void loadSubscription();
    Q_INVOKABLE void addSubscription(int type, bool auto_renew);

    Q_INVOKABLE QStringList getPhrase();
    Q_INVOKABLE bool        validatePhrase(const QString &phrase);
    Q_INVOKABLE bool        importPhrase(const QString &login, const QString &password, const QString &phrase);
    Q_INVOKABLE bool        importHex(const QString &login, const QString &password, const QString &hex);
    Q_INVOKABLE QString     importedHex(const QString &_);
    Q_INVOKABLE bool        isNewProfile();

    bool subscribed() const;
    bool subscribeActive() const;
    bool usernameActive() const;

public slots:
    void subscriptionAdded();

    QString      myId();
    void         setNeedWipe(bool needWipe);
    void         addAvatar(QString imageFile, bool temp, const int x, const int y, const int size);
    void         addEvent(QVariantMap event);
    QVariantList tokens();
    QVariantMap  token(const QString &id);
    void         logOut();

    /**
     * @brief registrationCompletion
     * @param userId
     * @details Slot that is called when new actor registration in backend is
     * completed
     *
     * @return
     */
    void         userRegistrationCompletion(ActorId userId,
                                            bool    isUser); // recieve userId from Node
    void         logIn();
    void         autoLogIn();
    QVariantList multipleProfiles();
    void         logInTo(const QString &actorId);
    void         loginPrivateProfile(QByteArray id, QByteArrayList idList);
    void         loadInfo(const QByteArray &info, const QString &value);
    void         profileRe(QString userId, Profile profile);
    void         newNotification(Notification ntf);
    void         addPortfolio(QString image);
    void         setNetworkStatus(bool networkStatus);
    void         setProfile(Profile profile);
    void         setServerError(bool serverError);
    void         setNetworkSockets(int networkSockets);
    void         setAppWidth(double appWidth);
    void         setIsApp(bool isApp);
    void         chatFileLoaded(QString fileName, QString originalFile);
    QString      localServerIp();
    void         requestQProfile(const QString &userId, QJSValue callback);
    void         blockDfs();
    void         needProfile(const QString &userId);
    void         like(QString userId, QString postId, bool isRemove, bool isPost);
    void         likeComment(QString userId, QString postId, QString commentId, bool isRemove, bool isPost);
    void         mark(QString userId, QString postId, bool isRemove, bool isPost);
    void postComment(QString commentId, QString userId, QString postId, QString text, QString sub, bool isPost);
    int  updateLikesTemp(QString userId, QString postId, bool isPost);
    QVariantList loadCommentsTemp(QString userId, QString postId, bool isPost);
    QVariantList loadCommentsLikesTemp(QString userId, QString postId, QString commentId, bool isPost);
    QVariantList loadLikesTemp(QString userId, QString postId, bool isPost);
    bool         isFirst(const QString &userId);
    QVariantList chatOwners();
    QVariantMap  exportAttach(QString fileName);
    // int exportFile(QString dfsPath, QString origName, int originSize, QString chatId);
    void shareFile(QString dfsPath, QString type);
    int  saveFile(QString dfsPath);
    // QVariantMap tx(QString hash, QString token);
    QString myUsername();
    int     editUsername(const QString &username);
    QString usernameById(const QString &userId);
    QString idByUsername(const QString &username);
    // QVariantMap benchmark();
    // bool chatFile(QString filePath, QString chatId, int type);
    bool uploadFile(QString filePath);
    // void openChatFile(QString chatId, QString dfsPath, QString originName, int originSize,
    // QString openType);
    void         skipAuth();
    QString      fixFileName(const QString &fileName);
    QString      firstId();
    qint64       actorsCount();
    QVariantList networkConnections();
    void         networkConnectionRemove(const QString &identifier);
    bool         serverStatus(Network::Protocol protocol) const;
    quint64      currentDfsLimit();
    void         changeDfsLimit(quint64 size);
    QString      testButton(const QString &f);
    void         addFiles(const QStringList &files,
                          const int          service_folder         = 0,
                          const bool         messenger_send_as_file = false);
    QString      fileName(const QString &file);

signals:
    void prepare();
    void connectionError(Network::SocketServiceError error, QString identifier, QString errorData);
    void generateSmartContract(QByteArray tokenCount,
                               QByteArray tokenName,
                               QByteArray rulAddress,
                               QByteArray color);
    void connectToNode(const QString    &ip,
                       Network::Protocol protocol,
                       bool              request    = true,
                       bool              isConstant = true,
                       bool              isLight    = false);
    void updateNetworkDeviceId();
    void updateAvatarImage();
    void regStarted(QByteArray);
    void networkStatusChanged(bool networkStatus);
    void authEnded(bool status, int type);
    void eventsUpdated();
    void myEventsUpdated();
    // profileLoaded
    void profileUpdated(QString profileId, Profile profile);
    void profilePageUpdated(QString profileId, Profile profile);
    void requestProfile(QString userId);
    void saveProfile(QByteArrayList profile);
    void profileChanged(Profile profile);
    void serverErrorChanged(bool serverError);
    void sendProfile();
    void logout();
    void profileLogout();

    // chat
    void createChat();                                        // group
    void inviteToChat(QByteArray chatId, QByteArray actorId); // group

    // dialogue
    void createDialogue(QByteArray actorId);

    // request
    void requestChatList();
    void requestChat(QByteArray chatId);
    void sendMessage(QByteArray chatId, QByteArray message, QString type);
    void messageReceived(QByteArray chatId, QByteArray userId, QByteArray text);
    void removeChat(QByteArray);
    void networkSocketsChanged(int networkSockets);
    void appWidthChanged(double appWidth);
    void isAppChanged(bool isApp);
    void fileLoaded(QString fileName);
    void authStatus(int status, int type);
    void iWantMyServiceAndPrivateQuickly();
    void noMoreServiceAndPrivate();
    void removeChatMessage(QString chatId, QString messId);
    void sendNotificationToken(QString os, QString actorId, QString token);
    void authHashChanged();
    // add files
    void resultAddFile(const QString &result, const QString &fileName);
    void messengerAddedFile(const QString &pathToFile, const QString &selectedFile, const bool &asFile);
    void loginError(int error);
    void avatarChanged(QString userId);
    void newNotify(Notification notify);
    void notify(QString userId, int type);

    void sendVpnsRequest();

    void subscribedChanged();
    void subscribeActiveChanged();

    void usernameActiveChanged();
    void usernamesUpdated();

    void updaterDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void updaterDownloadFinished(bool success);

private:
    void                                             loginHandler(bool loginResult);
    ExtraChainNode                                  *m_node;
    Profile                                          currentProfile;
    bool                                             m_serverError    = false;
    int                                              m_networkSockets = 0;
    double                                           m_appWidth;
    bool                                             m_isApp = false;
    QMap<QString, QList<QJSValue>>                   qProfileCallbacks;
    QMap<QString, Profile>                           profilesCache;
    QMap<QString, std::tuple<QString, QString, int>> sendedChatFiles;
    // std::pair<QByteArray, bool> getChatKey(QString myId, QString chatId);
    QStringList   waitingFiles;
    QStringList   waitingFilesNetwork;
    int           authType = -1;
    bool          authDone = false;
    bool          regDone  = true;
    AutologinHash m_autologinHash;
    void          reconnection();
    bool          m_subscribed      = false;
    bool          m_subscribeActive = false;
    bool          m_usernameActive  = false;

    Updater updater;
};
