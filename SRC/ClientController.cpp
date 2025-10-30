#include "ClientController.h"

#include <QCoreApplication>
#include <QStandardPaths>
#include <QThreadPool>
#include <QTranslator>

#include "chain/actor_index.h"
#include "chain/dag.h"
#include "chat/chat_manager.h"
#include "managers/extrachain_node.h"
#include "network/isocket_service.h"
#include "network/network_manager.h"

#include "file_downloader.h"

ClientController::ClientController(QObject *parent)
    : QObject(parent), updater(this) {
  // wallet = std::make_shared<WalletController>();
  welcomePage = std::make_shared<WelcomePage>();
  m_autologinHash.load();
  connectSignals();
}

ClientController::~ClientController() { eLog("Run ~ClientController()"); }

// WalletController *ClientController::getWallet() { return wallet.get(); }

WelcomePage *ClientController::getWelcomePage() const {
  return welcomePage.get();
}

QString ClientController::myId() { return currentActorId.toQString(); }

void ClientController::connectSignals() {
  // TODO: move to UC
  // registration
  connect(welcomePage.get(), &WelcomePage::logInStarted, this,
          &ClientController::logIn);
  connect(welcomePage.get(), &WelcomePage::autoLogInStarted, this,
          &ClientController::autoLogIn);
  // connect(this, &ClientController::authEnded, wallet.get(),
  //         &WalletController::updateWallet);
  connect(this, &ClientController::authEnded, [this](bool status, int type) {
    Q_UNUSED(status)
    Q_UNUSED(type)

    QFile file("top-secret");

    if (file.open(QFile::ReadOnly)) {
      QString token = file.readAll().replace(" ", "").trimmed();
      file.close();
      emit this->sendNotificationToken(QSysInfo::productType(), this->myId(),
                                       token);
    }
  });

  connect(this, &ClientController::sendProfile, [this]() {
    emit profileChanged(currentProfile);
    emit saveProfile(currentProfile.list());
  });
}

void ClientController::addAvatar(QString imageFile, bool temp, const int x,
                                 const int y, const int size) {
  const int avaSize = 200;
  eLog("addingAvatar {} {} {} {} {}", currentActorId.toQByteArray(),
       QUrl(imageFile).toLocalFile(), x, y, size);

  QImageReader reader(QUrl(imageFile).toLocalFile());
  reader.setAutoTransform(true);
  QImage originalImage = reader.read();
  QSize originalSize = originalImage.size();

  QImage image = originalImage.copy(x, y, size, size);
  originalImage = QImage();
  image = image.scaled(avaSize, avaSize);
  QImage out(image.width(), image.height(), QImage::Format_ARGB32);
  out.fill(Qt::transparent);
  QPainter painter(&out);

  painter.setRenderHint(QPainter::SmoothPixmapTransform);
  painter.setRenderHint(QPainter::Antialiasing);

  QPen pen;
  pen.setStyle(Qt::NoPen);
  painter.setPen(pen);
  QBrush brush(image);

  painter.setBrush(brush);

  qreal radius = avaSize / 2;
  painter.drawRoundedRect(QRectF(0, 0, avaSize, avaSize), radius, radius);

  QPixmap pxDst(originalSize);
  pxDst.fill(Qt::transparent);
  QPainter painter2(&pxDst);

  QStringList avatars = currentProfile.avatar();
  auto file = temp ? imageFile : QUrl(imageFile).toLocalFile();
  avatars.insert(
      0, QString::fromStdString(Utils::calculate_hash_file(
                                    FsPath::create(file.toStdString()).value())
                                    .value()));
  currentProfile.setAvatar(avatars);
  QTimer::singleShot(1000,
                     [this]() { emit this->updateAvatarImage(); }); // TODO

  emit sendProfile();
}

bool ClientController::networkStatus() const { return m_networkStatus; }

enum class ImageResult { Done, DoneNoScale, TooBig, CantRead };

ImageResult prepareImage(const QString &fileName, const QString &tmpName) {
  static const int imageSize = 1150;
  QImage image(fileName);

  if (image.isNull()) {
    QImageReader reader(fileName);
    if (reader.canRead())
      return ImageResult::TooBig;
    else
      return ImageResult::CantRead;
  }

  bool isScaled = false;
  int fileSize = QFileInfo(fileName).size() / 1000;
  if (fileSize > 500 &&
      (image.rect().width() > imageSize || image.rect().height() > imageSize)) {
    image = image.scaled(imageSize, imageSize, Qt::KeepAspectRatio);
    isScaled = image.save(tmpName + "_scaled.jpg");
  }

  QImage toBlur = image.scaled(350, 350);
  QImage imageBlurred = EtUtils::blur(toBlur, 100);
  imageBlurred.save(tmpName + "_blurred.jpg", "jpg");

  return isScaled ? ImageResult::Done : ImageResult::DoneNoScale;
}

bool ClientController::prepareMediaForPostsEvents(QVariantMap &map) {
  auto files = map["images"].toList();
  QVariantList edited;

  QStringList iSize;

  for (const QVariant &file : files) {
    auto fileMap = file.toMap();
    QString image = fileMap["file"].toString();
    QString type = fileMap["type"].toString();
    QString originalImage = QUrl(image).toLocalFile();
    fileMap["file"] = QString::fromStdString(
        Utils::calculate_hash_file(
            FsPath::create(originalImage.toStdString()).value())
            .value());

    if (type == "video") {
      originalImage =
          originalImage.replace(QString::fromStdWString(Utils::filePrefix), "");
      fileMap["file"] = QString::fromStdString(
          Utils::calculate_hash_file(
              FsPath::create(originalImage.toStdString()).value())
              .value());
      edited << fileMap;
      iSize << QString("%1 500 500").arg(QFileInfo(originalImage).size());
      // emit send(DfsStruct::DfsSave::File, originalImage, "",
      // DfsStruct::Video);
      continue;
    }

    QFile fileImage(originalImage);
    if (fileImage.open(QFile::ReadOnly)) {
      QByteArray read = fileImage.read(3);
      fileImage.close();

      if (read == "GIF") {
        fileMap["type"] = "gif";
        // TODO: convert to mp4
        edited << fileMap;
        // emit send(DfsStruct::DfsSave::File, originalImage, "",
        // DfsStruct::Image);
        continue;
      }
    }

    QImageReader imageReader(originalImage);
    imageReader.setAutoTransform(true);

    if (imageReader.canRead()) {
      auto size = imageReader.size();
      auto trans = imageReader.transformation();
      bool isRotate90 =
          trans == QImageIOHandler::TransformationRotate90 ||
          trans == QImageIOHandler::TransformationMirrorAndRotate90 ||
          trans == QImageIOHandler::TransformationFlipAndRotate90;
      QString toISize = !isRotate90 ? "%3 %1 %2" : "%3 %2 %1";
      iSize << toISize.arg(size.width())
                   .arg(size.height())
                   .arg(QFileInfo(originalImage).size());
    }

    // TODO: return to ui: can't add image
    QString randName =
        QString("tmp/%1").arg(Utils::generate_random_hex(50).c_str());
    auto res = prepareImage(originalImage, randName);
    switch (res) {
    case ImageResult::Done:
      //            emit send(DfsStruct::DfsSave::File, randName +
      //            "_blurred.jpg", "", DfsStruct::Image);
      break;
    case ImageResult::DoneNoScale:
      //            emit send(DfsStruct::DfsSave::File, randName +
      //            "_scaled.jpg", "", DfsStruct::Image); emit
      //            send(DfsStruct::DfsSave::File, randName + "_blurred.jpg",
      //            "", DfsStruct::Image);
      break;
    case ImageResult::TooBig:
      // return false; and add file name
    case ImageResult::CantRead:
      // return false;
      break;
    }

    edited << fileMap;
    //        emit send(DfsStruct::DfsSave::File, originalImage, "",
    //        DfsStruct::Image);
  }

  map["images"] = edited;
  map["isize"] = iSize;
  return true;
}

void ClientController::setEtUtils(const std::shared_ptr<EtUtils> &newEtUtils) {
  etUtils = newEtUtils;
}

QVariantList ClientController::networkConnections() {
  QVariantList connectionsList;

  auto connections = *m_node->network()->connections();
  auto adding = [&connectionsList](auto &el) {
    QVariantMap connection;
    connection["ip"] = el->ip();
    connection["port"] = el->port();
    connection["serverPort"] = el->server_port();
    connection["active"] = el->is_active();
    connection["protocol"] = el->protocol_string();
    connection["identifier"] = el->identifier();
    connection["incoming"] = el->bytes_incoming();
    connection["outgoing"] = el->bytes_outgoing();
    connection["compressed"] = el->bytes_compressed();
    connectionsList << connection;
  };

  std::for_each(connections->begin(), connections->end(), adding);

  return connectionsList;
}

