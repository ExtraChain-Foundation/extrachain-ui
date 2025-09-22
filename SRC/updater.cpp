
#include "updater.h"

#include <QCoreApplication>
#include <QDir>
#include <QEventLoop>
#include <QFile>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QProcess>
#include <QSettings>

#include "raccoon_version.h"
#include "utils/exc_utils.h"

#ifndef RACCOON_CLIENT_CONSOLE
#include "SRC/ClientController.h"
#endif

#if !defined(Q_OS_DEBUG) && defined(Q_OS_MACOS)
#include "MacOs/MacosUtils.h"
#endif

Updater::Updater(ClientController *clientController)
    : networkManager(std::make_unique<QNetworkAccessManager>()),
      clientController(clientController) {}

Updater::~Updater() = default;

std::pair<bool, std::string> Updater::checkForUpdates() {
  QFile::remove("RaccoonLine_Updater.exe");
#ifdef QT_DEBUG
  return {false, ""};
#endif

  this->patchUpdate();

  auto isLatestVersion = this->getLatestVersion();
  if (!isLatestVersion) {
    return {false, ""};
  }

  if (onlineVersion.empty()) {
    return {false, ""};
  }

  bool compare = compareVersions(raccoon_version, onlineVersion);
  return {compare, onlineVersion};
}

bool Updater::getLatestVersion() {
  if (os == "UNKNOWN") {
    return false;
  }

  QNetworkRequest request(QUrl("https://raccoonline.com/api/" + clientType +
                               "/actual-version?app_system=" + os));
  QNetworkReply *reply = networkManager->get(request);

  QEventLoop loop;
  QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
  loop.exec();

  if (reply->error() != QNetworkReply::NoError) {
    eCritical("[Updater] Network error: {}", reply->errorString());
    return false;
  }

  std::string jsonResponse = reply->readAll().toStdString();
  reply->deleteLater();

  auto version = Json::deserialize<UpdaterVersion>(jsonResponse);
  if (!version.has_value()) {
    return false;
  }

  onlineVersion = version->version;
  return true;
}

void Updater::downloadUpdate(const std::string &version) {
#ifdef Q_OS_WINDOWS
  QString url =
      QString(
          "https://raccoonline.com/api/assets/apps/RaccoonLine_Setup_%1.exe")
          .arg(QString::fromStdString(version));

  this->downloadFile(url, "RaccoonLine_Updater.exe");
  return;
#endif

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
  QString arch = "";
#if defined(__aarch64__) || defined(__arm64__)
  arch = "_arm64";
#endif

  const char *appName =
#ifdef RACCOON_CLIENT_CONSOLE
      "ExtraChain_Console";
#else
      "ExtraChain";
#endif

  QString url =
      QString("https://raccoonline.com/api/assets/apps/%1_%2%3.tar.gz")
          .arg(appName)
          .arg(QString::fromStdString(version))
          .arg(arch);

#ifdef RACCOON_CLIENT_CONSOLE
  this->downloadFileSync(url, "RaccoonLine_Update.tar.gz");
#else
  this->downloadFile(url, "RaccoonLine_Update.tar.gz");
#endif

#endif
}

void Updater::update() {
#ifdef QT_DEBUG
  return;
#endif

#ifdef Q_OS_MACOS
  eLog("[Updater] Start Sparkle");
  ApplePlatformUtils::init_sparkle();
  return;
#endif

#ifdef Q_OS_WINDOWS
  eInfo("[Updater] Downloading update...");
  this->downloadUpdate(onlineVersion);
#endif

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
  eInfo("[Updater] Downloading update...");
  this->downloadUpdate(onlineVersion);
#endif
}

