#include "androidutils.h"

#include "utils/exc_utils.h"

#include <QCoreApplication>

#ifdef Q_OS_ANDROID
    #include <QJniObject>
    #include <QJniEnvironment>
    #include <QGuiApplication>
    #include <QScreen>
    #include <QtCore/private/qandroidextras_p.h>
    #include <QStandardPaths>
    #include <QDir>
#endif

AndroidUtils::AndroidUtils(QObject *parent)
    : QObject(parent) {
}

// Shares a file using the Android system share intent
void AndroidUtils::shareFile(const QString &filePath) {
#ifdef Q_OS_ANDROID
    QJniObject context = QNativeInterface::QAndroidApplication::context();

    QJniObject jFilePath = QJniObject::fromString(filePath);

    QJniObject::callStaticMethod<void>("com/raccoonline/vpnapp/AndroidUtils",
                                       "shareFile",
                                       "(Landroid/content/Context;Ljava/lang/String;)V",
                                       context.object(),
                                       jFilePath.object<jstring>());
#endif
}

// Detects if the current device is a tablet based on screen configuration
bool AndroidUtils::isTablet() {
#ifdef Q_OS_ANDROID
    static bool done = false;
    static bool res  = false;

    if (done) {
        return res;
    }

    QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative",
                                                             "activity",
                                                             "()Landroid/app/Activity;");

    if (!activity.isValid())
        return false;

    QJniObject resources = activity.callObjectMethod("getResources", "()Landroid/content/res/Resources;");

    if (!resources.isValid())
        return false;

    QJniObject configuration =
        resources.callObjectMethod("getConfiguration", "()Landroid/content/res/Configuration;");

    if (!configuration.isValid())
        return false;

    jint screenLayout = configuration.getField<jint>("screenLayout");

    jint screenLayoutSizeMask  = 0x0f;
    jint screenLayoutSizeLarge = 0x03;

    res  = ((screenLayout & screenLayoutSizeMask) >= screenLayoutSizeLarge);
    done = true;
    return res;
#else
    return false;
#endif
}

// Sets screen orientation based on device type (portrait for phones, unspecified for tablets)
void AndroidUtils::setOrientationBasedOnDeviceType() {
#ifdef Q_OS_ANDROID
    QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative",
                                                             "activity",
                                                             "()Landroid/app/Activity;");

    if (!activity.isValid())
        return;

    const int SCREEN_ORIENTATION_PORTRAIT    = 1;
    const int SCREEN_ORIENTATION_UNSPECIFIED = -1;

    if (isTablet()) {
        activity.callMethod<void>("setRequestedOrientation", "(I)V", SCREEN_ORIENTATION_UNSPECIFIED);
    } else {
        activity.callMethod<void>("setRequestedOrientation", "(I)V", SCREEN_ORIENTATION_PORTRAIT);
    }
#endif
}

// Controls the wake lock to prevent device from sleeping
void AndroidUtils::setWakeLock(bool active) {
#ifdef Q_OS_ANDROID
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid()) {
        eInfo("AndroidUtils::setWakeLock() - Failed to get Android application context");
        return;
    }

    // Call Java method to manage WakeLock
    QJniObject::callStaticMethod<void>("com/raccoonline/vpnapp/AndroidUtils",
                                       "setWakeLock",
                                       "(Landroid/content/Context;Z)V",
                                       context.object(),
                                       active);

    eInfo("{}",
          QString("AndroidUtils::setWakeLock(%1) - Call completed successfully").arg(active ? "true" : "false"));
#endif
}

// Requests exemption from battery optimization for the app
bool AndroidUtils::requestBatteryOptimizationExemption() {
#ifdef Q_OS_ANDROID
    QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative",
                                                             "activity",
                                                             "()Landroid/app/Activity;");
    if (!activity.isValid()) {
        eInfo("{}", "AndroidUtils::requestBatteryOptimizationExemption() - Failed to get Android activity");
        return false;
    }

    jboolean result = QJniObject::callStaticMethod<jboolean>("com/raccoonline/vpnapp/AndroidUtils",
                                                             "requestBatteryOptimizationExemption",
                                                             "(Landroid/app/Activity;)Z",
                                                             activity.object());

    eInfo("{}",
          QString("AndroidUtils::requestBatteryOptimizationExemption() - Result: %1")
              .arg(result ? "success" : "failure"));

    return result;
#else
    return false;
#endif
}

// Checks if the app is exempted from battery optimization
bool AndroidUtils::isBatteryOptimizationExempted() {
#ifdef Q_OS_ANDROID
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid()) {
        eInfo("AndroidUtils::isBatteryOptimizationExempted() - Failed to get Android application context");
        return false;
    }

    jboolean result = QJniObject::callStaticMethod<jboolean>("com/raccoonline/vpnapp/AndroidUtils",
                                                             "isBatteryOptimizationExempted",
                                                             "(Landroid/content/Context;)Z",
                                                             context.object());

    return result;
#else
    return false;
#endif
}

// Registers a network callback to monitor network changes
void AndroidUtils::registerNetworkCallback() {
#ifdef Q_OS_ANDROID
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid()) {
        eInfo("AndroidUtils::registerNetworkCallback() - Failed to get Android application context");
        return;
    }

    QJniObject::callStaticMethod<void>("com/raccoonline/vpnapp/AndroidUtils",
                                       "registerNetworkCallback",
                                       "(Landroid/content/Context;)V",
                                       context.object());

    eInfo("AndroidUtils::registerNetworkCallback() - Network callback registered");
#endif
}

