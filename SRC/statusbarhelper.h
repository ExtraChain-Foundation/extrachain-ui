#ifndef STATUSBARHELPER_H
#define STATUSBARHELPER_H

#include <QCoreApplication>
#include <QRectF>
#include <QList>

class StatusBarHelper : public QObject {
    Q_OBJECT

public:
    StatusBarHelper();

    Q_INVOKABLE float  getStatusBarHeight();
    Q_INVOKABLE bool   hasNotch();
    Q_INVOKABLE QRectF getNotchSize();

    Q_INVOKABLE float getNavigationBarHeight();
    Q_INVOKABLE bool  hasNavigationBar();
    Q_INVOKABLE float getNavigationBarHeightForOrientation();
    Q_INVOKABLE bool  isGestureNavigationEnabled();
    Q_INVOKABLE QList<float> getSystemWindowInsets();
};

#endif // STATUSBARHELPER_H
