#pragma once

#include <QString>
#include <boost/describe.hpp>
#include <memory>

class QNetworkAccessManager;
class QNetworkReply;
class ClientController;

struct UpdaterVersion {
  std::string version;
};
BOOST_DESCRIBE_STRUCT(UpdaterVersion, (), (version))

class Updater {
public:
  Updater(ClientController *clientController = nullptr);
  ~Updater();

  std::pair<bool, std::string> checkForUpdates();
  void downloadUpdate(const std::string &version);
  void update();
  void install();
  void patchUpdate();

private:
  bool getLatestVersion();
  void downloadFile(const QString &url, const QString &fileName);
  bool downloadFileSync(const QString &url, const QString &fileName);

  bool compareVersions(const std::string &current, const std::string &latest);

  std::unique_ptr<QNetworkAccessManager> networkManager;
  std::string onlineVersion;

  ClientController *clientController;

  const QString clientType = "app";

  const QString os =
#ifdef Q_OS_WINDOWS
      "WINDOWS";
#elif defined(Q_OS_ANDROID)
      "ANDROID";
  QString savedApkPath;
#elif defined(Q_OS_IOS)
      "IOS";
#elif defined(Q_OS_MACOS)
      "MAC";
#elif defined(Q_OS_LINUX)
#ifdef EXTRACHAIN_CLIENT_CONSOLE
      "MINING_LINUX_CLIENT_ARCHIVE";
#else
      "LINUX";
#endif
#else
      "UNKNOWN";
#endif
};
