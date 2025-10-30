#include "MessengerController.h"

#include "blurhash.h"
#include "chat/chat_manager.h"
#include "dfs/dfs_controller.h"
#include <QImage>
#include <QThreadPool>
#include <QtGui/qvectornd.h>
#include <QtMath>

UserModel::UserModel(VariantModel *parent) : VariantModel(parent) {
  setModelRoles({"username"});
}

void UserModel::newActor(ActorId actorId) {
  append({{"username", actorId.toQString()}});
}

ChatListModel::ChatListModel(VariantModel *parent) : VariantModel(parent) {
  setModelRoles({"name_chat", "myself", "another", "type", "fileActorId",
                 "fileId", "last_message", "date_time_last_message"});
}

ChatModel::ChatModel(VariantModel *parent) : VariantModel(parent) {
  setModelRoles({"messageId", "owner", "type", "timestamp", "message"});
}

MessengerController::MessengerController(ExtraChainNode *nde, QObject *parent)
    : QObject(parent), node(nde) {
  auto all_actors = node->actor_index()->read_all_actors_ids();
  QVariantList list;
  for (int i = 0; i < all_actors.size(); i++) {
    // if (all_actors.at(i) == node.accountController()->system_actor().id()) {
    //     continue;
    // }

    QVariantMap contact = {{"username", all_actors.at(i).toQString()}};
    list.append(contact);
  }

  setUserModel(new UserModel());
  userModel()->appends(list);
  connect(node->actor_index(), &ActorIndex::actorSaved, userModel(),
          &UserModel::newActor);

  setChatListModel(new ChatListModel());

  setChatModel(new ChatModel());

  connect(node, &ExtraChainNode::chatsLoaded,
          [this]() { this->updateChatListModel(); });

  connect(node, &ExtraChainNode::chatAdded, [this](Chat::Chat chat) {
    // this->updateChatListModel();
    _chatListModel->append(chatToMap(chat));

    if (chat.chat.peer_id.has_value()) {
#ifdef EXTRACHAIN_MESSENGER
      emit newChatAdded(chat.chat.peer_id.value().toQString());
#endif
    }
  });

  connect(node, &ExtraChainNode::messageAdded,
          [this](ActorId owner_id, std::string file_id, Chat::Message msg) {
            if (owner_id == this->owner_id && file_id == this->file_id) {
              this->addMessage(msg);
              return;
            }

            auto chat = this->node->chat_manager()->get_chat(owner_id, file_id);
            if (chat.has_value()) {
              if (chat->chat.peer_id.has_value()) {
#ifdef EXTRACHAIN_MESSENGER
                emit newMessageAdded(chat->chat.peer_id.value().toQString());
#endif
              }
            }
          });

  connect(node, &ExtraChainNode::messageRemoved,
          [this](ActorId owner_id, std::string file_id, std::string id) {
            if (owner_id == this->owner_id && file_id == this->file_id) {
              QString qtId = QString::fromStdString(id);
              int index = _chatModel->findIndexByField("messageId", qtId);

              if (index >= 0) {
                _chatModel->remove(index, 1);
              }
            }
          });
}

UserModel *MessengerController::userModel() const { return _userModel; }

ChatListModel *MessengerController::chatListModel() const {
  return _chatListModel;
}

ChatModel *MessengerController::chatModel() const { return _chatModel; }

void MessengerController::setUserModel(UserModel *newUserModel) {
  _userModel = newUserModel;
  emit userModelChanged();
}

void MessengerController::setChatListModel(ChatListModel *newChatListModel) {
  _chatListModel = newChatListModel;
  emit chatListModelChanged();
}

void MessengerController::setChatModel(ChatModel *newChatModel) {
  _chatModel = newChatModel;
  emit chatModelChanged();
}