void ClientController::networkConnectionRemove(const QString &identifier) {
  qDebug().noquote() << "Remove connections by" << identifier;
  m_node->network()->remove_connection(identifier);
}

bool ClientController::serverStatus(Network::Protocol protocol) const {
  return m_node->network()->server_status(protocol);
}

void ClientController::setShareUtils(const std::shared_ptr<ShareUtils> &value) {
  shareUtils = value;
}

double ClientController::appWidth() const { return m_appWidth; }

int ClientController::networkSockets() const { return m_networkSockets; }

void ClientController::addEvent(QVariantMap event) {
  eLog("UiController::addEvent");
  prepareMediaForPostsEvents(event);

  QString tmpName =
      QString("tmp/event_%1").arg(QRandomGenerator::global()->bounded(999999));

  DbRow eventDbCProp{
      {"version", "3"},
      {"sender", currentActorId.to_string()},
      {"dateCreate", event["date"].toByteArray().toStdString()},
      {"dateModify", event["date"].toByteArray().toStdString()},
      {"latitude", event["latitude"].toByteArray().toStdString()},
      {"longitude", event["longitude"].toByteArray().toStdString()},
      {"eventName", event["name"].toByteArray().toStdString()},
      {"type", event["type"].toByteArray().toStdString()},
      {"locationName", event["location"].toByteArray().toStdString()},
      {"scope", event["scope"].toByteArray().toStdString()},
      {"agreement", event["agreement"].toByteArray().toStdString()},
      {"salary", event["salary"].toByteArray().toStdString()},
      {"startEpoch", event["startEpoch"].toByteArray().toStdString()},
      {"endEpoch", event["endEpoch"].toByteArray().toStdString()},
      {"start", event["start"].toByteArray().toStdString()},
      {"end", event["end"].toByteArray().toStdString()},
      {"sign", "TODO"}};
  DbRow eventDbText{{"locale", "en"},
                    {"text", event["desc"].toByteArray().toStdString()},
                    {"sign", "TODO"}};

  auto images = event["images"].toList();
  QStringList isize = event["isize"].toStringList();

  if (images.length() != isize.length()) {
    eLog("Event image error");
    return;
  }

  for (int i = 0; i != images.length(); i++) {
    QVariantMap imagesMap = images[i].toMap();

    DbRow imRow = {{"attachId", imagesMap["file"].toString().toStdString()},
                   {"type", imagesMap["type"].toString().toStdString()},
                   {"date", event["date"].toByteArray().toStdString()},
                   {"data", isize[i].toStdString()},
                   {"sign", "TODO"}};
  }

  QString eventFile = QString::fromStdString(
      Utils::calculate_hash_file(FsPath::create(tmpName.toStdString()).value())
          .value());
}

QVariantList ClientController::tokens() {
  eLog("UiController::tokens()");
  QVariantList list;
  list << QVariantMap{{"tokenId", "00000000000000000000"},
                      {"name", "ExtraChain"},
                      {"color", "#000000"}};

  if (!QFile::exists("chain/tokens.cache"))
    return list;

  DbConnector db("chain/tokens.cache");
  auto rows = db.select("SELECT * FROM Tokens");

  for (auto &row : rows) {
    QVariantMap map;
    map["tokenId"] = QString::fromStdString(row["tokenId"]);
    map["name"] = QString::fromStdString(row["name"]);
    map["color"] = QString::fromStdString(row["color"]);
    map["staking"] = true;
    list << map;
  }

  return list;
}

QVariantMap ClientController::token(const QString &id) {
  if (id.isEmpty())
    return QVariantMap();
  if (id == "00000000000000000000")
    return QVariantMap{{"tokenId", "00000000000000000000"},
                       {"name", "ExtraChain"},
                       {"color", "#000000"}};

  DbConnector db("chain/tokens.cache");
  auto rows = db.select("SELECT * FROM Tokens WHERE tokenId = '" +
                        id.toStdString() + "'");

  if (rows.empty())
    return {};

  QVariantMap map;
  map["tokenId"] = QString::fromStdString(rows[0]["tokenId"]);
  map["name"] = QString::fromStdString(rows[0]["name"]);
  map["color"] = QString::fromStdString(rows[0]["color"]);
  map["staking"] = true;

  return map;
}

void ClientController::logOut() {
  qDebug() << "Emit signal logout";
  emit logout();
  qDebug() << "make default ";
  currentProfile = Profile();
  setAuthHash("");
  // wallet->getWalletListModel()->clearModel();
}

bool ClientController::serverError() const { return m_serverError; }

void ClientController::addPortfolio(QString image) {
  QStringList portfolio = currentProfile.portfolio();
  portfolio << QString::fromStdString(
      Utils::calculate_hash_file(FsPath::create(image.toStdString()).value())
          .value());
  currentProfile.setPortfolio(portfolio);
  emit sendProfile();
}

void ClientController::setNetworkStatus(bool networkStatus) {
  if (m_networkStatus == networkStatus)
    return;
  m_networkStatus = networkStatus;
  emit networkStatusChanged(m_networkStatus);
}

void ClientController::setProfile(Profile profile) {
  if (currentProfile == profile)
    return;

  currentProfile = profile;
  emit profileChanged(currentProfile);
}

void ClientController::setServerError(bool serverError) {
  if (m_serverError == serverError)
    return;

  m_serverError = serverError;
  emit serverErrorChanged(m_serverError);
}

void ClientController::setNetworkSockets(int networkSockets) {
  if (m_networkSockets == networkSockets)
    return;

  m_networkSockets = networkSockets;
  emit networkSocketsChanged(m_networkSockets);
}

void ClientController::setAppWidth(double appWidth) {
  if (qFuzzyCompare(m_appWidth, appWidth))
    return;

  m_appWidth = appWidth;
  emit appWidthChanged(m_appWidth);
}

void ClientController::setIsApp(bool isApp) {
  if (m_isApp == isApp)
    return;

  eLog("Is App? {}", isApp);
  m_isApp = isApp;
  emit isAppChanged(m_isApp);
}

bool ClientController::isApp() const { return m_isApp; }

QVariantMap ClientController::exportAttach(QString fileName) {
  QVariantMap result;
  fileName.replace(QString::fromStdWString(Utils::filePrefix), "");

  QImageReader reader(fileName);
  QString format = reader.format().toLower();
  if (format == "jpeg")
    format = "jpg";

  QFile file(fileName);
  QString newFileName = "Image_" +
                        QString::number(QDateTime::currentMSecsSinceEpoch()) +
                        "." + format;
  QString newFilePath =
      QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
  QDir().mkpath(newFilePath);
  bool copyRes = file.copy(newFilePath + "/" + newFileName);

  result["name"] = newFileName;
  result["path"] = newFilePath;
  result["ok"] = copyRes;

  return result;
}

void ClientController::requestQProfile(const QString &userId,
                                       QJSValue callback) {
  if (userId.length() != 20 || userId == "00000000000000000000")
    return;

  if (qProfileCallbacks[userId].isEmpty()) {
    qProfileCallbacks.insert(userId, {callback});
  } else {
    qProfileCallbacks[userId] << callback;
  }
}

Profile ClientController::profile() const { return currentProfile; }

bool ClientController::needWipe() { return m_needWipe; }

void ClientController::setNeedWipe(bool needWipe) { m_needWipe = needWipe; }

void ClientController::userRegistrationCompletion(ActorId userId, bool isUser) {
  if (!isUser)
    return;

  eLog("userRegistrationCompletion {} {}", userId, isUser);
  currentActorId = m_node->account_controller()->system_actor().id();
  QByteArray currentActorIdByte = currentActorId.toQByteArray();
  currentProfile.setUserId(currentActorIdByte);
  // wallet->setCurrentWallets({currentActorIdByte});
  emit sendProfile();

  regDone = false;
}

void ClientController::logIn() {
  auto result = m_node->login(welcomePage->email().toStdString(),
                              welcomePage->password().toStdString());

  if (!result.has_value() && result.error() == LoadError::Multiple) {
    emit loginError(2);
    return;
  }

  loginHandler(result.has_value());
}

void ClientController::autoLogIn() {
  auto result = m_node->login(welcomePage->getHash().toStdString());

  if (!result.has_value() && result.error() == LoadError::Multiple) {
    emit loginError(2);
    return;
  }

  loginHandler(result.has_value());
}

