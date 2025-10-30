#include "ExtraChainController.h"

#include <QtConcurrent>

#include "SRC/HelperMacOs.h"
#include "SRC/helper_linux.h"

#include "SRC/MacOs/MacosUtils.h"
#include "SRC/Model/MessengerController.h"
#include "SRC/keychainclass.h"
#include "chain/actor_index.h"
#include "managers/token_manager.h"
#include "network/network_manager.h"

#include "extrachain_version.h"
// #include "managers/import_export_keystore.h"

ExtraChainController::ExtraChainController(QQmlApplicationEngine *engine)
    : _engine(engine) {

  engine->rootContext()->setContextProperty(
      "filePrefix", QString::fromStdWString(Utils::filePrefix));
  engine->rootContext()->setContextProperty("buildDate", COMPILE_DATE);
  eLog("Build date: {}", COMPILE_DATE);

  QString currentPath = qApp->applicationDirPath();
  eLog("application_dir_path: {}", qApp->applicationDirPath());
  shareUtils = std::make_shared<ShareUtils>();

#ifdef Q_OS_IOS
  currentPath =
      QStandardPaths::standardLocations(QStandardPaths::DocumentsLocation)
          .value(0);
//    iPhoneSpecialLayout = iOSUtils::iPhoneLess();
#endif

  updatePath();

#ifdef Q_OS_MAC
  QString appData;
#ifdef Q_OS_MACOS
  appData = QString("/Users/%1/Library/Application Support/Extrachain")
                .arg(getMacUser());
#elif defined(Q_OS_IOS)
  appData = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) +
            "/Extrachain";
#else
#endif
  qDebug() << appData;
  bool res = QDir().mkdir(appData) || QDir(appData).exists();
  qDebug() << res;
  if (!res) {
    eInfo("Can't create Extrachain folder");
    qApp->quit();
  }

  QString appPath = appData + "/" + Utils::dataDir();
  bool isAppExists = QDir(appPath).exists();

  if (!isAppExists) {
    // Version compatibility: 0.15.0
    QString binPath = currentPath + "/" + Utils::dataDir();
    bool isBinExists = QDir(binPath).exists();

    if (isBinExists) {
      QDir().rename(binPath, appPath);
    }
  }

  currentPath = appData;
#endif

  currentPath += "/" + Utils::dataDir();
  if (QDir(currentPath).exists()) {
    QDir::setCurrent(currentPath);
  }

  QDir().mkpath(currentPath);
  QDir::setCurrent(currentPath);
  eLog("Current dir: {}", currentPath);

  if (QFile("wipe").exists()) {
    eLog("Make wipe...");
    QFile("wipe").remove();
    Utils::wipeDataFiles();
  }

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
  RaccoonLinux::folderWriteUser();
#endif

#ifndef Q_OS_IOS
  Logger::start_file("extrachain");
#endif

  eLog("Extrachain {}, core {}", extrachain_version, extrachain_version);

  bool networkStatus = true;
#ifdef Q_OS_WIN
  networkStatus = true;
#endif

  bool isProfilesEmpty = AccountController::profiles_list().empty();
  bool hashExists = AutologinHash::is_available();
  eLog("Contructor ExtrachainController isProfilesEmpty: {}  hashExists: {}",
       isProfilesEmpty, hashExists);

  auto rootContext = engine->rootContext();

  nodeWrapper = new ExtraChainNodeWrapper(this, true, true);

  etUtils = std::make_shared<EtUtils>(nodeWrapper->node);
  engine->rootContext()->setContextProperty("etUtils", etUtils.get());

  ClientController tmpClientController;
  rootContext->setContextProperty("uiController", &tmpClientController);
  WalletUIController wuc{};
  rootContext->setContextProperty("walletUIController", &wuc);
  rootContext->setContextProperty("walletModel", wuc.wallets());
  rootContext->setContextProperty("walletTxsModel", wuc.txs());
  rootContext->setContextProperty("arch", QSysInfo::buildCpuArchitecture());
  rootContext->setContextProperty("extrachainVersion",
                                  QString::fromStdString(extrachain_version));
  rootContext->setContextProperty("serverIpDefault",
                                  EtUtils::defaultServerIp());

  DfsFileFilterModel dfm(nodeWrapper->node, false);
  rootContext->setContextProperty("dfsFileFilterModel", &dfm);
  rootContext->setContextProperty("dfsDirFilterModel", &dfm);

  MessengerController mc;
  rootContext->setContextProperty("messengerController", &mc);

  bool isPlayMarket = false;