QVariantMap MessengerController::chatToMap(const Chat::Chat &chat) {
  QString name;

  if (chat.chat.chat_type.has_value() &&
      chat.chat.chat_type.value() == Chat::ChatType::Channel) {
    name = "ExtraChain News";
  } else if (!chat.chat.peer_id.has_value()) {
    name = "Mirror";
  } else if (chat.chat.peer_id.has_value()) {
    name = chat.chat.peer_id.value().toQString();
  } else {
    name = "* error *";
  }

  auto chat_manager = node->chat_manager();
  auto messages = chat_manager->read_chat_messages(chat.owner_id, chat.file_id);
  QString last_message = "No messages yet";
  long long dt_last_message = 0;
  if (messages.has_value() && !messages.value().empty()) {
    auto lm = messages.value().at(messages.value().size() - 1);
    last_message = QString::fromStdString(lm.message.data.value_or(""));
    // qDebug() << "last_message" << last_message;
    dt_last_message =
        qulonglong(messages.value().at(messages.value().size() - 1).timestamp);
    auto lastMessageFromCache = getCachedMessage(name);
    if (!lastMessageFromCache.isEmpty()) {
      last_message = "<font color='red'>Draft!</font> " + lastMessageFromCache;
    }
  }

  return {{"myself",
           node->account_controller()->current_profile().main_id().toQString()},
          {"another",
           chat.chat.peer_id.has_value() ? chat.chat.peer_id->toQString() : ""},
          {"fileActorId", chat.owner_id.toQString()},
          {"fileId", QString::fromStdString(chat.file_id)},
          {"name_chat", name},
          {"type", chat.chat.chat_type.has_value()
                       ? int(chat.chat.chat_type.value())
                       : 0},
          {"last_message", last_message},
          {"date_time_last_message", dt_last_message}};
}

void MessengerController::updateChatListModel() {
  if (node->account_controller()->empty()) {
    return;
  }

  auto chat_manager = node->chat_manager();
  auto chats = chat_manager->read_chats();

  _chatListModel->clear();

  /*
  Chat::Chat channel = Chat::Chat {
      .id = "-",
      // for test network
      .owner_id = ActorId("15ceb2a77b7f7bf2338ceaf71dcd350f7ebef4cd"),
      .file_id  =
  "19dcb46ef1a9c982dfd56cd9f1e823290f9a8bbadcdad09679563dfba5a96a7c", .chat =
  Chat::ChatData { .chat_type = Chat::ChatType::Channel },
  };
  _chatListModel->append(chatToMap(channel));
  */

  if (!chats.has_value()) {
    return;
  }

  for (const auto &chat : chats.value()) {
    // bool existChat = std::any_of(_chatListModel->list().cbegin(),
    //                              _chatListModel->list().cend(),
    //                              [&name](const QVariantMap &chat) {
    //                                  return chat.value("name_chat") == name;
    //                              });

    // if (!existChat) {
    // }
    _chatListModel->append(chatToMap(chat));
  }
}

void MessengerController::updateChatModel(QString fileOwnerId, QString fileId,
                                          bool quick) {
  owner_id = ActorId(fileOwnerId.toStdString());
  file_id = fileId.toStdString();
  _chatModel->clear();

  auto chat_manager = node->chat_manager();
  auto messages = chat_manager->read_chat_messages(owner_id, file_id, quick);

  if (!messages.has_value()) {
    return;
  }
  _current_owner_id = owner_id.toQString();
  _current_file_id = fileId;

  this->addMessages(messages.value());
}

void MessengerController::addMessage(const Chat::Message &message) {
  QVariantMap mapMessage;
  mapMessage.insert("text",
                    QString::fromStdString(message.message.data.value_or("")));
  if (message.message.data.has_value()) {

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(
        QString::fromStdString(message.message.data.value().c_str()).toLatin1(),
        &parseError);
    QString caption, path;
    if (parseError.error == QJsonParseError::NoError && doc.isObject()) {
      QJsonObject obj = doc.object();
      caption = obj["caption"].toString();
      path = obj["path"].toString();
    }

    mapMessage.insert("has_caption", !caption.isEmpty());
    mapMessage.insert("caption", caption);
    if (message.message.type.has_value() &&
        message.message.type.value() == Chat::MessageType::Video &&
        !path.isEmpty()) {
      mapMessage["text"] = path;
    }
    if (message.message.type.has_value() &&
        message.message.type.value() == Chat::MessageType::File &&
        !path.isEmpty()) {
      mapMessage["text"] = path;
    }
  }

  std::string replyId;
  if (message.message.reply_id.has_value()) {
    const QString parentMessageId =
        QString::fromStdString(message.message.reply_id.value());

    for (int i = 0; i < _chatModel->rowCount(); ++i) {
      const QVariantMap rowData = _chatModel->get(i);
      if (rowData.value("messageId").toString() == parentMessageId) {
        const QVariantMap parentMessage = rowData.value("message").toMap();
        mapMessage.insert("reply_type", rowData.value("type").toInt());
        mapMessage.insert("reply_text_message",
                          parentMessage.value("text").toString());
        mapMessage.insert("has_reply", true);
        mapMessage.insert("parent_message_id", parentMessageId);
        break;
      }
    }
  } else {
    mapMessage.insert("has_reply", false);
  }

  auto map = QVariantMap{
      {"messageId", QString::fromStdString(message.id)},
      {"owner", message.actor ==
                    node->account_controller()->current_profile().main_id()},
      {"type", message.message.type.has_value()
                   ? int(message.message.type.value())
                   : 0},
      {"timestamp", qulonglong(message.timestamp)},
      {"message", mapMessage}};

  _chatModel->insert(0, map);
}