QVariantList ClientController::multipleProfiles() {
  auto hash = Utils::calculate_hash(
      (welcomePage->email() + welcomePage->password()).toStdString());

  if (!welcomePage->hash().isEmpty() &&
      (welcomePage->email().isEmpty() || welcomePage->password().isEmpty())) {
    hash = welcomePage->hash().toStdString();
  }

  auto multiple_profiles =
      m_node->account_controller()->multiple_profiles(hash);

  QVariantList qlist;
  for (const auto &actor_id : multiple_profiles) {
    qlist << QString::fromStdString(actor_id.to_string());
  }
  return qlist;
}

void ClientController::logInTo(const QString &actorId) {
  auto hash = Utils::calculate_hash(
      (welcomePage->email() + welcomePage->password()).toStdString());

  if (!welcomePage->hash().isEmpty() &&
      (welcomePage->email().isEmpty() || welcomePage->password().isEmpty())) {
    hash = welcomePage->hash().toStdString();
  }

  auto actor_id = ActorId(actorId.toStdString());
  bool result =
      m_node->account_controller()->load_profile(actor_id, hash, std::nullopt);
  loginHandler(result);
}

void ClientController::loginHandler(bool loginResult) {
  if (loginResult) {
    auto main = m_node->account_controller()->system_actor().id();
    auto actors = m_node->account_controller()->profile(main).actors();
    QByteArrayList idList;
    for (auto &actor : actors) {
      idList << actor.id().toQByteArray();
    }
    loginPrivateProfile(main.toQByteArray(), idList);
  } else {
    if (AccountController::profiles_list().size() != 0) {
      eLog("Error: Incorrect login or password");
      emit loginError(0);
    } else {
      eLog("Error: No profiles files");
      emit loginError(1);
    }
  }
}

void ClientController::loginPrivateProfile(QByteArray id,
                                           QByteArrayList idList) {
  currentActorId = id.toStdString();
  emit requestProfile(currentActorId.toQByteArray());
  // wallet->setCurrentWallets(idList);
  QTimer::singleShot(500, this, [this] {
    m_node->network()->connect_to_node(etUtils->serverIp(),
                                       Network::Protocol::WebSocket);
    // (etUtils->serverIp(), etUtils->networkProtocol());
  });

  emit authStatus(2, authType);

  // if (waitingFiles.isEmpty()) {
  emit authEnded(true, 3);
  authDone = true;
  // } else {
  // emit iWantMyServiceAndPrivateQuickly();
  // }
}

void ClientController::loadInfo(const QByteArray &info,
                                const QString &value) // pr profile getter
{
  Q_UNUSED(info)
  Q_UNUSED(value)
}

void ClientController::profileRe(QString userId, Profile profile) {
  QStringList avatarList = profile.avatar();
  QString avatar = avatarList.length() ? avatarList[0] : "";

  auto list = qProfileCallbacks[userId];
  // for (auto &&el : list)
  //     el.call(QJSValueList { qProfile.firstName + " " + qProfile.lastName,
  //     qProfile.firstName,
  //                          qProfile.lastName, qProfile.avatar });
  qProfileCallbacks.remove(userId);

  if (userId == currentActorId.toQByteArray())
    setProfile(profile);
}

void ClientController::newNotification(Notification ntf) {
  emit notify(ntf.data.left(20), ntf.type);
}

// void ClientController::onWebSocketError(Network::SocketServiceError error,
// QString identifier)
//{
//    eLog("[Client] Error WS: {} {}", error, identifier);
//}

void ClientController::blockDfs() {
  //    QFile file(DfsStruct::ROOT_FOOLDER_NAME + "/" +
  //    currentActorId.toByteArray() + "/services/blocked");
  //    file.open(QFile::WriteOnly);
  //    file.write(currentActorId.toByteArray());
  //    file.close();

  //    emit send(DfsStruct::DfsSave::Static, "blocked", "",
  //    DfsStruct::Service);
}

void ClientController::needProfile(const QString &userId) {
  if (profilesCache[userId].userId().isEmpty()) {
    eLog("---------------- Start future2 {}", userId);
    eLog("{}", userId);
  } else {
    emit profilePageUpdated(userId, profilesCache[userId]);
  }
}

void ClientController::like(QString userId, QString postId, bool isRemove,
                            bool isPost) {
  //    eLog("Likes {} {} {}", userId, postId, isRemove);

  //    auto contentHash =
  //        Utils::calcKeccak(userId.toLatin1() + postId.toLatin1() +
  //        myId().toLatin1()).toStdString();
  //    QByteArray sign =
  //        QByteArray::fromStdString(m_node->accountController()->mainActor().key().sign(contentHash));

  //    if (isRemove)
  //        emit sendEditSql(userId, postId.right(2) + "/" + postId + ".likes",
  //                         isPost ? DfsStruct::Type::Post :
  //                         DfsStruct::Type::Event, DfsStruct::Delete, {
  //                         Config::DataStorage::likesTableName.c_str(),
  //                         "userId", myId().toLatin1() });
  //    else
  //        emit sendEditSql(
  //            userId, postId.right(2) + "/" + postId + ".likes",
  //            isPost ? DfsStruct::Type::Post : DfsStruct::Type::Event,
  //            DfsStruct::Insert, {
  //            Config::DataStorage::likesTableName.c_str(), "userId",
  //            myId().toLatin1(), "sign", sign });

  //    auto mainActor = m_node->accountController()->mainActor().key();
  //    if (isPost)
  //        emit sendEditSql(currentActorId.toByteArray(), "likes",
  //        DfsStruct::Type::Private,
  //                         isRemove ? DfsStruct::Delete : DfsStruct::Insert,
  //                         { Config::DataStorage::savedPostsTableName.c_str(),
  //                         "user",
  //                           QByteArray::fromStdString(mainActor.encryptSelf(userId.toStdString())),
  //                           "post",
  //                           QByteArray::fromStdString(mainActor.encryptSelf(postId.toStdString()))
  //                           });
  //    else
  //        emit sendEditSql(currentActorId.toByteArray(), "likes",
  //        DfsStruct::Type::Private,
  //                         isRemove ? DfsStruct::Delete : DfsStruct::Insert,
  //                         {
  //                         Config::DataStorage::savedEventsTableName.c_str(),
  //                         "user",
  //                           QByteArray::fromStdString(mainActor.encryptSelf(userId.toStdString())),
  //                           "event",
  //                           QByteArray::fromStdString(mainActor.encryptSelf(postId.toStdString()))
  //                           });
}

void ClientController::likeComment(QString userId, QString postId,
                                   QString commentId, bool isRemove,
                                   bool isPost) {
  //    auto contentHash =
  //        Utils::calcKeccak(userId.toLatin1() + postId.toLatin1() +
  //        commentId.toLatin1() + myId().toLatin1())
  //            .toStdString();
  //    QByteArray sign =
  //        QByteArray::fromStdString(m_node->accountController()->mainActor().key().sign(contentHash));

  //    if (isRemove)
  //        emit sendEditSql(userId, postId.right(2) + "/" + postId +
  //        ".comments",
  //                         isPost ? DfsStruct::Type::Post :
  //                         DfsStruct::Type::Event, DfsStruct::Delete, {
  //                         Config::DataStorage::likesTableName.c_str(),
  //                         "commentId", commentId.toLatin1(),
  //                           "userId", myId().toLatin1() });
  //    else
  //        emit sendEditSql(userId, postId.right(2) + "/" + postId +
  //        ".comments",
  //                         isPost ? DfsStruct::Type::Post :
  //                         DfsStruct::Type::Event, DfsStruct::Insert, {
  //                         Config::DataStorage::likesTableName.c_str(),
  //                         "commentId", commentId.toLatin1(),
  //                           "userId", myId().toLatin1(), "sign", sign });
}

void ClientController::mark(QString userId, QString postId, bool isRemove,
                            bool isPost) {
  //     auto mainActor = m_node->accountController()->mainActor().key();
  //     if (isPost)
  //         emit sendEditSql(currentActorId.toByteArray(), "saved",
  //         DfsStruct::Type::Private,
  //                          isRemove ? DfsStruct::Delete : DfsStruct::Insert,
  //                          {
  //                          Config::DataStorage::savedPostsTableName.c_str(),
  //                          "user",
  //                            QByteArray::fromStdString(mainActor.encryptSelf(userId.toStdString())),
  //                            "post",
  //                            QByteArray::fromStdString(mainActor.encryptSelf(postId.toStdString()))
  //                            });
  //     else
  //         emit sendEditSql(currentActorId.toByteArray(), "saved",
  //         DfsStruct::Type::Private,
  //                          isRemove ? DfsStruct::Delete : DfsStruct::Insert,
  //                          {
  //                          Config::DataStorage::savedEventsTableName.c_str(),
  //                          "user",
  //                            QByteArray::fromStdString(mainActor.encryptSelf(userId.toStdString())),
  //                            "event",
  //                            QByteArray::fromStdString(mainActor.encryptSelf(postId.toStdString()))
  //                            });
}

