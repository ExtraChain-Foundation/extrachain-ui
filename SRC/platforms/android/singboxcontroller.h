#ifndef SINGBOXCONTROLLER_H
#define SINGBOXCONTROLLER_H

#include <QObject>
#include <QJniObject>
#include <QJniEnvironment>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QTimer>

#include "utils/exc_logs.h"

class SingBoxController : public QObject
{
    Q_OBJECT

public:
    explicit SingBoxController(QObject *parent = nullptr);
    ~SingBoxController();

    static void registerQmlType();

    // Core VPN methods
    bool startVpn(const std::string& interfaceLocalIP, const std::string& peerPublicKey,
                     const std::string& peerShortID, const std::string& peerPublicIP, const int peerPublicPort, const std::string& uuid);
    bool stopVpn();
    bool isVpnRunning();
    QString getTrafficStats();

signals:
    void vpnStatusChanged(bool isRunning);
    void trafficUpdated(const QString &trafficJson);
    void errorOccurred(const QString &errorMessage);
    void permissionResult(bool granted);
    void closeApp();

private slots:
    void checkPermissionResult();

private:
    bool initialize();
    bool hasVpnPermission();
    bool requestVpnPermission();
    std::string_view createConfig();

    bool initializeJni();
    void cleanup();
    QJniObject getAndroidContext();
    QJniObject getAndroidActivity();
    void startPermissionPolling();

    QJniObject m_jniObject;
    bool m_initialized;
    QTimer *m_permissionCheckTimer;

    static const char* JNI_CLASS_NAME;
};

#endif // SINGBOXCONTROLLER_H