void MessengerController::addMessages(
    const std::vector<Chat::Message> &messages) {
  for (const auto &message : messages) {
    addMessage(message);
  }
}

void MessengerController::sendMessage(QString text) {
  // static const QRegularExpression
  // controlCharsRegex("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]"); static const
  // QRegularExpression
  // zeroWidthCharsRegex("[\\u200B-\\u200F\\u2060-\\u2064\\uFEFF]"); static
  // const QRegularExpression multipleSpacesRegex("\\s+");

  text = text.trimmed();
  // text = text.remove(controlCharsRegex);
  // text = text.remove(zeroWidthCharsRegex);
  // text = text.replace(multipleSpacesRegex, " ");

  auto message = Chat::MessageText{.text = text.toStdString()};
  if (text.startsWith("dfs/") &&
      text.split(QRegularExpression(R"([\\/])")).size() == 3) {
    const QString nameFile = getFileNameFromMessage(text);
    QString ext = QFileInfo(nameFile).suffix();
    sendImage(text, nameFile);
  } else {
    node->chat_manager()->add_new_message_text(owner_id, file_id, message);
  }
}

void MessengerController::replyMessage(const QString &text,
                                       const QString &messageId) {
  qDebug() << "Begin reply to message with id " << messageId << " with text "
           << text;
  auto message = Chat::MessageText{.text = text.toStdString(),
                                   .reply_id = messageId.toStdString()};
  node->chat_manager()->add_new_message_text(owner_id, file_id, message);
}

void MessengerController::sendGif(const QString &gifUrl,
                                  const QString &messageId) {
  Chat::MessageText cmt{.text = gifUrl.toStdString()};
  if (!messageId.isEmpty())
    cmt.reply_id = messageId.toStdString();

  node->chat_manager()->add_gif_message(owner_id, file_id, cmt);
}

void MessengerController::sendImage(const QString &pathToFile,
                                    const QString &localPath,
                                    const QString &messageId,
                                    const QString &caption) {
  QImage image(localPath);
  QImage img = image.convertToFormat(QImage::Format_RGB32);
  QString hash = BlurHashEncoder::encode(img, 3, 3);
  QMap<QString, QVariant> map;
  map["hash"] = hash;
  map["path"] = pathToFile;
  map["width"] = image.width();
  map["height"] = image.height();
  map["caption"] = caption;

  QJsonObject obj = QJsonObject::fromVariantMap(map);
  QString json = QJsonDocument(obj).toJson(QJsonDocument::Compact);
  Chat::MessageText chatMessageData{.text = json.toStdString()};
  if (!messageId.isEmpty())
    chatMessageData.reply_id = messageId.toStdString();
  auto res = node->chat_manager()->add_image_message(owner_id, file_id,
                                                     chatMessageData);
}

void MessengerController::sendVideo(const QString &pathToFile,
                                    const QString &messageId,
                                    const QString &caption) {
  QMap<QString, QVariant> map;
  map["path"] = pathToFile;
  if (!caption.isEmpty())
    map["caption"] = caption;

  QJsonObject obj = QJsonObject::fromVariantMap(map);
  QString json = QJsonDocument(obj).toJson(QJsonDocument::Compact);
  Chat::MessageText chatMessageData{.text = json.toStdString()};

  if (!messageId.isEmpty())
    chatMessageData.reply_id = messageId.toStdString();
  auto res = node->chat_manager()->add_video_message(owner_id, file_id,
                                                     chatMessageData);
}

