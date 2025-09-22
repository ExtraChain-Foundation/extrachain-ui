#include "singboxcontroller.h"
#include <QQmlEngine>
#include <QTimer>
#include <QGuiApplication>

#include <boost/json.hpp>

const char* SingBoxController::JNI_CLASS_NAME = "com/raccoonline/vpnapp/SingBoxJNI";

void SingBoxController::registerQmlType() {
    qmlRegisterType<SingBoxController>("SingBox", 1, 0, "SingBoxController");
}

SingBoxController::SingBoxController(QObject* parent)
    : QObject(parent)
    , m_initialized(false)
    , m_permissionCheckTimer(nullptr) {
    connect(this, &SingBoxController::permissionResult, [&](bool granted) {
        if (granted)
            eDebug("SingBoxController::permissionResult callback, permissions granted!");
        else {
            eDebug("SingBoxController::permissionResult callback, permissions not granted!");
            // QGuiApplication::quit();
            emit closeApp();
        }
    });

    // Constructor - initialization will be done manually
    QTimer::singleShot(1000, [&]() {
        eDebug("SingBoxController::SingBoxController, Testing SingBox controller initialization...");
        if (initialize()) {
            eDebug("SingBoxController::SingBoxController, SingBox controller initialized successfully");

            // Test VPN permission check
            bool hasPermission = hasVpnPermission();
            if (!hasPermission)
            {
                bool result = requestVpnPermission();
                if (!result)
                    QGuiApplication::quit();
            }
            else
                eDebug("SingBoxController::SingBoxController, VPN permission status: {}", hasPermission);

        } else {
            eDebug("SingBoxController::SingBoxController, Failed to initialize SingBox controller");
        }
    });
}

SingBoxController::~SingBoxController()
{
    cleanup();
    if (m_permissionCheckTimer) {
        m_permissionCheckTimer->stop();
        delete m_permissionCheckTimer;
    }
}

bool SingBoxController::initialize()
{
    if (m_initialized) {
        return true;
    }

    return initializeJni();
}

QJniObject SingBoxController::getAndroidContext()
{
    // Try multiple methods for Qt 6.9.0 compatibility
    QJniObject context;

    // Method 1: Try getContext()
    context = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "getContext",
        "()Landroid/content/Context;"
        );

    if (context.isValid()) {
        return context;
    }

    // Method 2: Try through activity
    QJniObject activity = getAndroidActivity();
    if (activity.isValid()) {
        context = activity.callObjectMethod(
            "getApplicationContext",
            "()Landroid/content/Context;"
            );
        if (context.isValid()) {
            return context;
        }
    }

    // Method 3: Try getting application context directly
    QJniObject application = QJniObject::callStaticObjectMethod(
        "android/app/ActivityThread",
        "currentApplication",
        "()Landroid/app/Application;"
        );

    if (application.isValid()) {
        context = application.callObjectMethod(
            "getApplicationContext",
            "()Landroid/content/Context;"
            );
    }

    return context;
}

QJniObject SingBoxController::getAndroidActivity()
{
    // Try multiple methods for Qt 6.9.0 compatibility
    QJniObject activity;

    // Method 1: Try getActivity()
    activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "getActivity",
        "()Landroid/app/Activity;"
        );

    if (activity.isValid()) {
        return activity;
    }

    // Method 2: Try activity() (older method)
    activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;"
        );

    return activity;
}

bool SingBoxController::initializeJni()
{
    QJniEnvironment env;

    // Create JNI object
    m_jniObject = QJniObject(JNI_CLASS_NAME);

    if (!m_jniObject.isValid()) {
        eCritical("SingBoxController::initializeJni, Failed to create SingBoxJNI object");
        emit errorOccurred("Failed to create SingBoxJNI object");
        return false;
    }

    // For Qt 6.9.0, delay context initialization until actually needed
    m_initialized = true;
    eDebug("SingBoxController::initializeJni, SingBox JNI object created successfully (context will be initialized when needed)");
    return true;
}