#ifdef EXTRACHAIN_PLAY_MARKET
  isPlayMarket = true;
#endif
  rootContext->setContextProperty("isPlayMarket", isPlayMarket);
#ifdef Q_OS_IOS
  iosUtils = new ApplePlatformUtils(this);
  connect(iosUtils, &ApplePlatformUtils::resultFaceId, this,
          &ExtraChainController::iosFaceAuth);
#endif

  connect(
      nodeWrapper->node, &ExtraChainNode::nodeInitialised, this,
      [engine, this]() {
        auto node = nodeWrapper->node;
        availableFullModeInit();

        uiController = new ClientController();
        uiController->setNode(node);
        uiController->setShareUtils(shareUtils);
        uiController->setEtUtils(etUtils);
        dfsDirFilterModel = new DfsFileFilterModel(node, true);
        dfsFileFilterModel = new DfsFileFilterModel(node, false);
        auto rootContext = engine->rootContext();
        rootContext->setContextProperty("dfsFileFilterModel",
                                        dfsFileFilterModel);
        rootContext->setContextProperty("dfsDirFilterModel", dfsDirFilterModel);
        rootContext->setContextProperty("dfsFolderName", "dfs");
        rootContext->setContextProperty("isWiped", isWiped);
        rootContext->setContextProperty("uiController", uiController);
        rootContext->setContextProperty("welcomePage",
                                        uiController->getWelcomePage());

        walletUiController = new WalletUIController(node);
        rootContext->setContextProperty("walletUIController",
                                        walletUiController);
        rootContext->setContextProperty("walletModel",
                                        walletUiController->wallets());
        rootContext->setContextProperty("walletTxsModel",
                                        walletUiController->txs());

        messengerController = new MessengerController(node);
        rootContext->setContextProperty("messengerController",
                                        messengerController);

        keyChainClass = new KeyChainClass(this);
        rootContext->setContextProperty("keyChain", keyChainClass);

        notificationController = new NotificationController();
        rootContext->setContextProperty("notificationController",
                                        notificationController);

        connections();
        uiController->prepare();
      },
      Qt::QueuedConnection);

  nodeWrapper->init(true);
}

ExtraChainController::~ExtraChainController() {
  eLog("[Destructor ExtraChainController].");
  if (uiController != nullptr && uiController->needWipe()) {
    QFile("wipe").open(QFile::WriteOnly);
  }

  delete nodeWrapper;
  if (uiController != nullptr) {
    uiController->deleteLater();
  }
}

void ExtraChainController::sighUp(const QString ip, const QString login,
                                  const QString &password,
                                  const QString &confirmPassword) {
  // eLog("sighUp: \nip:  {} \nlogin:  {} \npassword:  {} \nconfirm password:
  // {}",
  //      ip,
  //      login,
  //      password,
  //      confirmPassword);

  emit uiController->authEnded(true, 3);
  emit uiController->connectToNode(etUtils->serverIp(),
                                   Network::Protocol::WebSocket);
  // setMainActor(node->accountController()->mainActor()->id().toString());
}

Network::Protocol ExtraChainController::getNetworkProtocol() {
  return Network::Protocol::WebSocket;
}