void MessengerController::sendFile(const QString &pathToFile,
                                   const QString &messageId,
                                   const QString &caption) {
  QMap<QString, QVariant> map;
  map["path"] = pathToFile;
  if (!caption.isEmpty())
    map["caption"] = caption;

  QJsonObject obj = QJsonObject::fromVariantMap(map);
  QString json = QJsonDocument(obj).toJson(QJsonDocument::Compact);
  Chat::MessageText chatMessageData{.text = json.toStdString()};

  if (!messageId.isEmpty())
    chatMessageData.reply_id = messageId.toStdString();
  qDebug() << __FUNCTION__ << json;
  auto res = node->chat_manager()->add_file_message(owner_id, file_id,
                                                    chatMessageData);
}

void MessengerController::editMessage(const QString &text,
                                      const QString &messageId) {
  qDebug() << QString("Edit message with id %1. Text: message: [%2]")
                  .arg(messageId, text);
}

void MessengerController::removeMessage(QString id) {
  int index = _chatModel->findIndexByField("messageId", id);
  auto msg = _chatModel->get(index);
  if (!msg["owner"].toBool()) {
    return;
  }

  eLog("[Chat] Remove message with id {}", id);
  node->chat_manager()->remove_message(owner_id, file_id, id.toStdString());
}

bool MessengerController::createChat(QString actorWith) {
  if (actorWith.isEmpty()) {
    return false;
  }

  auto chat_manager = node->chat_manager();

  auto system_id = node->account_controller()->current_profile().system_id();
  if (actorWith.toStdString() == system_id.to_string()) {
    qDebug() << "[Chat] Creation: actorWith equal system_id";
    return false;
  }

  auto my_chats = chat_manager->read_chats();
  if (my_chats.has_value()) {
    my_chats_file_id = my_chats->at(0).file_id;
  }

  auto actor_with = ActorId(actorWith.toStdString());
  auto main_id = node->account_controller()->current_profile().main_id();
  auto chat = (actor_with == main_id)
                  ? chat_manager->create_myself()
                  : chat_manager->create_dialogue(actor_with);

  if (!chat.has_value()) {
    emit error("Can't create chat");
    eWarning("[ClientController] Can't create chat: {}", chat.error());

    return false;
  }

  eSuccess("[ClientController] Created chat: {}", chat);

  return chat.has_value();
}

QString MessengerController::currentDir() { return QDir::currentPath(); }

QString MessengerController::getFileNameFromMessage(const QString &message) {
  auto fileParts = message.split(QRegularExpression(R"([\\/])"));
  if (fileParts.size() != 3) {
    eLog("[MessengerController::getFileNameFromMessage] Please try again or "
         "check your export path.",
         message);
    return QString();
  }
  ActorId actorId(fileParts.at(1).toStdString());
  auto fileId = fileParts.at(2).toStdString();

  auto dir_row_result = Dfs::Tables::DirsFile::ActorSpace::get_dir_row(
      node->dfs()->get_db_instance(), actorId, fileId);
  if (!dir_row_result.has_value())
    return QString();

  QString name_file = QString::fromStdString(dir_row_result->name);
  const auto chat = node->chat_manager()->get_chat(
      ActorId(_current_owner_id.toStdString()), _current_file_id.toStdString());
  if (!chat) {
    eLog("[MessengerController::storeImageToCache] No chat.");
    return QString();
  }

  const auto encryptedName = Utils::from_base64(dir_row_result->name);
  const auto decrypted = Cryptography::symmetric_decrypt(
      ByteArray(encryptedName.value()).toBytes(),
      Dfs::DataSecurityKey{.key = chat->chat_key}.key);
  const QString nameFile =
      QString::fromUtf8(reinterpret_cast<const char *>(decrypted->data()),
                        static_cast<int>(decrypted->size()));
  return nameFile;
}

