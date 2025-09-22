#include "statusbarhelper.h"

#ifdef Q_OS_ANDROID
    #include <QJniObject>
    #include <QJniEnvironment>

StatusBarHelper::StatusBarHelper() {
}

float StatusBarHelper::getStatusBarHeight() {
    QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative",
                                                             "activity",
                                                             "()Landroid/app/Activity;");
    QJniObject statusBarHelper("com/raccoonline/vpnapp/StatusBarHelper",
                               "(Landroid/app/Activity;)V",
                               activity.object<jobject>());
    return statusBarHelper.callMethod<jfloat>("getStatusBarHeight");
}

bool StatusBarHelper::hasNotch() {
    QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative",
                                                             "activity",
                                                             "()Landroid/app/Activity;");
    QJniObject displayHelper("com/raccoonline/vpnapp/StatusBarHelper",
                             "(Landroid/app/Activity;)V",
                             activity.object<jobject>());
    return displayHelper.callMethod<jboolean>("hasNotch");
}

QRectF StatusBarHelper::getNotchSize() {
    QRectF     notchSize;
    QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative",
                                                             "activity",
                                                             "()Landroid/app/Activity;");
    QJniObject displayHelper("com/raccoonline/vpnapp/StatusBarHelper",
                             "(Landroid/app/Activity;)V",
                             activity.object<jobject>());
    QJniObject sizeArray = displayHelper.callObjectMethod("getNotchSize", "()[F");
    if (sizeArray.isValid()) {
        jfloatArray     array = sizeArray.object<jfloatArray>();
        QJniEnvironment env;
        jfloat         *sizes = env->GetFloatArrayElements(array, nullptr);
        notchSize             = QRectF(sizes[0], sizes[1], sizes[2], sizes[3]);
        env->ReleaseFloatArrayElements(array, sizes, 0);
    }
    return notchSize;
}

float StatusBarHelper::getNavigationBarHeight() {
    QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative",
                                                             "activity",
                                                             "()Landroid/app/Activity;");
    QJniObject statusBarHelper("com/raccoonline/vpnapp/StatusBarHelper",
                               "(Landroid/app/Activity;)V",
                               activity.object<jobject>());
    return statusBarHelper.callMethod<jfloat>("getNavigationBarHeight");
}

bool StatusBarHelper::hasNavigationBar() {
    QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative",
                                                             "activity",
                                                             "()Landroid/app/Activity;");
    QJniObject statusBarHelper("com/raccoonline/vpnapp/StatusBarHelper",
                               "(Landroid/app/Activity;)V",
                               activity.object<jobject>());
    return statusBarHelper.callMethod<jboolean>("hasNavigationBar");
}

float StatusBarHelper::getNavigationBarHeightForOrientation() {
    QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative",
                                                             "activity",
                                                             "()Landroid/app/Activity;");
    QJniObject statusBarHelper("com/raccoonline/vpnapp/StatusBarHelper",
                               "(Landroid/app/Activity;)V",
                               activity.object<jobject>());
    return statusBarHelper.callMethod<jfloat>("getNavigationBarHeightForOrientation");
}

bool StatusBarHelper::isGestureNavigationEnabled() {
    QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative",
                                                             "activity",
                                                             "()Landroid/app/Activity;");
    QJniObject statusBarHelper("com/raccoonline/vpnapp/StatusBarHelper",
                               "(Landroid/app/Activity;)V",
                               activity.object<jobject>());
    return statusBarHelper.callMethod<jboolean>("isGestureNavigationEnabled");
}

QList<float> StatusBarHelper::getSystemWindowInsets() {
    QList<float> insets;
    QJniObject   activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative",
                                                             "activity",
                                                             "()Landroid/app/Activity;");
    QJniObject   statusBarHelper("com/raccoonline/vpnapp/StatusBarHelper",
                               "(Landroid/app/Activity;)V",
                               activity.object<jobject>());
    QJniObject   insetsArray = statusBarHelper.callObjectMethod("getSystemWindowInsets", "()[F");

    if (insetsArray.isValid()) {
        jfloatArray     array = insetsArray.object<jfloatArray>();
        QJniEnvironment env;
        jfloat         *values = env->GetFloatArrayElements(array, nullptr);

        // [left, top, right, bottom]
        for (int i = 0; i < 4; i++) {
            insets.append(values[i]);
        }

        env->ReleaseFloatArrayElements(array, values, 0);
    } else {
        // Fallback для старых версий
        insets.append(0.0f);                     // left
        insets.append(getStatusBarHeight());     // top
        insets.append(0.0f);                     // right
        insets.append(getNavigationBarHeight()); // bottom
    }

    return insets;
}

#else
StatusBarHelper::StatusBarHelper() {
}

float StatusBarHelper::getStatusBarHeight() {
    return 0.f;
}

bool StatusBarHelper::hasNotch() {
    return false;
}

QRectF StatusBarHelper::getNotchSize() {
    return QRectF();
}

float StatusBarHelper::getNavigationBarHeight() {
    return 0.f;
}

bool StatusBarHelper::hasNavigationBar() {
    return false;
}

float StatusBarHelper::getNavigationBarHeightForOrientation() {
    return 0.f;
}

bool StatusBarHelper::isGestureNavigationEnabled() {
    return false;
}

QList<float> StatusBarHelper::getSystemWindowInsets() {
    return QList<float> { 0.0f, 0.0f, 0.0f, 0.0f };
}
#endif