// Unregisters the network callback
void AndroidUtils::unregisterNetworkCallback() {
#ifdef Q_OS_ANDROID
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid()) {
        eInfo("AndroidUtils::unregisterNetworkCallback() - Failed to get Android application context");
        return;
    }

    QJniObject::callStaticMethod<void>("com/raccoonline/vpnapp/AndroidUtils",
                                       "unregisterNetworkCallback",
                                       "(Landroid/content/Context;)V",
                                       context.object());

    eInfo("AndroidUtils::unregisterNetworkCallback() - Network callback unregistered");
#endif
}

// Enables WebSocket keep-alive functionality
void AndroidUtils::enableWebSocketKeepAlive() {
#ifdef Q_OS_ANDROID
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid()) {
        eInfo("AndroidUtils::enableWebSocketKeepAlive() - Failed to get Android application context");
        return;
    }

    QJniObject::callStaticMethod<void>("com/raccoonline/vpnapp/AndroidUtils",
                                       "enableWebSocketKeepAlive",
                                       "(Landroid/content/Context;)V",
                                       context.object());

    eInfo("AndroidUtils::enableWebSocketKeepAlive() - WebSocket connection support activated");
#endif
}

// Starts the VPN service with the provided configuration parameters
void AndroidUtils::startVpnService(const QString &privateKey,
                                   const QString &ip,
                                   const QString &endpoint,
                                   const QString &publicKey,
                                   const QString &allowedIps) {
#ifdef Q_OS_ANDROID
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid()) {
        eInfo("AndroidUtils::startVpnService() - Failed to get Android application context");
        return;
    }

    QJniObject jPrivateKey = QJniObject::fromString(privateKey);
    QJniObject jIp         = QJniObject::fromString(ip);
    QJniObject jEndpoint   = QJniObject::fromString(endpoint);
    QJniObject jPublicKey  = QJniObject::fromString(publicKey);
    QJniObject jAllowedIps = QJniObject::fromString(allowedIps);

    QJniObject::callStaticMethod<void>("com/raccoonline/vpnapp/VpnForegroundService",
                                       "startVpnService",
                                       "(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;Ljava/lang/"
                                       "String;Ljava/lang/String;Ljava/lang/String;)V",
                                       context.object(),
                                       jPrivateKey.object<jstring>(),
                                       jIp.object<jstring>(),
                                       jEndpoint.object<jstring>(),
                                       jPublicKey.object<jstring>(),
                                       jAllowedIps.object<jstring>());

    eInfo("AndroidUtils::startVpnService() - VPN service start request sent");
#endif
}

// Stops the VPN service
void AndroidUtils::stopVpnService() {
#ifdef Q_OS_ANDROID
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid()) {
        eInfo("AndroidUtils::stopVpnService() - Failed to get Android application context");
        return;
    }

    QJniObject::callStaticMethod<void>("com/raccoonline/vpnapp/VpnForegroundService",
                                       "stopVpnService",
                                       "(Landroid/content/Context;)V",
                                       context.object());

    eInfo("AndroidUtils::stopVpnService() - VPN service stop request sent");
#endif
}

// Initializes Android utilities
void AndroidUtils::initialize() {
#ifdef Q_OS_ANDROID
    eInfo("AndroidUtils::initialize() - Initializing Android utilities");

    // Request battery optimization exemption
    requestBatteryOptimizationExemption();

    // Register network callback
    registerNetworkCallback();

    // Set wake lock
    setWakeLock(true);
    setupStatusBar();

    eInfo("AndroidUtils::initialize() - Initialization complete");
#endif
}

// Cleans up resources used by Android utilities
void AndroidUtils::cleanup() {
#ifdef Q_OS_ANDROID
    eInfo("AndroidUtils::cleanup() - Cleaning up Android utility resources");

    // Release wake lock
    setWakeLock(false);

    // Unregister network callback
    unregisterNetworkCallback();

    eInfo("AndroidUtils::cleanup() - Cleanup complete");
#endif
}

// Sets up the status bar
void AndroidUtils::setupStatusBar() {
#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();

    if (activity.isValid()) {
        QJniObject::callStaticMethod<void>("com/raccoonline/vpnapp/AndroidUtils",
                                           "setupStatusBar",
                                           "(Landroid/app/Activity;)V",
                                           activity.object());
    }
#endif
}

// Gets the height of the status bar in pixels
int AndroidUtils::getStatusBarHeight() {
#ifdef Q_OS_ANDROID

    QJniObject activity = QNativeInterface::QAndroidApplication::context();

    if (activity.isValid()) {
        return QJniObject::callStaticMethod<jint>("com/raccoonline/vpnapp/AndroidUtils",
                                                  "getStatusBarHeight",
                                                  "(Landroid/app/Activity;)I",
                                                  activity.object());
    }

#endif
    return 0; // Return 0 if failed to get activity
}

bool AndroidUtils::installApk(const QString &filePath) {
#ifdef Q_OS_ANDROID
    QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative",
                                                             "activity",
                                                             "()Landroid/app/Activity;");

    if (!activity.isValid()) {
        qWarning() << "[AndroidUtils] Cannot get Android activity";
        return false;
    }

    QJniObject::callStaticMethod<void>("com/raccoonline/vpnapp/UpdaterHelper",
                                       "setContext",
                                       "(Landroid/content/Context;)V",
                                       activity.object());

    QJniObject::callStaticMethod<void>("com/raccoonline/vpnapp/UpdaterHelper",
                                       "installApk",
                                       "(Ljava/lang/String;)V",
                                       QJniObject::fromString(filePath).object());

    return true;
#endif
    return false;
}