void MessengerController::exportFile(const QString &message,
                                     const QString &export_path) {
  auto fileParts = message.split(QRegularExpression(R"([\\/])"));
  if (fileParts.size() != 3) {
    emit error("Export failed. Please try again or check your export path.");
    eLog("Export failed. Please try again or check your export path.", message,
         export_path);
    return;
  }

  ActorId actorId(fileParts.at(1).toStdString());
  auto fileId = fileParts.at(2).toStdString();

  auto dir_row_result = Dfs::Tables::DirsFile::ActorSpace::get_dir_row(
      node->dfs()->get_db_instance(), actorId, fileId);
  if (!dir_row_result.has_value())
    return;

  QString name_file = QString::fromStdString(dir_row_result->name);
  const auto chat = node->chat_manager()->get_chat(
      ActorId(_current_owner_id.toStdString()), _current_file_id.toStdString());
  if (!chat) {
    eLog("[MessengerController::storeImageToCache] No chat.");
    return;
  }

  const auto encryptedName = Utils::from_base64(dir_row_result->name);
  const auto decrypted = Cryptography::symmetric_decrypt(
      ByteArray(encryptedName.value()).toBytes(),
      Dfs::DataSecurityKey{.key = chat->chat_key}.key);
  const QString nameFile =
      QString::fromUtf8(reinterpret_cast<const char *>(decrypted->data()),
                        static_cast<int>(decrypted->size()));

  QString exportPath =
      QString::fromStdString(Dfs::Path::filePath(actorId, fileId).string())
          .replace("\\", "/");

  auto fs_path = FsPath::create(export_path.toStdString());
  if (!fs_path.has_value())
    return;

  auto isExported =
      export_file(actorId, fileId, fs_path.value(), nameFile.toStdString(),
                  Dfs::DataSecurityKey{.key = chat->chat_key});

  if (isExported.has_value()) {
    emit exported(
        QString("The file has been exported to: %1").arg(export_path));
  } else {
    emit error("Failed to export the file.");
  }
}

QString MessengerController::storeImageToCache(const QString &messageData,
                                               const bool &isBlurState) {
  QMap<QString, QVariant> map;

  QJsonParseError parseError;
  QJsonDocument doc =
      QJsonDocument::fromJson(messageData.toUtf8(), &parseError);

  if (parseError.error == QJsonParseError::NoError && doc.isObject()) {
    QJsonObject obj = doc.object();
    map = obj.toVariantMap();
    // for (auto it = map.begin(); it != map.end(); ++it) {
    //     qDebug() << it.key() << ":" << it.value();
    // }
  } else {
    return QString("KEIEb8o#0KMwoeWB4Tj@ax");
  }
  if (isBlurState) {
    if (!map["hash"].isNull())
      return map["hash"].toString();
    return QString("KEIEb8o#0KMwoeWB4Tj@ax");
  }

  if (map["path"].isNull())
    return QString();

  QString message = map["path"].toString();

  const QStringList parts = message.split(QRegularExpression(R"([\\/])"));
  if (parts.size() != 3) {
    eLog("Can not parse message.", message);
    return QString();
  }
  const ActorId actorId(parts[1].toStdString());
  const QString fileId = parts[2];

  const QString relativePath =
      QString::fromStdString(
          Dfs::Path::filePath(actorId, fileId.toStdString()).string())
          .replace("\\", "/");

  const QString fullPath = QDir::currentPath() + "/" + relativePath;
  const QString fileUrl = QUrl::fromLocalFile(fullPath).toString();

  const auto dirRow = Dfs::Tables::DirsFile::ActorSpace::get_dir_row(
      node->dfs()->get_db_instance(), actorId, fileId.toStdString());
  if (!dirRow) {
    eLog("[MessengerController::storeImageToCache] Can not get dir row.");
    return QString();
  }

  const auto chat = node->chat_manager()->get_chat(
      ActorId(_current_owner_id.toStdString()), _current_file_id.toStdString());
  if (!chat) {
    eLog("[MessengerController::storeImageToCache] No chat.");
    return QString();
  }

  const auto encryptedName = Utils::from_base64(dirRow->name);
  const auto decrypted = Cryptography::symmetric_decrypt(
      ByteArray(encryptedName.value()).toBytes(),
      Dfs::DataSecurityKey{.key = chat->chat_key}.key);

  if (!decrypted) {
    eLog("[MessengerController::storeImageToCache] Not decrypted file name.");
    return QString();
  }

  const QString nameFile =
      QString::fromUtf8(reinterpret_cast<const char *>(decrypted->data()),
                        static_cast<int>(decrypted->size()));

  const QString extension = QFileInfo(nameFile).suffix();
  const QString tempFilePath =
      QString("tmp/files/dfs/%1/%2").arg(actorId.toQString(), nameFile);
  const QString absTempFilePath = QDir::currentPath() + "/" + tempFilePath;

  if (QFile::exists(absTempFilePath)) {
    eLog("[MessengerController::storeImageToCache] {}",
         fmt::format("File already exists: {}", absTempFilePath));
    return QUrl::fromLocalFile(absTempFilePath).toString();
  }

#ifdef Q_OS_ANDROID
  const bool unsupported = true;
#else
  const bool unsupported = false;
#endif

  if (unsupported || nameFile == "." ||
      !QStringList{"png", "jpg", "jpeg", "gif"}.contains(extension,
                                                         Qt::CaseInsensitive)) {
    eLog("[MessengerController::storeImageToCache] {}",
         fmt::format("Unsupported extension: {}", extension));
    return QString();
  }

  const QString exportDir =
      QDir::currentPath() + "/tmp/files/dfs/" + actorId.toQString();
  QDir dir;
  if (!dir.exists(exportDir) && !dir.mkpath(exportDir)) {
    eLog("[MessengerController::storeImageToCache] {}",
         fmt::format("Failed to create directory {}", exportDir));
    return QString();
  }

  const auto fsPath = FsPath::create(exportDir.toStdString());
  if (!fsPath) {
    eLog("[MessengerController::storeImageToCache] {}",
         fmt::format("Invalid create FsPath"));

    return QString();
  }

  const auto exportRes = export_file(
      actorId, fileId.toStdString(), fsPath.value(), nameFile.toStdString(),
      Dfs::DataSecurityKey{.key = chat->chat_key});
  if (exportRes) {
    eLog("[MessengerController::storeImageToCache] {}",
         fmt::format("Export successful: {}",
                     QUrl::fromLocalFile(absTempFilePath).toString()));
    return QUrl::fromLocalFile(absTempFilePath).toString();
  }

  qDebug() << (int)exportRes.error() << actorId.toQString()
           << fileId.toStdString() << fsPath.value().filename().value()
           << absTempFilePath;
  eLog("Export file failed.");
  return QString();
}

