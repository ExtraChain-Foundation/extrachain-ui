#pragma once

#include <QCoreApplication>
#include <QGuiApplication>
#include <QObject>
#include <QQmlContext>
#include <QtQml/QQmlApplicationEngine>

#include "ClientController.h"
#include "SRC/MacOs/MacosUtils.h"
#include "SRC/Model/DfsFileFilter.h"
#include "SRC/Model/MessengerController.h"
#include "SRC/Model/NotificationController.h"
#include "SRC/Model/wallet_new/WalletUIController.h"
#include "SRC/etutils.h"
#include "SRC/keychainclass.h"
#include "ShareUtils.hpp"
#include "managers/extrachain_node.h"
#include <QString>

#include "SRC/platforms/android/androidutils.h"

#ifndef QT_DEBUG
constexpr double FULL_DAG_MODE_MIN_SIZE = 15.5;
constexpr double FULL_DAG_MODE_AND_DFS_MIN_SIZE = 35.0;
#else
constexpr double FULL_DAG_MODE_MIN_SIZE = 1;
constexpr double FULL_DAG_MODE_AND_DFS_MIN_SIZE = 4;
#endif

class ExtraChainController : public QObject {
  Q_OBJECT
  QQmlApplicationEngine *_engine;
  ExtraChainNodeWrapper *nodeWrapper;
  std::shared_ptr<EtUtils> etUtils;
  std::shared_ptr<ShareUtils> shareUtils;
  ClientController *uiController = nullptr;
  DfsFileFilterModel *dfsDirFilterModel;
  DfsFileFilterModel *dfsFileFilterModel;
  bool isWiped = false;
  void updatePath();
  QString _mainActor;
  WalletUIController *walletUiController;
  MessengerController *messengerController;
  KeyChainClass *keyChainClass;
  AndroidUtils androidUtils;
  NotificationController *notificationController;

public:
  Q_PROPERTY(QString mainActor READ mainActor WRITE setMainActor NOTIFY
                 mainActorChanged)
  Q_PROPERTY(bool isAvailbaleFullMode READ isAvailbaleFullMode NOTIFY
                 isAvailbaleFullModeChanged FINAL)
  Q_PROPERTY(double fullDagModeMinSize READ fullDagModeMinSize CONSTANT)
  Q_PROPERTY(
      QString availableGB READ availableGB NOTIFY availableGBChanged FINAL)

  ExtraChainController(QQmlApplicationEngine *engine);
  ~ExtraChainController();

  QString mainActor() const { return _mainActor; }
  void setMainActor(const QString &newValue);

  Q_INVOKABLE int statusHeight() { return AndroidUtils::getStatusBarHeight(); }

  bool isAvailbaleFullMode() const;

  double fullDagModeMinSize() const;

  QString availableGB() const;

  Q_INVOKABLE void closeApp() const;

  Q_INVOKABLE void retranslate() const { _engine->retranslate(); }

public slots:
  void sighUp(const QString ip, const QString login, const QString &password,
              const QString &confirmPassword);
  Network::Protocol getNetworkProtocol();
  void importProfile(const QString &pathToFile, QString login,
                     QString password);
  void importProfileForIos(const QString fileContent, const QString login,
                           const QString password);
  void exportProfile(const QString &folderExport,
                     const QString &nameFileExport);
  void fillMainActorData();
  void removeFile(const QString &actor, const QString &fileName);
  void createToken(const QString &tokenCount, const QString &tokenName,
                   const QString &symbol, const QString &relAddress,
                   const QString &color);
  void clearData();
  std::string exportedData();
  void kill();
#ifdef Q_OS_IOS
  void verifyWithFaceID();
#endif
  bool isFaceIDAvailable();

signals:
  void walletCreated();
  void decryptedKeystore(bool hashLoaded = false,
                         const QString &message = QString());
  void exportImportKeystore(const QString &message = QString());
  void showMessageErrorBox(const QString &title, const QString &message);
  void createTxError(const QString &);
  void sendedTx();
  void failedTxCreate(const QString &);
  void mainActorChanged();
  void errorNameTokenExist(const QString &);
  void errorSymbolTokenExist(const QString &);
  void addedToken();
  void wipeData(int type, const QString &title, const QString &message);
  void updateHash(const QString &hash);
  void fileRemoved();
  void dagSyncFinish();
  void dagControlStarted();
  void dagControlEnded();
  void dagSearchControlStarted();
  void dagSearchControlEnded();
  void dagTxSended(const QString &hash);
  void dagTxApproved(const QString &hash);
  void dagTxNotApproved(const QString &hash);
  void actorsStarted();
  void actorsEnded();
  void actorsProgress(int, int);
  void isAvailbaleFullModeChanged();
  void availableGBChanged();
#ifdef Q_OS_IOS
  void iosFaceAuth(const bool &result);
#endif

public slots:
  void sendTransactionFromUi(ActorId reciever, BigNumberFloat actor,
                             ActorId token);
  void addNewWallet(const QString &nameWallet);
  void createTx(const QString &walletTo, const QString &coinName,
                const QString &amount, const QString &newtwork = QString());
  void sendTx(const QString &walletFrom, const QString &walletTo,
              const QString &coinName, const QString &amount,
              const QString &newtwork = QString());
  // KeyChainClass* keychain() const;
  void availableFullModeInit();

private:
  void connections();
  QString _walletBalance;
#ifdef Q_OS_IOS
  ApplePlatformUtils *iosUtils;
#endif
  bool _isAvailbaleFullMode;
  QString _availableGB;
};

class Onboarding : public QObject {
  Q_OBJECT
public:
  enum OnboardingPage {
    Mining_Info,                       // 3
    Wallet_Access,                     // 4
    Notifications_And_Settings,        // 5
    Storage_Space,                     // 6
    Storage_Upgrade,                   // 7
    Storage_Search,                    // 8
    Storage_View_Options,              // 9
    Storage_Notification_and_Settings, // 10
    Wallet_Estimate_Balance,           // 11
    Wallet_Transaction_List,           // 12
    Wallet_Select,                     // 13
    Finished
  };
  Q_ENUM(OnboardingPage)
};

class Tooltip : public QObject {
  Q_OBJECT
public:
  enum TooltipType {
    Deposit,
    Withdraw,
    Settings,
    UploadFile,
    Mining,
    CopiedAddress,
    Message
  };
  Q_ENUM(TooltipType)
};

class ConnectStatus : public QObject {
  Q_OBJECT

public:
  enum StatusConnect { NotConnected, InProcess, Connected };
  Q_ENUM(StatusConnect)
};

class MenuSelector : public QObject {
  Q_OBJECT
public:
  enum SelectorMenu { Wallet, Dfs, Settings, Notification };
  Q_ENUM(SelectorMenu)
};