void Updater::install() {
#ifdef Q_OS_WINDOWS
  QString updaterPath = QDir::currentPath() + "/RaccoonLine_Updater.exe";
  QFile updaterFile(updaterPath);

  if (updaterFile.exists() && updaterFile.size() != 0) {
    QProcess::startDetached("RaccoonLine_Updater.exe");
    std::exit(0);
  }
#endif

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
  QString binPath = QCoreApplication::applicationDirPath();
  QString updaterPath = QDir::currentPath() + "/RaccoonLine_Update.tar.gz";
  if (QFile::exists(updaterPath)) {
    eInfo("Extract archive...");
    QStringList tarArgs;
    tarArgs << "-xzf" << updaterPath;

#ifdef RACCOON_CLIENT_CONSOLE
    tarArgs << "-C" << binPath;
#else
    tarArgs << "-C" << QDir(binPath).absoluteFilePath("..");
#endif

    if (QProcess::execute("tar", tarArgs) != 0) {
      eInfo("Failed to extract update archive: {}", updaterPath);
      return;
    }

    eInfo("Done. Please, restart");
    QFile::remove(updaterPath);
    std::exit(0);
  }
#endif
}

void Updater::patchUpdate() {
  QSettings settings;
  QString savedVersion = settings.value("RaccoonVersionPatch").toString();

  if (savedVersion.isEmpty() ||
      compareVersions(savedVersion.toStdString(), raccoon_version)) {
    eLog("[Updater] Patch version... {}", os);

    QString url = "https://raccoonline.com/api/" + clientType +
                  "/increment-statistic?app_system=" + os;
    QNetworkAccessManager *manager = new QNetworkAccessManager();
    QNetworkRequest request(url);
    QNetworkReply *reply = manager->sendCustomRequest(request, "PATCH");

    QObject::connect(reply, &QNetworkReply::finished, [=]() {
      if (reply->error() == QNetworkReply::NoError) {
        eLog("[Updater] Data updated successfully");

        QSettings settings;
        settings.setValue("RaccoonVersionPatch",
                          QString::fromStdString(raccoon_version));
        settings.sync();
      } else {
        eLog("[Updater] Failed to update data: {}", reply->errorString());
      }

      reply->deleteLater();
      manager->deleteLater();
    });
  }
}

void Updater::downloadFile(const QString &url, const QString &fileName) {
  QObject *helper = new QObject();

  QNetworkRequest request(url);
  QNetworkReply *reply = networkManager->get(request);

  QFile *file = new QFile(fileName);
  if (!file->open(QIODevice::WriteOnly)) {
    reply->deleteLater();
    delete file;
    delete helper;

#ifndef RACCOON_CLIENT_CONSOLE
    emit clientController->updaterDownloadFinished(false);
#endif
    return;
  }

  ClientController *controller = clientController;

#ifndef RACCOON_CLIENT_CONSOLE
  QObject::connect(reply, &QNetworkReply::downloadProgress, controller,
                   &ClientController::updaterDownloadProgress);
#endif

  QObject::connect(reply, &QNetworkReply::readyRead, helper, [reply, file]() {
    file->write(reply->readAll());
    file->flush();
  });

  QObject::connect(reply, &QNetworkReply::finished, helper,
                   [reply, file, controller, helper]() {
                     bool success = (reply->error() == QNetworkReply::NoError);

                     if (success) {
                       file->write(reply->readAll());
                     }

                     file->close();
                     delete file;
                     reply->deleteLater();
                     delete helper;

#ifndef RACCOON_CLIENT_CONSOLE
                     emit controller->updaterDownloadFinished(success);
#endif
                   });
}

bool Updater::downloadFileSync(const QString &url, const QString &fileName) {
  QNetworkRequest request(url);
  QNetworkReply *reply = networkManager->get(request);

  QEventLoop loop;
  QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
  loop.exec();

  if (reply->error() != QNetworkReply::NoError) {
    reply->deleteLater();
    return false;
  }

  QFile file(fileName);
  if (!file.open(QIODevice::WriteOnly)) {
    reply->deleteLater();
    return false;
  }

  file.write(reply->readAll());
  file.close();
  reply->deleteLater();

  return true;
}

bool Updater::compareVersions(const std::string &current,
                              const std::string &latest) {
  return Utils::is_newer_version(current, latest);
}
