#pragma once
#include <QObject>
#include <QString>

class AndroidUtils : public QObject {
    Q_OBJECT
public:
    explicit AndroidUtils(QObject *parent = nullptr);
    // Existing methods
    Q_INVOKABLE void shareFile(const QString &filePath);
    static bool      isTablet();
    static void      setOrientationBasedOnDeviceType();
    // Power management
    static void setWakeLock(bool active);
    static bool requestBatteryOptimizationExemption();
    static bool isBatteryOptimizationExempted();
    // Network methods
    static void registerNetworkCallback();
    static void unregisterNetworkCallback();
    // WebSocket support
    static void enableWebSocketKeepAlive();
    // VPN methods
    static void startVpnService(const QString &privateKey,
                                const QString &ip,
                                const QString &endpoint,
                                const QString &publicKey,
                                const QString &allowedIps);
    static void stopVpnService();
    // Initialization and cleanup
    static void initialize();
    static void cleanup();
    static void setupStatusBar();
    static int  getStatusBarHeight();
};