void ClientController::postComment(QString commentId, QString userId,
                                   QString postId, QString text, QString sub,
                                   bool isPost) {
  auto contentHash = Utils::calculate_hash(
      userId.toStdString() + postId.toStdString() + commentId.toStdString() +
      myId().toStdString() + text.toStdString() + sub.toStdString());
  // QByteArray sign = QByteArray::fromStdString(
  // m_node->accountController()->mainActor()->key().sign(contentHash));

  //    emit sendEditSql(userId, postId.right(2) + "/" + postId + ".comments",
  //                     isPost ? DfsStruct::Type::Post :
  //                     DfsStruct::Type::Event, DfsStruct::Insert, {
  //                     Config::DataStorage::commentsTableName.c_str(),
  //                     "commentId", commentId.toLatin1(),
  //                       "message", text.toUtf8(), "sender",
  //                       myId().toLatin1(), "date",
  //                       QByteArray::number(QDateTime::currentMSecsSinceEpoch()),
  //                       "sub", sub.toLatin1(), "sign", sign });
}

int ClientController::updateLikesTemp(QString userId, QString postId,
                                      bool isPost) { // TODO: dfs changes signal
  //    QString filePath = CardManager::buildPathForFile(userId.toStdString(),
  //    postId.toStdString() +
  //    ".likes",
  //                                                     isPost ?
  //                                                     DfsStruct::Type::Post :
  //                                                     DfsStruct::Type::Event)
  //                           .c_str();
  //    if (!QFile::exists(filePath))
  //        return 0;
  //    DBConnector db(filePath.toStdString());
  //    auto mapLikedCount = db.select("SELECT COUNT() FROM Likes");
  //    if (mapLikedCount.empty())
  //        return -1;
  //    if (mapLikedCount[0].empty())
  //        return -1;
  //    return QString(mapLikedCount[0]["COUNT()"].c_str()).toInt();
  return -1;
}

QVariantList ClientController::loadCommentsTemp(QString userId, QString postId,
                                                bool isPost) {
  //    QString filePath = CardManager::buildPathForFile(userId.toStdString(),
  //    postId.toStdString() +
  //    ".comments",
  //                                                     isPost ?
  //                                                     DfsStruct::Type::Post :
  //                                                     DfsStruct::Type::Event)
  //                           .c_str();

  //    if (!QFile::exists(filePath))
  //        return {};

  //    DBConnector db(filePath.toStdString());
  //    auto mapSql = db.select("SELECT * FROM Comments ORDER BY date");

  //    QVariantList comments;
  //    for (auto &el : mapSql) {
  //        QVariantMap map;

  //        for (auto &[key, value] : el)
  //            map[QString::fromStdString(key)] =
  //            QString::fromStdString(value);

  //        // likes
  //        std::string commentId = el["commentId"];
  //        DBConnector dbLikes(filePath.toStdString());
  //        QString queryLikes = QString("SELECT * FROM Likes WHERE commentId =
  //        '%1' AND userId = '%2'")
  //                                 .arg(commentId.c_str(), QString(myId()));
  //        bool liked = dbLikes.select(queryLikes.toStdString()).size() > 0;
  //        int count = db.count("Likes", "commentId = '" + commentId + "'");

  //        map["liked"] = liked;
  //        map["likes"] = count;
  //        comments << map;
  //    }

  //    return comments;
  return {};
}

QVariantList ClientController::loadCommentsLikesTemp(QString userId,
                                                     QString postId,
                                                     QString commentId,
                                                     bool isPost) {
  //    QString filePath = CardManager::buildPathForFile(userId.toStdString(),
  //    postId.toStdString() +
  //    ".comments",
  //                                                     isPost ?
  //                                                     DfsStruct::Type::Post :
  //                                                     DfsStruct::Type::Event)
  //                           .c_str();

  //    if (!QFile::exists(filePath))
  //        return {};

  //    DBConnector db(filePath.toStdString());
  //    auto mapSql = db.select("SELECT userId FROM Likes");

  //    QVariantList likes;
  //    for (auto &el : mapSql) {
  //        likes << QString::fromStdString(el["userId"]);
  //    }

  //    return likes;
  return {};
}

QVariantList ClientController::loadLikesTemp(QString userId, QString postId,
                                             bool isPost) {
  //    QString filePath = CardManager::buildPathForFile(userId.toStdString(),
  //    postId.toStdString() +
  //    ".likes",
  //                                                     isPost ?
  //                                                     DfsStruct::Type::Post :
  //                                                     DfsStruct::Type::Event)
  //                           .c_str();

  //    if (!QFile::exists(filePath))
  //        return {};

  //    DBConnector db(filePath.toStdString());
  //    auto mapSql = db.select("SELECT userId FROM Likes");

  //    QVariantList likes;
  //    for (auto &el : mapSql) {
  //        likes << QString::fromStdString(el["userId"]);
  //    }

  //    return likes;
  return {};
}

bool ClientController::isFirst(const QString &userId) {
  auto firstId = m_node->actor_index()->network_id();
  return firstId.toQByteArray() == userId;
}

QVariantList ClientController::chatOwners() {
  //    QVariantList list;

  //    QString filePath = DfsStruct::ROOT_FOOLDER_NAME + "/" +
  //    currentActorId.toByteArray() +
  //    "/private/chats";

  //    if (!QFile::exists(filePath))
  //        return {};

  //    auto mainActor = m_node->accountController()->mainActor().key();
  //    DBConnector DB(filePath.toStdString());
  //    std::vector<DBRow> chats = DB.select("SELECT * FROM " +
  //    Config::DataStorage::chatIdTableName);

  //    for (DBRow &row : chats) {
  //        QString chatId =
  //        QString::fromStdString(mainActor.decryptSelf(row["chatId"]));
  //        QString owner =
  //        QString::fromStdString(mainActor.decryptSelf(row["owner"]));

  //        QVariantMap map = { { "chatId", chatId }, { "owner", owner } };
  //        list << map;
  //    }

  //    return list;
  return {};
}

QString ClientController::myUsername() { return usernameById(myId()); }

int ClientController::editUsername(const QString &username) {
  auto firstId = m_node->actor_index()->network_id();
  if (firstId.is_zero())
    return 1;

  //    QString file = QString(DfsStruct::ROOT_FOOLDER_NAME +
  //    "/%1/services/usernames").arg(firstId.toString()); if
  //    (!QFile::exists(file))
  //        return 1;

  //    if (username.isEmpty()) {
  //        emit sendEditSql(firstId.toString(), "usernames",
  //        DfsStruct::Type::Service, DfsStruct::Delete,
  //                         { Config::DataStorage::userNameTableName.c_str(),
  //                         "actorId", myId().toLatin1()
  //                         });
  //        return true;
  //    }

  //    QString idByUserName = idByUsername(username);
  //    if (idByUserName != "null") {
  //        if (idByUserName == myId())
  //            return 2;
  //        return 3;
  //    }

  //    auto hash = Utils::calcKeccak(myId().toLatin1() +
  //    username.toLatin1()).toStdString(); QByteArray sign =
  //    QByteArray::fromStdString(m_node->accountController()->mainActor().key().sign(hash));
  //    QByteArrayList list = { Config::DataStorage::userNameTableName.c_str(),
  //                            "actorId",
  //                            myId().toLatin1(),
  //                            "username",
  //                            username.toLatin1(),
  //                            "sign",
  //                            sign };
  //    emit sendEditSql(firstId.toString(), "usernames",
  //    DfsStruct::Type::Service, DfsStruct::Update, list);
  return 0;
}

QString ClientController::usernameById(const QString &userId) {
  auto firstId = m_node->actor_index()->network_id();
  if (firstId.is_zero())
    return "null";

  //    QString file = QString(DfsStruct::ROOT_FOOLDER_NAME +
  //    "/%1/services/usernames").arg(firstId.toString()); if
  //    (!QFile::exists(file))
  //        return "null";

  //    DBConnector db(file.toStdString());
  //    auto res = db.select("SELECT username FROM " +
  //    Config::DataStorage::userNameTableName
  //                         + " WHERE actorId = '" + userId.toStdString() +
  //                         "'");
  //    db.close();

  //    if (res.empty())
  //        return "null";

  //    return QString::fromStdString(res[0]["username"]);
  return "";
}