bool SingBoxController::hasVpnPermission()
{
    if (!m_initialized && !initialize()) {
        return false;
    }

    QJniEnvironment env;

    // Get context when we actually need it
    QJniObject context = getAndroidContext();
    if (!context.isValid()) {
        eWarning("SingBoxController::hasVpnPermission, Could not get Android context for permission check");
        emit errorOccurred("Could not get Android context");
        return false;
    }

    // Initialize the Java manager if not done yet
    m_jniObject.callMethod<void>("initialize", "(Landroid/content/Context;)V", context.object());

    if (env.checkAndClearExceptions()) {
        eWarning("SingBoxController::hasVpnPermission, Failed to initialize Java manager");
        return false;
    }

    bool hasPermission = m_jniObject.callMethod<jboolean>(
        "hasVpnPermission",
        "(Landroid/content/Context;)Z",
        context.object()
        );

    if (env.checkAndClearExceptions()) {
        eWarning("SingBoxController::hasVpnPermission, Failed to check VPN permission");
        return false;
    }

    eDebug("SingBoxController::hasVpnPermission, VPN and all permissions status: {}", hasPermission);
    return hasPermission;
}

bool SingBoxController::requestVpnPermission()
{
    if (!m_initialized && !initialize()) {
        return false;
    }

    QJniEnvironment env;
    QJniObject activity = getAndroidActivity();

    if (!activity.isValid()) {
        emit errorOccurred("No active Android activity found");
        return false;
    }

    bool result = m_jniObject.callMethod<jboolean>(
        "requestVpnPermission",
        "(Landroid/app/Activity;)Z",
        activity.object()
        );

    if (env.checkAndClearExceptions()) {
        eWarning("SingBoxController::requestVpnPermission, Failed to request VPN permission");
        emit errorOccurred("Failed to request VPN permission");
        return false;
    }

    if (result) {
        eDebug("SingBoxController::requestVpnPermission, Permission request initiated, starting polling");
        // Start polling for permission result
        startPermissionPolling();
    } else {
        eDebug("SingBoxController::requestVpnPermission, permissions already granted");
        // If no request was needed, emit success
        emit permissionResult(true);
    }

    return result;
}

void SingBoxController::startPermissionPolling()
{
    if (!m_permissionCheckTimer) {
        m_permissionCheckTimer = new QTimer(this);
        connect(m_permissionCheckTimer, &QTimer::timeout, this, &SingBoxController::checkPermissionResult);
    }

    m_permissionCheckTimer->start(500); // Check every 500ms
}

void SingBoxController::checkPermissionResult()
{
    if (!m_initialized || !m_jniObject.isValid()) {
        return;
    }

    QJniEnvironment env;

    // Check if still waiting
    bool isWaiting = m_jniObject.callMethod<jboolean>("isWaitingForPermissionResult", "()Z");

    if (env.checkAndClearExceptions()) {
        eWarning("SingBoxController::checkPermissionResult, Failed to check permission waiting status");
        return;
    }

    if (!isWaiting) {
        // Get the result
        bool granted = m_jniObject.callMethod<jboolean>("getLastPermissionResult", "()Z");

        if (env.checkAndClearExceptions()) {
            eWarning("SingBoxController::checkPermissionResult, Failed to get permission result");
        } else {
            eDebug("SingBoxController::checkPermissionResult, Permission result received: {}", granted);
            emit permissionResult(granted);

            if (!granted) {
                emit errorOccurred("Required permissions were not granted. Please enable Location and Notification permissions in Settings.");
            }
        }

        // Stop polling
        m_permissionCheckTimer->stop();
    }
}