void ExtraChainController::importProfile(const QString &pathToFile,
                                         QString login, QString password) {
  eLog("{} {}", pathToFile, password);

  if (login.isEmpty() && password.isEmpty()) {
    login = password = "any";
  }

  QFile file(pathToFile);
  if (!file.open(QIODevice::ReadOnly)) {
    std::cerr << "Unable to open the file!" << std::endl;
    emit exportImportKeystore("Import operation failed: file access");
    return;
  }

  QByteArray fileContent = file.readAll();
  file.close();

  if (!fileContent.isEmpty()) {
    std::string fileContentStr = fileContent.toStdString();
    auto from_base64 = Utils::from_base64(fileContentStr);
    if (!from_base64.has_value()) {
      emit exportImportKeystore("Import operation failed: base64");
      return;
    }

    std::string error = "";
    auto hash = nodeWrapper->node->import_profile(
        from_base64.value(), login.toStdString(), password.toStdString());
    if (hash.has_value()) {
      emit exportImportKeystore("Profile successfully imported!");
      uiController->setAuthHash(QString::fromStdString(hash.value()));
      uiController->logIn();
      emit updateHash(QString::fromStdString(hash.value()));
    } else {
      switch (hash.error()) {
      case ImportProfileError::DecryptError:
        error = "The username or password you entered is incorrect. Please try "
                "again.";
        break;
      case ImportProfileError::DataEmpty:
        error = "Import data is empty";
        break;
      case ImportProfileError::LoginPasswordEmpty:
        error = "Login and password is empty.";
        break;
      case ImportProfileError::IncorrectJson:
        error = "Json data is empty";
        break;
      }

      emit showMessageErrorBox("Import error", QString::fromStdString(error));
      return;
    }
  } else {
    emit exportImportKeystore("Import operation failed: file content");
  }
}

void ExtraChainController::importProfileForIos(const QString fileContent,
                                               const QString login,
                                               const QString password) {
  if (!fileContent.isEmpty()) {
    QString cleanedContent = fileContent;
    int firstQuote = cleanedContent.indexOf("\"");
    int lastQuote = cleanedContent.lastIndexOf("\"");
    if (firstQuote != -1 && lastQuote != -1 && firstQuote != lastQuote) {
      cleanedContent =
          cleanedContent.mid(firstQuote + 1, lastQuote - firstQuote - 1);
    }
    auto fc = cleanedContent.toStdString();
    auto from_base64 = Utils::from_base64(fc);
    if (!from_base64) {
      qDebug() << "Base64 decoding failed: "
               << static_cast<int>(from_base64.error());
      return;
    }
    auto hash = nodeWrapper->node->import_profile(
        from_base64.value(), login.toStdString(), password.toStdString());
    if (hash.has_value()) {
      qDebug() << "Profile successfully imported!";
      emit exportImportKeystore("Profile successfully imported!");
      uiController->getWelcomePage()->setEmail(login.toLatin1());
      uiController->getWelcomePage()->setPassword(password.toLatin1());

      uiController->setAuthHash(QString::fromStdString(hash.value()));
      uiController->logIn();
    } else {
      QString error;
      switch (hash.error()) {
      case ImportProfileError::DecryptError:
        error = "The username or password you entered is incorrect. Please try "
                "again.";
        break;
      case ImportProfileError::DataEmpty:
        error = "Import data is empty";
        break;
      case ImportProfileError::LoginPasswordEmpty:
        error = "Login and password is empty.";
        break;
      case ImportProfileError::IncorrectJson:
        error = "Json data is empty";
        break;
      }

      emit showMessageErrorBox("Import error", error);
      return;
    }
  } else {
    emit exportImportKeystore("Import operation failed: file content");
  }
}