QString ClientController::idByUsername(const QString &username) {
  //    auto firstId = m_node->actorIndex()->firstId();
  //    if (firstId.isEmpty())
  //        return "null";

  //    QString file = QString(DfsStruct::ROOT_FOOLDER_NAME +
  //    "/%1/services/usernames").arg(firstId.toString()); if
  //    (!QFile::exists(file))
  //        return "null";

  //    DBConnector db(file.toStdString());
  //    auto res = db.select("SELECT actorId FROM " +
  //    Config::DataStorage::userNameTableName
  //                         + " WHERE username = '" + username.toStdString() +
  //                         "' COLLATE NOCASE");
  //    db.close();

  //    if (res.empty())
  //        return "null";

  //    return QString::fromStdString(res[0]["actorId"]);
  return "";
}

// QVariantMap ClientController::tx(QString hash, QString token) {
//   QVariantMap tx;

//   auto [transaction, blockId] = m_node->blockchain()->getTransaction(
//       SearchEnum::TxParam::Hash, hash.toLatin1(),
//       ActorId(token.toStdString()));
//   std::string data   = transaction.data();
//   bool        incoma = transaction.sender() !=
//   wallet->getCurrentWalletId().toStdString();

//   tx["date"]          = transaction.date();
//   tx["amount"]        = QString(transaction.amount().toByteArray());
//   tx["amountDec"]     =
//   QString(transaction.amount().toByteArray(NumeralBase::Dec));
//   tx["amountVisible"] =
//   QString(transaction.amount().toByteArray(NumeralBase::Dec)); tx["data"] =
//   QString::fromStdString(data); tx["token"]         =
//   QString(transaction.token().toByteArray()); tx["sender"]        =
//   QString(transaction.sender().toByteArray()); tx["receiver"]      =
//   QString(transaction.receiver().toByteArray()); tx["producer"]      =
//   QString(transaction.producer().toByteArray());
//   // tx["digSig"] = QString::fromStdString(transaction.getDigSig());
//   tx["block"] = QString::fromStdString(blockId.toStdString());
//   //    tx["isFreeze"] = data == Fee::FREEZE_TX;
//   //    tx["incoma"] = data == Fee::UNFREEZE_TX || data.contains(Fee::UNFEE)
//   ||
//   //    data == Fee::FREEZE_TX
//   //            || data == Fee::UNFREEZE_TX
//   //        ? !incoma
//   //        : incoma;

//   return tx;
// }

// QVariantMap ClientController::benchmark() {
//   QVariantMap bench;
//   for (int i = 0; i != 1000; i++) {
//     std::string hash = Utils::calcHash("hash");

//     QElapsedTimer t;
//     t.start();
//     Signature signature =
//     m_node->accountController()->mainActor()->key().sign(hash);

//     QByteArray sign =
//     QByteArray::fromStdString(std::string(signature.begin(),
//     signature.end())); bench["sign"] = bench["sign"].toLongLong() +
//     t.elapsed();

//     t.restart();
//     bool verify =
//     m_node->accountController()->mainActor()->key().verify(hash, signature);
//     Q_UNUSED(verify)
//     bench["verify"] = bench["verify"].toLongLong() + t.elapsed();

//     t.restart();
//     std::string hello = "hello";
//     auto pubKey =
//     m_node->accountController()->mainActor()->key().publicKey(); auto
//     encryptedActorBytes = m_node->accountController()->mainActor()
//                               ->key().encrypt(Bytes(hello.begin(),
//                               hello.end()), pubKey);
//     auto encryptedActor = std::string(encryptedActorBytes.begin(),
//     encryptedActorBytes.end()); bench["encryptActor"] =
//     bench["encryptActor"].toLongLong() + t.elapsed(); t.restart(); auto
//     decryptedActor =
//         m_node->accountController()->mainActor()->key().decrypt(
//             encryptedActorBytes,
//             m_node->accountController()->mainActor()->key().publicKey());
//     bench["decryptActor"] = bench["decryptActor"].toLongLong() + t.elapsed();

//     t.restart();
//     auto keygen = Cryptography::keygen();
//     std::string keyd = std::string(keygen.begin(), keygen.end());
//     KeyPass keyPass = {};
//     std::copy_n(keyd.begin(), std::min(keyd.size(), crypto_box_SEEDBYTES),
//     keyPass.begin()); Bytes encryptedFish
//     =Cryptography::encrypt(Bytes(hello.begin(), hello.end()),
//                                                         keyPass);

//     bench["encryptFish"] = bench["encryptFish"].toLongLong() + t.elapsed();
//     t.restart();
//     Bytes decryptedFish = Cryptography::decrypt(encryptedFish, keyPass);
//     bench["decryptFish"] = bench["decryptFish"].toLongLong() + t.elapsed();

//     // eLog("{} {} {} {}", sign, verify, decryptedActor, decryptedFish);
//     if (decryptedActor != decryptedFish)
//       return {};
//   }

//   return bench;
// }

// std::pair<QByteArray, bool> ClientController::getChatKey(QString myId,
//                                                          QString chatId) {
//   //    QString dbChatPath = DfsStruct::ROOT_FOOLDER_NAME + "/" + myId +
//   //    "/private/chats"; if (!QFile::exists(dbChatPath)) {
//   //        eLog("{} not exists", "[Chat] " + DfsStruct::ROOT_FOOLDER_NAME +
//   "/" + myId +
//   //        "/private/chats"
//   //);
//   //        return { "", false };
//   //    }

//   //    auto mainActor = m_node->accountController()->mainActor().key();
//   //    DBConnector db(dbChatPath.toStdString());
//   //    std::string encryptedChatId =
//   //    mainActor.encryptSelf(chatId.toStdString()); std::vector<DBRow> res =
//   //        db.select("SELECT owner, key FROM " +
//   //        Config::DataStorage::chatIdTableName + " WHERE chatId =
//   //        ?",
//   //                  Config::DataStorage::chatIdTableName, { { "chatId",
//   //                  encryptedChatId } });

//   //    if (res.size() == 0) {
//   //        eLog("[Chat] Can't find key with chatId {}", chatId);
//   //        return { "", false };
//   //    }

//   //    QByteArray key =
//   //    QByteArray::fromStdString(mainActor.decryptSelf(res[0]["key"])); if
//   //    (key.isEmpty()) {
//   //        eLog("[Chat] Incorrect key with chatId {}", chatId);
//   //        return { "", false };
//   //    }

//   //    return { key, true };
//   return {"", true};
// }

int ClientController::getAuthStatus() const { return authType; }

void ClientController::setAuthStatus(int value) { authType = value; }

void ClientController::skipAuth() {
  eLog("skipAuth");
  waitingFiles.clear();
  waitingFilesNetwork.clear();
  emit connectToNode(etUtils->serverIp(), etUtils->networkProtocol());
  emit noMoreServiceAndPrivate();
  QTimer::singleShot(1000, [this]() { emit authEnded(true, authType); });
}

QString ClientController::fixFileName(const QString &fileName) {
  return Utils::fix_file_name(fileName, "_");
}

QString ClientController::firstId() {
  auto firstId = m_node->actor_index()->network_id();
  return firstId.is_zero() ? QString("-") : firstId.toQString();
}

qint64 ClientController::actorsCount() {
  return m_node->actor_index()->records();
}

QString ClientController::localServerIp() {
  return m_node->network()->local_ip();
}

// int ClientController::exportFile(QString dfsPath, QString origName,
//                                  int originSize, QString chatId) {
//   QString decryptedFile =
//       "tmp/" + QString::number(QRandomGenerator::global()->bounded(1323123));
//   QString newFilePath =
//       QStandardPaths::writableLocation(QStandardPaths::DownloadLocation) +
//       "/" + origName;

//   if (QFileInfo(newFilePath).size() == originSize) {
//     eLog("File already exists");
//     return 2;
//   } else
//     QFile::remove(newFilePath);

//   auto [key, keyRes] = getChatKey(myId(), chatId);
//   if (!keyRes) {
//     eLog("Key cant find");
//     return 0;
//   }
//   QByteArray keyT = key;