int MessengerController::heightHashBlur(const QString &messageData) {
  QMap<QString, QVariant> map;

  QJsonParseError parseError;
  QJsonDocument doc =
      QJsonDocument::fromJson(messageData.toUtf8(), &parseError);

  if (parseError.error == QJsonParseError::NoError && doc.isObject()) {
    QJsonObject obj = doc.object();
    map = obj.toVariantMap();
  } else {
    // qDebug() << "Failed to parse JSON:" << parseError.errorString();
    return 50;
  }
  return map["height"].toInt();
}

int MessengerController::widthHashBlur(const QString &messageData) {
  QMap<QString, QVariant> map;

  QJsonParseError parseError;
  QJsonDocument doc =
      QJsonDocument::fromJson(messageData.toUtf8(), &parseError);

  if (parseError.error == QJsonParseError::NoError && doc.isObject()) {
    QJsonObject obj = doc.object();
    map = obj.toVariantMap();
  } else {
    qDebug() << "Failed to parse JSON:" << parseError.errorString();
    return 50;
  }
  return map["width"].toInt();
}

void MessengerController::updateCacheInput(const QString &cahtId,
                                           const QString &message) {
  _cacheInputMessages.insert(cahtId, message);
}

QString MessengerController::getCachedMessage(const QString &chatId) const {
  return _cacheInputMessages.value(chatId);
}