void ExtraChainController::exportProfile(const QString &folderExport,
                                         const QString &nameFileExport) {
  if (folderExport.isEmpty() || nameFileExport.isEmpty()) {
    eWarning("[ProfileExport] Folder or name is empty. Folder: {}, name: {}",
             folderExport, nameFileExport);
    return;
  }

  eLog("Start export profile");
  eLog("{} {}", folderExport, nameFileExport);

  std::expected<std::string, ImportError> res =
      nodeWrapper->node->export_profile();
  if (!res.has_value()) {
    QString errorText =
        "Export operation failed: " +
        QString::fromStdString(Utils::enum_value_name_value(res.error()));
    eWarning("{}", errorText);
    emit exportImportKeystore(errorText);
    return;
  }

  eLog("Start export to {}/{}", folderExport, nameFileExport);

  QString filePath = QString("%1/%2").arg(folderExport, nameFileExport);

  auto fs_path = FsPath::create(filePath.toStdString());
  if (!fs_path.has_value()) {
    emit exportImportKeystore("Export operation failed: file path");
    eWarning("Export operation failed: file path");
    return;
  }

  std::ofstream file(fs_path->native(), std::ios::binary);

  if (!file) {
    emit exportImportKeystore("Export operation failed: file access");
    eWarning("Export operation failed: file access");
    return;
  }

  auto fileContent = nodeWrapper->node->account_controller()->profile_type() ==
                             ProfileType::New
                         ? res.value()
                         : Utils::to_base64(res.value());

  if (!file.write(fileContent.c_str(), fileContent.size())) {
    emit exportImportKeystore("Export operation failed: file write");
    eWarning("Export operation failed: file write");
    return;
  }
  file.close();

#ifndef Q_OS_ANDROID
  emit exportImportKeystore("Profile successfully saved to file!");
#else
  androidUtils.shareFile(QString::fromStdString(fs_path->native().string()));
#endif

  eLog("Profile successfully saved to file");
}

void ExtraChainController::fillMainActorData() {
  eLog("begin fill main actor data");
  auto mainId =
      nodeWrapper->node->account_controller()->current_profile().main_id();
  setMainActor(mainId.toQString());
  walletUiController->startControl();
}

void ExtraChainController::removeFile(const QString &actor,
                                      const QString &fileName) {
  eLog("Begin remove file. Actor - {}  filename: {}", actor, fileName);
  auto result = nodeWrapper->node->dfs()->remove_stored_file(
      ActorId(actor.toStdString()), fileName.toStdString());
  if (result)
    emit fileRemoved();
}

void ExtraChainController::createToken(const QString &tokenCount,
                                       const QString &tokenName,
                                       const QString &symbol,
                                       const QString &relAddress,
                                       const QString &color) {
  auto count = BigNumberFloat::create(tokenCount.toStdString());
  if (!count.has_value()) {
    return;
  }

  nodeWrapper->node->token_manager()->create_token(
      ActorId(relAddress.toStdString()), tokenName.toStdString(),
      symbol.toStdString(), count.value(), color.toStdString());
}

void ExtraChainController::clearData() {
  qDebug() << "Begin clear data";
  Utils::wipeDataFiles();
  QString program = QCoreApplication::applicationFilePath();
  //    QProcess::startDetached(program);
  QCoreApplication::quit();
}

std::string ExtraChainController::exportedData() {
  std::expected<std::string, ImportError> res =
      nodeWrapper->node->export_profile();
  if (!res.has_value()) {
    QString errorText =
        "Export operation failed: " +
        QString::fromStdString(Utils::enum_value_name_value(res.error()));

    emit exportImportKeystore(errorText);
    return "";
  }

  return Utils::to_base64(res.value());
}

void ExtraChainController::kill() { std::exit(0); }

#ifdef Q_OS_IOS
void ExtraChainController::verifyWithFaceID() { iosUtils->triggerFaceID(); }
#endif

bool ExtraChainController::isFaceIDAvailable() {
#ifdef Q_OS_IOS
  return iosUtils->isFaceIDAvailable();
#endif
  return false;
}

void ExtraChainController::setMainActor(const QString &newValue) {
  if (_mainActor != newValue) {
    _mainActor = newValue;
    eLog("main actor is {}", newValue);
    emit mainActorChanged();
  }
}

void ExtraChainController::updatePath() {
#ifdef QT_DEBUG
  Utils::dataDir("test-data");
#else
  Utils::dataDir("public-data");
#endif
}