//   QDir().mkpath(
//       QStandardPaths::writableLocation(QStandardPaths::DownloadLocation));
//   if (!Utils::decryptFile(dfsPath, decryptedFile, keyT)) {
//     eLog("Cant decrypt");
//     return 0;
//   }
//   if (!QFile::copy(decryptedFile, newFilePath)) {
//     eLog("Cant copy");
//     QFile::remove(decryptedFile);
//     return 0;
//   }

//   QFile::remove(decryptedFile);
//   return 1;
// }

void ClientController::shareFile(QString dfsPath, QString type) {
  dfsPath = dfsPath.replace(QString::fromStdWString(Utils::filePrefix), "");
  QString mime = Utils::fileMimeType(dfsPath);
  eLog("dfsPath {}", dfsPath);
  shareUtils->sendFile(dfsPath, "Send file", mime, 111, false);
}

int ClientController::saveFile(QString dfsPath) {
  dfsPath.replace(QString::fromStdWString(Utils::filePrefix), "");
  QString newFilePath =
      QStandardPaths::writableLocation(QStandardPaths::DownloadLocation) + "/" +
      QFileInfo(dfsPath).fileName();

  if (QFileInfo(newFilePath).size() == QFileInfo(dfsPath).size()) {
    eLog("File already exists");
    return 2;
  } else
    QFile::remove(newFilePath);

  QDir().mkpath(
      QStandardPaths::writableLocation(QStandardPaths::DownloadLocation));

  if (!QFile::copy(dfsPath, newFilePath)) {
    eLog("Cant copy");
    return 0;
  }

  return 1;
}

// bool ClientController::chatFile(QString filePath, QString chatId, int type) {
//   Q_UNUSED(type)
//   if (filePath.isEmpty() || chatId.isEmpty()) {
//     eLog("[Chat] {} or {} is empty", filePath, chatId);
//     return false;
//   }

//   QString tmpPath =
//       "tmp/" + QString::number(QDateTime::currentSecsSinceEpoch() +
//                                QRandomGenerator::global()->bounded(10000));
//   bool copyRes = QFile::copy(filePath, tmpPath);
//   eLog("[Chat] Temp copy file result: {} {} {}", copyRes, filePath, tmpPath);
//   if (!copyRes)
//     return false;
//   QString fileName = QFileInfo(filePath).fileName();
//   filePath = tmpPath;
//   auto [key, keyRes] = getChatKey(myId(), chatId);
//   if (!keyRes) {
//     eLog("Chat: key not found");
//     return false;
//   }

//   sendedChatFiles[filePath] = {chatId, fileName, QFileInfo(filePath).size()};
//   eLog("sendedChatFiles[filePath] {} {} {}", chatId, fileName
//, QFileInfo(filePath).size());
//   //    emit send(DfsStruct::DfsSave::File, filePath, "encryptfile::" + key,
//   //    DfsStruct::Type::Files);
//   return true;
// }

bool ClientController::uploadFile(QString filePath) {
#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
  if (!QFile::exists(filePath)) {
    eLog("[Upload] Cannot check existense of file {}", filePath);
    return false;
  }
#endif
#ifdef Q_OS_IOS
  if (filePath.contains("assets"))
    filePath = QUrl(filePath).toLocalFile();
  else
    filePath = QUrl(filePath).toString();
#endif

  //    QString dfsPath = QDir::currentPath() + "/" +
  //    QString::fromStdString(DfsStruct::ROOT_FOOLDER_NAME_STD)
  //        + "/" + myId() + "/files/" + QFileInfo(filePath).fileName();
  //    QFile::remove(dfsPath);
  //    bool copyRes = QFile::copy(filePath, dfsPath);
  //    eLog("[Upload] Temp copy file result: {} {} {}", copyRes, filePath, //
  //    dfsPath); if (!copyRes) {
  //        return false;
  //    }
  //    QString fileName = QFileInfo(filePath).fileName();
  // #ifdef Q_OS_ANDROID
  //    QAndroidJniObject jniFilePath = QAndroidJniObject::fromString(filePath);
  //    fileName = QtAndroid::androidActivity()
  //                   .callObjectMethod("getFileName",
  //                   "(Ljava/lang/String;)Ljava/lang/String;",
  //                                     jniFilePath.object<jstring>())
  //                   .toString();
  // #endif

  //    filePath = dfsPath;

  // #ifdef Q_OS_IOS
  //     if (type == 2) {
  //         QImageReader reader(filePath);
  //         fileName = "image." + reader.format().toLower();
  //     }
  // #endif

  //    // auto key =
  //    QByteArray::fromStdString(node->accountController()->mainActor().key()->secretKey());
  //    emit send(DfsStruct::DfsSave::StaticNonStored, fileName, ""
  //    /*"encryptfile::" + key*/,
  //              DfsStruct::Type::Files);
  return true;
}

// void ClientController::openChatFile(QString chatId, QString dfsPath,
//                                     QString originName, int originSize,
//                                     QString openType) {
//   QString fileName = fixFileName(originName);
//   if (fileName.right(1) == "." || fileName.right(1) == " ")
//     fileName.replace(fileName.length() - 1, 1, "_");

// #ifndef Q_OS_ANDROID
//   QString currentPath = QDir::currentPath() + "/";
//   QString tmpPath = "tmp/" + fileName;
//   QString decryptedFile = currentPath + tmpPath;
// #else
//   QString shareFolder =
//       QStandardPaths::standardLocations(QStandardPaths::AppDataLocation)
//           .value(0) +
//       "/Share/";

//   if (!QDir(shareFolder).exists())
//     eLog("mkpath {}", QDir().mkpath(shareFolder));

//   QString decryptedFile = shareFolder + fileName;
// #endif

//   if (QFile::exists(decryptedFile) &&
//       QFileInfo(decryptedFile).size() == originSize) {
//     eLog("Exists, open {} {}", decryptedFile
//, Utils::fileMimeType(decryptedFile));

// #if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
//     QDesktopServices::openUrl(
//         QUrl(QString::fromStdWString(Utils::filePrefix) + decryptedFile,
//         QUrl::TolerantMode));
// #else
//     if (openType == "view")
//       shareUtils->viewFile(decryptedFile, "Open file",
//                            Utils::fileMimeType(decryptedFile), 111, false);
//     else if (openType == "send")
//       shareUtils->sendFile(decryptedFile, "Send file",
//                            Utils::fileMimeType(decryptedFile), 111, false);
// #endif
//     return;
//   }

//   auto [key, keyRes] = getChatKey(myId(), chatId);
//   if (!keyRes)
//     return;
//   QByteArray keyT = key;
//   eLog("keyT {}", key);

//   auto future = QtConcurrent::run(
//       [=] { return Utils::decryptFile(dfsPath, decryptedFile, keyT); });
//   future.then([this, decryptedFile, openType](bool res) {
//     eLog("{} {} {}", res, decryptedFile, QFile::exists(decryptedFile));
//     eLog("Decrypted, open {} {}", decryptedFile
//, Utils::fileMimeType(decryptedFile));

//     if (!res)
//       return;
// #if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
//     Q_UNUSED(this)
//     eLog("Detect desktop");
//     QDesktopServices::openUrl(
//         QUrl(QString::fromStdWString(Utils::filePrefix) + decryptedFile,
//         QUrl::TolerantMode));
// #else
//     if (openType == "view")
//       shareUtils->viewFile(decryptedFile, "Open file",
//                            Utils::fileMimeType(decryptedFile), 111, false);
//     else if (openType == "send")
//       shareUtils->sendFile(decryptedFile, "Send file",
//                            Utils::fileMimeType(decryptedFile), 111, false);
// #endif
//   });
// }

void ClientController::chatFileLoaded(QString fileName, QString originalFile) {
  if (originalFile == "network") {
    emit fileLoaded(fileName);
    return;
  }

  if (!sendedChatFiles.contains(originalFile))
    return;

  auto [chatId, originName, originSize] = sendedChatFiles[originalFile];
  eLog("chatFileLoaded {} {} {} {}", fileName, chatId, originName, originSize);
  //    ChatFileSender chatFile = { .chatId = chatId,
  //                                .dfsName = fileName,
  //                                .originName = originName,
  //                                .mime = Utils::fileMimeType(originalFile),
  //                                .size = originSize };
  //    emit sendChatFile(chatFile);
  QFile::remove(originalFile);
}

void ClientController::loadHash() {
  m_autologinHash.load();
  eLog("{}", m_autologinHash.hash());
}