bool SingBoxController::startVpn(const std::string& interfaceLocalIP, const std::string& peerPublicKey,
                                 const std::string& peerShortID, const std::string& peerPublicIP, const int peerPublicPort, const std::string& uuid)
{
    if (!m_initialized && !initialize()) {
        emit errorOccurred("SingBox not initialized");
        return false;
    }

    if (!hasVpnPermission()) {
        emit errorOccurred("VPN permission not granted. Please request permission first.");
        return false;
    }

    auto configJson = boost::json::parse(createConfig()).as_object();
    auto& inbound = configJson.at("inbounds").as_array()[0];
// #ifndef Q_OS_MACOS
//     inbound.at("interface_name") = config.interfaceName;
// #else
    if (inbound.as_object().contains("interface_name"))
        inbound.as_object().erase("interface_name");
// #endif
    inbound.at("inet4_address") = interfaceLocalIP + "/28"; // 30?

    auto& outbound = configJson.at("outbounds").as_array()[0];
    outbound.at("server") = peerPublicIP;
    outbound.at("server_port") = peerPublicPort;
    outbound.at("uuid") = uuid;

    outbound.at("tls").at("reality").at("public_key") = peerPublicKey;
    outbound.at("tls").at("reality").at("short_id") = peerShortID;

    auto configSerialized = boost::json::serialize(configJson);

    QJniEnvironment env;
    QJniObject jConfigJson = QJniObject::fromString(QString::fromStdString(configSerialized));

    bool result = m_jniObject.callMethod<jboolean>(
        "startVpn",
        "(Ljava/lang/String;)Z",
        jConfigJson.object<jstring>()
        );

    if (env.checkAndClearExceptions()) {
        emit errorOccurred("Failed to start VPN - JNI error");
        return false;
    }

    if (result) {
        emit vpnStatusChanged(true);
        eDebug("SingBoxController::startVpn, VPN started successfully");
    } else {
        emit errorOccurred("VPN failed to start - service returned false");
    }

    return result;
}

bool SingBoxController::stopVpn()
{
    if (!m_initialized) {
        return false;
    }

    QJniEnvironment env;

    bool result = m_jniObject.callMethod<jboolean>("stopVpn", "()Z");

    if (env.checkAndClearExceptions()) {
        eWarning("Failed to stop VPN");
        emit errorOccurred("Failed to stop VPN");
        return false;
    }

    if (result) {
        emit vpnStatusChanged(false);
        qDebug() << "SingBoxController::stopVpn, VPN stopped successfully";
    }

    return result;
}

bool SingBoxController::isVpnRunning()
{
    if (!m_initialized) {
        return false;
    }

    QJniEnvironment env;

    bool result = m_jniObject.callMethod<jboolean>("isVpnRunning", "()Z");

    if (env.checkAndClearExceptions()) {
        return false;
    }

    return result;
}

QString SingBoxController::getTrafficStats()
{
    if (!m_initialized) {
        return "{}";
    }

    QJniEnvironment env;

    QJniObject result = m_jniObject.callObjectMethod("getTrafficStats", "()Ljava/lang/String;");

    if (env.checkAndClearExceptions()) {
        return "{}";
    }

    QString stats = result.toString();
    if (!stats.isEmpty() && stats != "{}") {
        emit trafficUpdated(stats);
    }
    return stats;
}

void SingBoxController::cleanup()
{
    if (m_initialized && m_jniObject.isValid()) {
        stopVpn(); // Ensure VPN is stopped
        m_jniObject.callMethod<void>("cleanup", "()V");
        m_initialized = false;
        qDebug() << "SingBox JNI cleaned up";
    }
}

std::string_view SingBoxController::createConfig()
{
    static constinit std::string_view config = R"json(
{
  "log": {
    "disabled": true,
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "google",
        "address": "8.8.8.8",
        "detour": "proxy"
      },
      {
        "tag": "local",
        "address": "223.5.5.5",
        "detour": "direct"
      }
    ],
    "rules": [
      {
        "outbound": "any",
        "server": "local"
      }
    ],
    "strategy": "ipv4_only"
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "tun0",
      "inet4_address": "172.19.0.1/30",
      "mtu": 1500,
      "auto_route": true,
      "strict_route": true,
      "stack": "system",
      "sniff": true,
      "sniff_override_destination": false
    }
  ],
  "outbounds": [
    {
      "type": "vless",
      "tag": "proxy",
      "server": "37.187.180.212",
      "server_port": 443,
      "uuid": "161375e1-2156-4278-9a15-b1c3616bb788",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "google.com",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
        "reality": {
          "enabled": true,
          "public_key": "XNPtYcFzG3XcpNkVhB6FYZbd8Y97gj_RAxhVuzyuiA4",
          "short_id": "0a381e1fa219"
        }
      },
      "packet_encoding": "xudp"
    },
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    },
    {
      "type": "dns",
      "tag": "dns-out"
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "network": "udp",
        "port": 443,
        "outbound": "block"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      }
    ],
    "final": "proxy",
    "auto_detect_interface": true
  }
})json";

    return config;
}