void ExtraChainController::connections() {
  auto dfs = nodeWrapper->node->dfs();
  auto networkManager = nodeWrapper->node->network();
  auto accController = nodeWrapper->node->account_controller();
  auto actorIndex = nodeWrapper->node->actor_index();
  auto dag = nodeWrapper->node->dag();

  connect(uiController, &ClientController::connectToNode, networkManager,
          &NetworkManager::connect_to_node);
  connect(networkManager, &NetworkManager::connectionStatusChanged,
          uiController, &ClientController::setNetworkStatus);
  connect(networkManager, &NetworkManager::connectionsCountChanged,
          uiController, &ClientController::setNetworkSockets);

  connect(uiController, &ClientController::sendNotificationToken,
          nodeWrapper->node, &ExtraChainNode::notificationToken);

  connect(nodeWrapper->node, &ExtraChainNode::subscriptionAdded, uiController,
          &ClientController::subscriptionAdded);

  connect(networkManager, &NetworkManager::connectionError, this,
          [=, this](Network::SocketServiceError error, QString identifier,
                    QString erroData) {
            switch (error) {
            case Network::SocketServiceError::IncompatibleNetwork:
              emit wipeData(1, "<b>Network incompatibility</b>",
                            "Please download the updated client from "
                            "<b>extrachain.com</b><br><br>Click "
                            "<b>OK</b> to "
                            "open the website.");
              break;
            case Network::SocketServiceError::VersionTooOld:
              emit wipeData(2, "<b>Update Required</b>",
                            "Please download the latest version from "
                            "<b>extrachain.com</b><br><br>Click "
                            "<b>OK</b> to "
                            "open the website.");
              break;
            case Network::SocketServiceError::VersionTooNew:
              emit wipeData(3, "<b>Version Mismatch</b>",
                            "Your node version is newer than the other node "
                            "supports. Please wait for the node "
                            "to be updated or use an older client version from "
                            "<b>extrachain.com</b><br><br>"
                            "Click <b>OK</b> to open the website.");
              break;
            default:
              break;
            }
          });

  connect(uiController->getWelcomePage(), &WelcomePage::regStarted,
          [=, this](QByteArray hash) {
            auto profile =
                nodeWrapper->node->account_controller()->create_profile(
                    hash.toStdString(), ActorType::User);
            uiController->userRegistrationCompletion(
                profile.actors().front().id(), true);
          });

  connect(nodeWrapper->node, &ExtraChainNode::dagSyncFinish, this,
          &ExtraChainController::dagSyncFinish);
  connect(nodeWrapper->node, &ExtraChainNode::dagControlStarted, this,
          &ExtraChainController::dagControlStarted);
  connect(nodeWrapper->node, &ExtraChainNode::dagControlEnded, this,
          &ExtraChainController::dagControlEnded);
  connect(nodeWrapper->node, &ExtraChainNode::dagSearchControlStarted, this,
          &ExtraChainController::dagSearchControlStarted);
  connect(nodeWrapper->node, &ExtraChainNode::dagSearchControlEnded, this,
          &ExtraChainController::dagSearchControlEnded);

  connect(
      nodeWrapper->node, &ExtraChainNode::dagTxApproved, this,
      [=, this](SectionId section_id, std::string hash) {
        if (!nodeWrapper->node->dag()->sended_transactions().contains(hash)) {
          return;
        }

        auto transaction =
            nodeWrapper->node->dag()->sended_transactions()[hash];
        if (!transaction.is_empty() &&
            transaction.type() != TransactionType::Reward)
          emit dagTxApproved(QString::fromStdString(hash));
      });
  connect(nodeWrapper->node, &ExtraChainNode::dagTxNotApproved, this,
          [=, this](SectionId section_id, std::string hash) {
            auto transaction =
                nodeWrapper->node->dag()->failed_transactions()[hash];
            if (!transaction.is_empty() &&
                transaction.type() != TransactionType::Reward)
              emit dagTxNotApproved(QString::fromStdString(hash));
          });
  connect(
      nodeWrapper->node, &ExtraChainNode::dagTxSended, this,
      [=, this](SectionId section_id, std::string hash) {
        if (!nodeWrapper->node->dag()->sended_transactions().contains(hash)) {
          return;
        }

        auto transaction =
            nodeWrapper->node->dag()->sended_transactions()[hash];
        if (!transaction.is_empty() &&
            transaction.type() != TransactionType::Reward)
          emit dagTxSended(QString::fromStdString(hash));
      });

  connect(nodeWrapper->node->actor_index(), &ActorIndex::firstSyncStarted, this,
          &ExtraChainController::actorsStarted);
  connect(nodeWrapper->node->actor_index(), &ActorIndex::firstSyncEnded, this,
          &ExtraChainController::actorsEnded);
  connect(nodeWrapper->node->actor_index(), &ActorIndex::firstSyncProgress,
          this, &ExtraChainController::actorsProgress);

  connect(nodeWrapper->node->token_manager(),
          &TokenManager::errorNameTokenExist, this,
          &ExtraChainController::errorNameTokenExist);
  connect(nodeWrapper->node->token_manager(),
          &TokenManager::errorTickerTokenExist, this,
          &ExtraChainController::errorSymbolTokenExist);
  connect(nodeWrapper->node->token_manager(), &TokenManager::added, this,
          &ExtraChainController::addedToken);

  QObject::connect(
      nodeWrapper->node->dfs(), &DfsController::downloaded,
      [this](ActorId owner_id, Dfs::DirRow dirRow) {
        auto network_id = nodeWrapper->node->actor_index()->network_id();
        auto extrachain_id =
            ActorId("46710a2d823c23db9fc2ac01e0f84212a8128373");

        if (owner_id == network_id && dirRow.folder.has_value() &&
            dirRow.folder.value() == Dfs::Basic::TEMPLATE_VECTOR &&
            dirRow.name == "Usernames") {
          auto main_id = nodeWrapper->node->account_controller()
                             ->current_profile()
                             .main_id();
          uiController->loadUserName(main_id.toQString());
        }

        if (owner_id == extrachain_id && dirRow.folder.has_value() &&
            dirRow.folder.value() == Dfs::Basic::TEMPLATE_VECTOR &&
            dirRow.name == "ExtrachainSubscription") {
          uiController->loadSubscription();
        }
      });

  QObject::connect(walletUiController, &WalletUIController::notificationTx,
                   notificationController,
                   &NotificationController::newTransactionForNotification);

  connect(nodeWrapper->node, &ExtraChainNode::actorRenamed, walletUiController,
          &WalletUIController::renamedWallet);
  connect(nodeWrapper->node, &ExtraChainNode::actorRenamedLoaded,
          walletUiController, &WalletUIController::renamesLoad);
}