void ClientController::changeTranslation(const QString &language) {
  static QTranslator translator;

  QString lang = language;
  if (language.isEmpty()) {

#ifdef Q_OS_MACOS
    QStringList uiLangs = QLocale::system().uiLanguages();
    eLog("[Translation] All UI languages: {}", uiLangs.join(", "));

    QLocale locale = QLocale::system();
    eLog("[Translation] System locale name: {}", locale.name());
    eLog("[Translation] System locale language: {}",
         QLocale::languageToString(locale.language()));

    if (!uiLangs.isEmpty()) {
      QString firstLang = uiLangs.first().split('-').first();
      eLog("[Translation] First UI language code: {}", firstLang);

      if (firstLang == "uk" || firstLang == "ru") {
        lang = firstLang;
        eLog("[Translation] Using first supported language: {}", lang);
      } else {
        for (const QString &uiLang : uiLangs) {
          QString langCode = uiLang.split('-').first();
          if (langCode == "uk" || langCode == "ru") {
            lang = langCode;
            eLog("[Translation] Found supported language in list: {}", lang);
            break;
          }
        }
      }
    }
#else
    QLocale locale = QLocale::system();
    lang = locale.name().left(2);
#endif
  }

  eLog("[Translation] Change lang: {}", lang);
  if ((lang == "uk" || lang == "ru") &&
      translator.load(":/translations/ExtraChain_" + lang + ".qm")) {
    qApp->installTranslator(&translator);
    eLog("[Translation] Loaded {}", lang);
  } else {
    qApp->removeTranslator(&translator);
    eLog("[Translation] No translation");
  }
}

QString ClientController::calcRoccSummary() {
  return "---";
  // auto last_saved = m_node->blockchain()->getBlockIndex().getLastSavedId();
  // auto mega_result =
  //     m_node->blockchain()->create_mega_genesis_block(m_node->accountController()->system_actor());
  // if (!mega_result.has_value()) {
  //     return QString::fromStdString(fmt::format("Error: {}",
  //     mega_result.error()));
  // }

  // BigNumberFloat sum;

  // for (const auto &[first, second] : mega_result->dataRows()) {
  //     if (first.tokenId ==
  //     ActorId("468faf2f1be6504a9a26f7f027f7e43380b0d77d")) {
  //         sum += second.state;
  //     }
  // }

  // auto res = fmt::format("Blocks count: {}\nROCC: {}",
  //                        last_saved.to_string(NumeralBase::Dec),
  //                        sum.to_string(NumeralBase::Dec));
  // return QString::fromStdString(res);
}

QString ClientController::calcActiveUsers() {
  return "---";
  // auto [week, week_new] = m_node->dag()->active_users();
  // return QString("Week: %1 | New week: %2").arg(week).arg(week_new);
}

QString ClientController::checkUpdate() {
  auto [can_update, version] = updater.checkForUpdates();

  if (can_update) {
    return QString::fromStdString(version);
  }

  return "";
}

bool ClientController::downloadUpdate() {
  auto [can_update, version] = updater.checkForUpdates();

  if (can_update) {
    updater.update();
    return true;
  }

  return false;
}

void ClientController::installUpdate() { return updater.install(); }

bool ClientController::isBlockchainLight() {
  auto res = m_node->dag()->mode() == DagMode::Light;
  return res;
}

void ClientController::setBlockchainLight(bool isLight) {
  auto mode = isLight ? DagMode::Light : DagMode::Full;
  // m_node->dag()->set_mode(mode);
  auto settings = Utils::read_settings();
  settings.dag_mode = mode;
  Utils::write_settings(settings);
}

bool ClientController::isDfsLight() {
  auto res = m_node->dfs()->mode() == DfsMode::Light;
  return res;
}

void ClientController::setDfsLight(bool isLight) {
  auto mode = isLight ? DfsMode::Light : DfsMode::Full;
  auto extrachain_settings = Utils::read_settings();
  extrachain_settings.dfs_mode = mode;
  Utils::write_settings(extrachain_settings);
  m_node->dfs()->set_mode(mode);
}

QVariantList ClientController::loadUserNames() {
  QVariantList list;
  auto network_id = m_node->actor_index()->network_id();
  if (network_id.is_zero()) {
    return list;
  }

  if (usernames_file_id.empty()) {
    auto search_result =
        Dfs::Tables::DirsFile::ActorSpace::search_file_by_folder_and_name(
            m_node->dfs()->get_db_instance(), network_id,
            Dfs::Basic::TEMPLATE_VECTOR, "Usernames");
    if (!search_result.has_value()) {
      return list;
    }

    this->usernames_file_id = search_result->file_id;

    if (search_result->state == Dfs::FileState::Ready) {
      this->m_usernameActive = true;
      emit this->usernameActiveChanged();
    } else {
      return list;
    }
  }

  auto rows = m_node->dfs()->read_vector_rows(network_id, usernames_file_id);
  if (!rows.has_value()) {
    return list;
  }

  for (auto &row : rows.value()) {
    QVariantMap obj;
    obj["actorId"] = QString::fromStdString(row["actor"]);
    obj["username"] = QString::fromStdString(row["name"]);
    list.append(obj);
  }

  return list;
}

QString ClientController::loadUserName(QString actorId) {
  auto network_id = m_node->actor_index()->network_id();
  if (network_id.is_zero()) {
    QFile network(".network_id");
    if (network.open(QFile::ReadOnly)) {
      auto data = network.readAll();
      network.close();

      if (!data.isEmpty()) {
        auto actor_id = ActorId::create(data.toStdString());
        if (actor_id.has_value()) {
          network_id = actor_id.value();
        } else {
          return "";
        }
      }
    }
  }

  if (network_id.is_zero()) {
    return "";
  }

  QFile network(".network_id");
  network.open(QFile::WriteOnly);
  network.write(network_id.toQByteArray());
  network.close();

  if (usernames_file_id.empty()) {
    auto search_result =
        Dfs::Tables::DirsFile::ActorSpace::search_file_by_folder_and_name(
            m_node->dfs()->get_db_instance(), network_id,
            Dfs::Basic::TEMPLATE_VECTOR, "Usernames");
    if (!search_result.has_value()) {
      return "";
    }

    this->usernames_file_id = search_result->file_id;

    if (search_result->state == Dfs::FileState::Ready) {
      this->m_usernameActive = true;
      emit this->usernameActiveChanged();
    } else {
      return "";
    }
  }

  if (actorId.isEmpty()) {
    actorId =
        m_node->account_controller()->current_profile().main_id().toQString();
  }

  auto row = m_node->dfs()->read_vector_row(network_id, usernames_file_id,
                                            actorId.toStdString());
  if (!row.has_value()) {
    return "";
  }

  return row->at("name").c_str();
}

bool ClientController::addUsername(QString username) {
  auto network_id = m_node->actor_index()->network_id();
  if (network_id.is_zero()) {
    return false;
  }

  auto res = m_node->dfs()->add_vector_row(network_id, usernames_file_id,
                                           {
                                               {"name", username.toStdString()},
                                           });
  return res;
}

bool ClientController::existsUsername(QString username) {
  auto network_id = m_node->actor_index()->network_id();
  auto v = DfsVector::load(m_node, m_node->account_controller()->system_actor(),
                           network_id, usernames_file_id);
  if (!v.has_value()) {
    return false;
  }

  auto row = v->read_rows(
      fmt::format("WHERE name='{}' AND status = '1'", username.toStdString()));
  if (!row.has_value()) {
    return false;
  }
  if (row->empty()) {
    return false;
  }

  return true;
}

bool ClientController::removeUsername() {
  auto network_id = m_node->actor_index()->network_id();
  auto system_actor_id =
      m_node->account_controller()->current_profile().main_id();

  auto res = m_node->dfs()->remove_vector_row(network_id, usernames_file_id,
                                              system_actor_id.to_string());
  return res;
}

// auto subscription_template = Dfs::CollectionTemplate::create("Subscription")
//                                  .value()
//                                  .add_fields({
//                                  Dfs::Field::Integer("type").not_null(),
//                                                Dfs::Field::Integer("date_start").not_null(),
//                                                Dfs::Field::Bool("auto_renew").not_null().between(0,
//                                                1),
//                                                Dfs::Field::String("block_id").not_null(),
//                                                Dfs::Field::String("transaction_hash").not_null()
//                                                });

