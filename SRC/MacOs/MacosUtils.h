#ifndef MACOS_UTILS_H
#define MACOS_UTILS_H

#include <QObject>
#include <QString>

class ApplePlatformUtils : public QObject {
    Q_OBJECT
public:
    explicit ApplePlatformUtils(QObject *parent = nullptr);
    void clipboard(const QString &text);

    static void init_sparkle();
#ifdef Q_OS_IOS
    void triggerFaceID();
    bool isFaceIDAvailable();
    void vibrate();
#endif
signals:
    void resultFaceId(bool result);

private:
#ifdef Q_OS_IOS
    void authenticateWithFaceID(std::function<void(bool, const char *)> callback);
    void requestPasscodeFallback(std::function<void(bool, const char *)> callback);
#endif
};

#endif // MACOS_UTILS_H