void ExtraChainController::availableFullModeInit() {
  auto bytesAvailable = Utils::diskAvailableMemory();
  double gbAvailable =
      static_cast<double>(bytesAvailable) / (1024.0 * 1024.0 * 1024.0);

  _availableGB = QString::number(gbAvailable, 'f', 2);

  if (gbAvailable < FULL_DAG_MODE_MIN_SIZE) {
    eInfo("Warning: available only {} GB, set Dag and Dfs to light mode",
          gbAvailable);
    nodeWrapper->node->dag()->set_mode(DagMode::Light);
    // nodeWrapper->node->dfs()->set_mode(DfsMode::Light);
    _isAvailbaleFullMode = false;
  } else if (gbAvailable < FULL_DAG_MODE_AND_DFS_MIN_SIZE) {
    // eInfo("Warning: available only {} GB, set Dfs to full mode",
    // gbAvailable); nodeWrapper->node->dfs()->set_mode(DfsMode::Full);
    _isAvailbaleFullMode = true;
  }

  emit isAvailbaleFullModeChanged();
  emit availableGBChanged();
}

void ExtraChainController::sendTransactionFromUi(ActorId reciever,
                                                 BigNumberFloat actor,
                                                 ActorId token) {}

void ExtraChainController::addNewWallet(const QString &nameWallet) {
  auto future = QtConcurrent::run([=, this] {
    auto actor = nodeWrapper->node->account_controller()->create_wallet(
        ActorId(), nameWallet.toStdString());
    auto walletId = actor.id().toQString();
    walletUiController->addWallet(actor.id(), nameWallet);
    eLog("Wallet created");
  });
  future.then([this] {
    eLog("Wallet created");
    emit walletCreated();
  });
}