void MessengerController::addFiles(const QStringList &files,
                                   const bool messenger_send_as_file,
                                   const QString &chatId,
                                   const QString &replyMessageId,
                                   const QString &caption) {

  if (files.isEmpty())
    return;

  const QString &file = files.first();
  auto mainId = node->account_controller()->current_profile().main_id();
  auto chat = this->node->chat_manager()->get_chat(
      ActorId(_current_owner_id.toStdString()), _current_file_id.toStdString());

  auto dataSecurity = Dfs::DataSecurityKey{.key = chat.value().chat_key};

  // Define file processing function
  auto processFile = [this, file, mainId, dataSecurity, &messenger_send_as_file,
                      &replyMessageId, &caption]() {
    try {
      QString filePath = file;

#ifdef Q_OS_ANDROID
      auto tempPath =
          "tmp/" + QString::number(QRandomGenerator::global()->bounded(1000) +
                                   QDateTime::currentMSecsSinceEpoch());
      QFile::copy(file, tempPath);
      filePath = tempPath;
#endif

      auto result = node->dfs()->store_file(
          mainId, mainId, filePath.toStdWString(), Dfs::ServiceFolder::Chat,
          QFileInfo(file).fileName().toStdString(), Dfs::DataSecurity::Key,
          dataSecurity);
#ifdef Q_OS_ANDROID
      QFile::remove(tempPath);
#endif

      QString message = result.has_value()
                            ? "File added"
                            : QString::fromStdString(fmt::format(
                                  "Add Files Error: {}", result.error()));
      qDebug() << "Message add " << message;
      if (result.has_value()) {
        const auto &value = result.value();
        const QString dfsPath = QString::fromStdWString(
            DfsB::fsActrRootW + DfsB::separator +
            value.actor_id.toQString().toStdWString() + DfsB::separator +
            QString::fromStdString(value.file_id).toStdWString());
        emit messengerAddedFile(dfsPath, file, messenger_send_as_file,
                                replyMessageId, caption);
      }
    } catch (const std::exception &e) {
      QMetaObject::invokeMethod(
          this, [this, file, e]() {}, Qt::QueuedConnection);
    }
  };

  if (QFileInfo(file).size() > 5 * 1024 * 1024) {
    QThreadPool::globalInstance()->start(processFile);
  } else {
    processFile();
  }
}

std::expected<void, ExportFileError> MessengerController::export_file(
    const ActorId &owner_id, const std::string &file_id,
    const FsPath &output_folder, const std::string &name_file,
    const Dfs::DataSecurityKey &dsk) {
  if (!output_folder.exists()) {
    return std::unexpected(ExportFileError::OutupDirNotExits);
  }

  auto is_dir = output_folder.is_directory();
  if (!is_dir.has_value()) {
    return std::unexpected(ExportFileError::OutupDirNotExits);
  }
  if (!is_dir.value()) {
    return std::unexpected(ExportFileError::OutupDirNotExits);
  }

  auto has_write_perm = output_folder.has_write_permission();
  if (!has_write_perm.has_value()) {
    return std::unexpected(ExportFileError::NoWritePermissions);
  }
  if (!has_write_perm.value()) {
    return std::unexpected(ExportFileError::NoWritePermissions);
  }

  auto dir_row_result = Dfs::Tables::DirsFile::ActorSpace::get_dir_row(
      node->dfs()->get_db_instance(), owner_id, file_id);

  if (!dir_row_result.has_value()) {
    return std::unexpected(ExportFileError::DirRowNotExists);
  }

  if (dir_row_result->state != Dfs::FileState::Ready) {
    return std::unexpected(ExportFileError::FileNotReadyState);
  }

  auto dfs_path_result = Dfs::Path::file_path(owner_id, file_id);
  if (!dfs_path_result.has_value()) {
    return std::unexpected(ExportFileError::IncorrectDfsPath);
  }

  auto dfs_path = dfs_path_result.value();
  if (!dfs_path.exists()) {
    return std::unexpected(ExportFileError::LocalFileNotExists);
  }

  bool is_downloaded = node->dfs()->is_file_already_downloaded(
      owner_id, file_id, dir_row_result->hash);
  if (!is_downloaded) {
    return std::unexpected(ExportFileError::LocalFileNotValid);
  }

  auto output_path = output_folder;

  if (dir_row_result->encryption) {
    output_path.append("/");
    output_path.append(name_file);

    auto decrypt_result =
        Cryptography::symmetric_decrypt_file(dfs_path, output_path, dsk.key);
    if (!decrypt_result.has_value()) {
      return std::unexpected(ExportFileError::Unknown);
    }
    return {};
  }

  output_path.append(dir_row_result->name);
  if (output_path.exists()) {
    return std::unexpected(ExportFileError::OutputFileExists);
  }

  try {
    std::filesystem::copy(dfs_path.native(), output_path.native());
  } catch (const std::filesystem::filesystem_error &e) {
    return std::unexpected(ExportFileError::CopyError);
  }

  return {};
}

