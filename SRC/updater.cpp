
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

#include "extrachain_version.h"
#include "utils/exc_utils.h"

#ifndef RACCOON_CONSOLE
#include "SRC/ClientController.h"
#endif

#if !defined(Q_OS_DEBUG) && defined(Q_OS_MACOS)
#include "MacOs/MacosUtils.h"
#endif

#ifdef Q_OS_ANDROID
#include <QStandardPaths>

#include "SRC/platforms/android/androidutils.h"
#endif

Updater::Updater(ClientController *clientController)
    : networkManager(std::make_unique<QNetworkAccessManager>()),
      clientController(clientController) {}

Updater::~Updater() = default;

std::pair<bool, std::string> Updater::checkForUpdates() {
  QFile::remove("ExtraChain_Updater.exe");
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

  bool compare = compareVersions(extrachain_version, onlineVersion);
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
      QString("https://extrachain.com/api/assets/apps/ExtraChain_Setup_%1.exe")
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
#ifdef EXTRACHAIN_CLIENT_CONSOLE
      "ExtraChain_Console";
#else
      "Extrachain";
#endif

  QString url =
      QString("https://raccoonline.com/api/assets/apps/%1_%2%3.tar.gz")
          .arg(appName)
          .arg(QString::fromStdString(version))
          .arg(arch);

#ifdef RACCOON_CLIENT_CONSOLE
  this->downloadFileSync(url, "ExtraChain_Update.tar.gz");
#else
  this->downloadFile(url, "ExtraChain_Update.tar.gz");
#endif
#endif

#ifdef Q_OS_ANDROID
  QString apkFile = QString("android-build-ExtraChain-release-signed-%1.apk")
                        .arg(QString::fromStdString(version));
  QString url = QString("https://extrachain.com/api/assets/apps/") + apkFile;

  this->downloadFile(url, apkFile);
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

#if defined(Q_OS_WINDOWS) || defined(Q_OS_LINUX) || defined(Q_OS_ANDROID)
  eInfo("[Updater] Downloading update...");
  this->downloadUpdate(onlineVersion);
#endif
}

void Updater::install() {
#ifdef Q_OS_WINDOWS
  QString updaterPath = QDir::currentPath() + "/ExtraChain_Updater.exe";
  QFile updaterFile(updaterPath);

  if (updaterFile.exists() && updaterFile.size() != 0) {
    QProcess::startDetached("ExtraChain_Updater.exe");
    std::exit(0);
  }
#endif

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
  QString binPath = QCoreApplication::applicationDirPath();
  QString updaterPath = QDir::currentPath() + "/ExtraChain_Update.tar.gz";
  if (QFile::exists(updaterPath)) {
    eInfo("Extract archive...");
    QStringList tarArgs;
    tarArgs << "-xzf" << updaterPath;

#ifdef RACCOON_CONSOLE
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

#ifdef Q_OS_ANDROID
  if (!savedApkPath.isEmpty() && QFile::exists(savedApkPath)) {
    AndroidUtils::installApk(savedApkPath);
  }
#endif
}

void Updater::patchUpdate() {
  QSettings settings;
  QString savedVersion = settings.value("ExtraChainVersionPatch").toString();

  if (savedVersion.isEmpty() ||
      compareVersions(savedVersion.toStdString(), extrachain_version)) {
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
        settings.setValue("ExtraChainVersionPatch",
                          QString::fromStdString(extrachain_version));
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

#ifdef Q_OS_ANDROID
  QString androidPath =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
  QDir().mkpath(androidPath);
  savedApkPath = androidPath + "/" + fileName;
  QFile *file = new QFile(savedApkPath);
#else
  QFile *file = new QFile(fileName);
#endif

  if (!file->open(QIODevice::WriteOnly)) {
    reply->deleteLater();
    delete file;
    delete helper;
#ifndef RACCOON_CONSOLE
    emit clientController->updaterDownloadFinished(false);
#endif
    return;
  }

  ClientController *controller = clientController;

#ifndef RACCOON_CONSOLE
  QObject::connect(reply, &QNetworkReply::downloadProgress, controller,
                   &ClientController::updaterDownloadProgress);
#endif

  QObject::connect(reply, &QNetworkReply::readyRead, helper, [=]() {
    file->write(reply->readAll());
    file->flush();
  });

  QObject::connect(reply, &QNetworkReply::finished, helper, [=]() {
    bool success = (reply->error() == QNetworkReply::NoError);

    if (success) {
      file->write(reply->readAll());
    }

    file->close();
    delete file;
    reply->deleteLater();
    delete helper;

#ifndef RACCOON_CONSOLE
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