void ExtraChainController::createTx(const QString &walletTo,
                                    const QString &coinName,
                                    const QString &amount,
                                    const QString &newtwork) {
  eLog("{} {} {} {}", __FUNCTION__, walletTo, coinName, amount);
  if (walletTo.isEmpty() || coinName.isEmpty() || amount.isEmpty()) {
    QString paremError = walletTo.isEmpty()   ? "Wallet address is empty."
                         : coinName.isEmpty() ? "Coin name error."
                                              : "Amount empty.";

    emit createTxError(paremError);
    return;
  }

  auto mainActor = nodeWrapper->node->account_controller()->system_actor();
  Transaction tx;
  tx.set_sender(mainActor.id());
  tx.set_receiver(ActorId(walletTo.toStdString()));
  tx.set_amount(BigNumberFloat(amount.toStdString(), NumeralBase::Dec));

  std::expected<Transaction, TransactionError> createdTx =
      nodeWrapper->node->create_transaction(tx);

  if (!createdTx.has_value()) {
    auto error =
        nodeWrapper->node->transaction_error_description(createdTx.error());
    emit failedTxCreate(QString::fromStdString(error));
  } else {
    nodeWrapper->node->send_transaction(tx, mainActor);
    emit sendedTx();
  }
}

void ExtraChainController::sendTx(const QString &walletFrom,
                                  const QString &walletTo,
                                  const QString &coinName,
                                  const QString &amount,
                                  const QString &network) {
  eLog(
      "ui sendTx. from: '{}', to '{}', coin: '{}', amount: '{}', network: '{}'",
      walletFrom, walletTo, coinName, amount, network);
  if (walletTo.isEmpty() || coinName.isEmpty() || amount.isEmpty() ||
      walletFrom.isEmpty()) {
    QString paremError = walletTo.isEmpty()   ? "Wallet address is empty."
                         : coinName.isEmpty() ? "Coin name error."
                                              : "Amount empty.";

    emit createTxError(paremError);
    return;
  }

  TokenManager tm(nodeWrapper->node);
  // auto         map = tm.mapTokens();
  // if (map.empty() || !map.contains(coinName))
  auto existActor = nodeWrapper->node->actor_index()->exists(
      ActorId(walletTo.trimmed().toStdString()));
  if (!existActor) {
    emit failedTxCreate(
        "User " + walletTo +
        " not found.\nEnsure that the username is correct and try again.");
    return;
  }

  Transaction tx;
  tx.set_sender(ActorId(walletFrom.trimmed().toStdString()));
  tx.set_receiver(ActorId(walletTo.trimmed().toStdString()));
  tx.set_amount(BigNumberFloat(amount.toStdString(), NumeralBase::Dec));
  tx.set_token(ActorId("468faf2f1be6504a9a26f7f027f7e43380b0d77d"));

  auto createdTx = nodeWrapper->node->create_transaction(tx);

  if (!createdTx.has_value()) {
    auto error =
        nodeWrapper->node->transaction_error_description(createdTx.error());
    emit failedTxCreate(QString::fromStdString(error));
  } else {
    auto signer =
        nodeWrapper->node->account_controller()->current_profile().get_actor(
            ActorId(walletFrom.toStdString()));
    if (!signer.has_value()) {
      emit failedTxCreate(QString::fromStdString("No wallet"));
      return;
    }
    auto result = nodeWrapper->node->send_transaction(tx, signer.value().get());
    if (result.has_value()) {
      emit sendedTx();
    } else {
      emit failedTxCreate(QString::fromStdString("NoLastBlock"));
    }
  }
}

bool ExtraChainController::isAvailbaleFullMode() const {
  return _isAvailbaleFullMode;
}

double ExtraChainController::fullDagModeMinSize() const {
  return FULL_DAG_MODE_MIN_SIZE;
}

QString ExtraChainController::availableGB() const { return _availableGB; }

void ExtraChainController::closeApp() const {
  std::thread([] {
    std::this_thread::sleep_for(std::chrono::seconds(5));
    std::exit(0);
  }).detach();

  qApp->exit();
}