void ClientController::loadSubscription() {
  auto extrachain_id = ActorId("46710a2d823c23db9fc2ac01e0f84212a8128373");

  if (sub_file_id.empty()) {
    auto search_result =
        Dfs::Tables::DirsFile::ActorSpace::search_file_by_folder_and_name(
            m_node->dfs()->get_db_instance(), extrachain_id,
            Dfs::Basic::TEMPLATE_VECTOR, "ExtraChainSubscription");
    if (!search_result.has_value()) {
      return;
    }

    sub_file_id = search_result->file_id;

    if (search_result->state == Dfs::FileState::Ready) {
      m_subscribeActive = true;
      emit subscribeActiveChanged();
    } else {
      return;
    }
  }

  auto system_actor_id = m_node->account_controller()->system_actor().id();
  auto row = m_node->dfs()->read_vector_row(extrachain_id, sub_file_id,
                                            system_actor_id.to_string());

  if (m_subscribed != row.has_value()) {
    m_subscribed = row.has_value();
    emit subscribedChanged();
  }
}

void ClientController::addSubscription(int type, bool auto_renew) {
  auto extrachain_id = ActorId("46710a2d823c23db9fc2ac01e0f84212a8128373");

  if (sub_file_id.empty()) {
    auto search_result =
        Dfs::Tables::DirsFile::ActorSpace::search_file_by_folder_and_name(
            m_node->dfs()->get_db_instance(), extrachain_id,
            Dfs::Basic::TEMPLATE_VECTOR, "TestSubscription");
    if (!search_result.has_value()) {
      return;
    }
    sub_file_id = search_result->file_id;
  }

  bool res = m_node->add_subscription(
      extrachain_id, sub_file_id, type, auto_renew,
      TokenId("468faf2f1be6504a9a26f7f027f7e43380b0d77d"));
}

QStringList ClientController::getPhrase() {
  auto mnemonic = m_node->account_controller()->seed_mnemonic();

  QStringList result;
  for (const auto &word : mnemonic) {
    result << QString::fromStdString(word);
    qDebug() << "word" << word;
  }
  return result;
}

bool ClientController::validatePhrase(const QString &phrase) {
  return m_node->account_controller()->validate_mnemonic(
      phrase.simplified().trimmed().toStdString());
}

bool ClientController::importPhrase(const QString &login,
                                    const QString &password,
                                    const QString &phrase) {
  std::string mnemonic = phrase.trimmed().simplified().toStdString();
  return m_node->account_controller()->import_seed_phrase(
      login.toStdString(), password.toStdString(), mnemonic);
}

bool ClientController::importHex(const QString &login, const QString &password,
                                 const QString &hex) {
  return m_node->account_controller()->import_seed_hex(
      login.toStdString(), password.toStdString(), hex.toStdString());
}

QString ClientController::importedHex(const QString &_) {
  const std::string generatedHex = m_node->account_controller()->seed_hex();
  return QString::fromStdString(generatedHex);
}

bool ClientController::isNewProfile() {
  return m_node->account_controller()->profile_type() == ProfileType::New;
}

void ClientController::subscriptionAdded() { this->loadSubscription(); }

// QString ClientController::downloadUpdate() {
//     FileDownloader *downloader = new FileDownloader();

//     QObject::connect(downloader, &FileDownloader::downloadProgress, [](qint64
//     received, qint64 total) {
//         qDebug() << "Progress:" << received << "/" << total;
//     });

//     QObject::connect(downloader, &FileDownloader::downloadComplete, []() {
//         qDebug() << "Download completed!";
//     });

//     QObject::connect(downloader, &FileDownloader::error, [](const QString
//     &error) {
//         qDebug() << "Error:" << error;
//     });

//     downloader->downloadFile("https://extrachain.com/api/assets/apps/ExtraChain_Setup_0.2.0.dmg",
//                              "./ExtraChain_Setup_0.2.0.dmg");

//     return "";
// }

void ClientController::setNode(ExtraChainNode *newNode) {
  m_node = newNode;

  auto setupUsernamesHandler = [this](ActorId owner_id, Dfs::DirRow dir_row,
                                      DbRow row) {
    auto network_id = m_node->actor_index()->network_id();
    if (network_id.is_zero() || usernames_file_id.empty()) {
      return;
    }

    if (owner_id == network_id && dir_row.file_id == usernames_file_id) {
      emit usernamesUpdated();
    }
  };

  connect(m_node->dfs(), &DfsController::vectorRowAdded, setupUsernamesHandler);
  connect(m_node->dfs(), &DfsController::vectorRowRemoved,
          setupUsernamesHandler);
}

QString ClientController::authHash() const {
  return QString::fromStdString(m_autologinHash.hash());
}

void ClientController::setAuthHash(const QString &newAuthHash) {
  if (m_autologinHash.hash() == newAuthHash.toStdString())
    return;

  m_autologinHash.save(newAuthHash.toStdString());
  emit authHashChanged();
}

quint64 ClientController::currentDfsLimit() {
  return m_node->dfs()->bytesLimit();
}

void ClientController::changeDfsLimit(quint64 size) {
  // m_node->dfs()->setBytesLimit(size);
}

QString ClientController::testButton(const QString &f) { return ""; }

void ClientController::addFiles(const QStringList &files,
                                const int service_folder,
                                const bool messenger_send_as_file) {
  if (files.isEmpty())
    return;

  const QString &file = files.first();
  auto mainId = m_node->account_controller()->current_profile().main_id();
  auto dataSecurity = Dfs::DataSecuritySelf{.my_actor = mainId};

  // Define file processing function
  auto processFile = [this, file, mainId, dataSecurity, service_folder,
                      messenger_send_as_file]() {
    try {
      QString filePath = file;

#ifdef Q_OS_ANDROID
      auto tempPath =
          "tmp/" + QString::number(QRandomGenerator::global()->bounded(1000) +
                                   QDateTime::currentMSecsSinceEpoch());
      QFile::copy(file, tempPath);
      filePath = tempPath;
#endif

      auto sf = Dfs::toServiceFolder(service_folder);
      auto result =
          m_node->dfs()->store_file(mainId, mainId, filePath.toStdWString(), sf,
                                    QFileInfo(file).fileName().toStdString(),
                                    Dfs::DataSecurity::Self, dataSecurity);

#ifdef Q_OS_ANDROID
      QFile::remove(tempPath);
#endif

      QString message = "";

      if (!result.has_value()) {
        switch (result.error()) {
        case Dfs::DfsError::MaxFileSize:
          message = "Error: The file exceeds the allowed limit of 700 MB.";
          break;
        default:
          message =
              QString::fromStdString(fmt::format("Error: {}", result.error()));
          break;
        }
      } else {
        message = QFileInfo(file).fileName() +
                  " was successfully uploaded to storage.";
      }

      if (result.has_value() && sf == Dfs::ServiceFolder::Chat) {
        const auto &value = result.value();
        const QString dfsPath = QString::fromStdWString(
            DfsB::fsActrRootW + DfsB::separator +
            value.actor_id.toQString().toStdWString() + DfsB::separator +
            QString::fromStdString(value.file_id).toStdWString());
        emit messengerAddedFile(dfsPath, file, messenger_send_as_file);
      } else if (!result.has_value() &&
                 result.error() == Dfs::DfsError::DirDuplicate &&
                 sf == Dfs::ServiceFolder::Chat) {
        const std::string filename = QFileInfo(file).fileName().toStdString();
        const auto searchResult =
            Dfs::Tables::DirsFile::ActorSpace::search_file_by_folder_and_name(
                m_node->dfs()->get_db_instance(), mainId,
                Dfs::Basic::TEMPLATE_CHAT, filename);
        const auto &fileId = searchResult.value().file_id;
        const QString dfsPath = QString::fromStdWString(
            DfsB::fsActrRootW + DfsB::separator +
            QString::fromStdString(mainId.to_string()).toStdWString() +
            DfsB::separator + QString::fromStdString(fileId).toStdWString());
        emit messengerAddedFile(dfsPath, file, messenger_send_as_file);
      }
      QMetaObject::invokeMethod(
          this,
          [this, message, file, sf]() {
            if (sf != Dfs::ServiceFolder::Chat)
              emit resultAddFile(message, file);
          },
          Qt::QueuedConnection);
    } catch (const std::exception &e) {
      QMetaObject::invokeMethod(
          this,
          [this, file, e]() {
            emit resultAddFile(QString("Exception: %1").arg(e.what()), file);
          },
          Qt::QueuedConnection);
    }
  };

  // Process large files in separate thread, small files directly
  if (QFileInfo(file).size() > 5 * 1024 * 1024) {
    QThreadPool::globalInstance()->start(processFile);
  } else {
    processFile();
  }
}

QString ClientController::fileName(const QString &file) {
  return QFileInfo(file).fileName();
}

bool ClientController::subscribed() const { return m_subscribed; }

bool ClientController::subscribeActive() const { return m_subscribeActive; }

bool ClientController::usernameActive() const { return m_usernameActive; }