void MessengerController::getIndexByMessageId(const QString &messageId) {
  int res = -1;
  for (int i = 0; i < _chatModel->rowCount(); ++i) {
    const QVariantMap rowData = _chatModel->get(i);
    if (rowData.value("messageId").toString() == messageId) {
      qDebug() << "searched message id " << i << messageId;
      res = i;
      break;
    }
  }
  qDebug() << "Send signal to move list view on index" << res << messageId;
  if (res != -1)
    emit moveToIndex(res);

  emit runAnimation(res);
}

static const char *characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij"
                                "klmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~";

static int intPow(int base, int exp) {
  int result = 1;
  while (exp-- > 0)
    result *= base;
  return result;
}

static QString encodeBase83(int value, int length) {
  QString result;
  for (int i = 1; i <= length; ++i) {
    int digit = (value / intPow(83, length - i)) % 83;
    result += characters[digit];
  }
  return result;
}

static float linearToSrgb(float value) {
  if (value <= 0.0031308f)
    return value * 12.92f;
  else
    return 1.055f * qPow(value, 1.0f / 2.4f) - 0.055f;
}

static int encodeDC(const QVector3D &color) {
  auto r = qBound(0, int(linearToSrgb(color.x()) * 255 + 0.5f), 255);
  auto g = qBound(0, int(linearToSrgb(color.y()) * 255 + 0.5f), 255);
  auto b = qBound(0, int(linearToSrgb(color.z()) * 255 + 0.5f), 255);
  return (r << 16) + (g << 8) + b;
}

static QVector3D decodePixel(const QRgb &pixel) {
  auto r = qRed(pixel) / 255.0f;
  auto g = qGreen(pixel) / 255.0f;
  auto b = qBlue(pixel) / 255.0f;

  auto linear = [](float val) {
    if (val <= 0.04045f)
      return val / 12.92f;
    return qPow((val + 0.055f) / 1.055f, 2.4f);
  };

  return {linear(r), linear(g), linear(b)};
}

QString BlurHashEncoder::encode(const QImage &image, int componentsX,
                                int componentsY) {
  QImage img = image.convertToFormat(QImage::Format_RGB32);
  int width = img.width();
  int height = img.height();

  QVector<QVector3D> factors;
  for (int y = 0; y < componentsY; ++y) {
    for (int x = 0; x < componentsX; ++x) {
      float normalisation = (x == 0 && y == 0) ? 1.0f : 2.0f;
      QVector3D sum(0, 0, 0);
      for (int j = 0; j < height; ++j) {
        for (int i = 0; i < width; ++i) {
          float basis =
              qCos(M_PI * x * i / width) * qCos(M_PI * y * j / height);
          sum += decodePixel(img.pixel(i, j)) * basis;
        }
      }
      sum *= normalisation / (width * height);
      factors.append(sum);
    }
  }

  QString hash;
  hash += encodeBase83((componentsX - 1) + (componentsY - 1) * 9, 1);

  float maxAc = 0.0f;
  for (int i = 1; i < factors.size(); ++i) {
    const QVector3D &f = factors[i];
    maxAc =
        std::max(maxAc, std::max(std::abs(f.x()),
                                 std::max(std::abs(f.y()), std::abs(f.z()))));
  }

  int quantMaxAc = qBound(0, int(maxAc * 166 - 0.5f), 82);
  hash += encodeBase83(quantMaxAc, 1);

  hash += encodeBase83(encodeDC(factors[0]), 4);

  float normalizer = (quantMaxAc == 0) ? 1.0f : (quantMaxAc / 166.0f);

  for (int i = 1; i < factors.size(); ++i) {
    QVector3D f = factors[i] / normalizer;

    auto quant = [](float val) { return qBound(-9, int(qRound(val * 9)), 9); };

    int r = quant(f.x());
    int g = quant(f.y());
    int b = quant(f.z());
    int acValue = (r + 9) * 19 * 19 + (g + 9) * 19 + (b + 9);
    hash += encodeBase83(acValue, 2);
  }

  return hash;
}
