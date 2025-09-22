#ifndef IMAGEPICKER_H
#define IMAGEPICKER_H

#include <QDateTime>
#include <QQuickItem>

class ImagePicker : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(QString imagePath READ imagePath WRITE setImagePath NOTIFY imagePathChanged)
    Q_PROPERTY(float imageScale READ imageScale WRITE setImageScale NOTIFY imageScaleChanged)
    Q_PROPERTY(float imageQuality READ imageQuality WRITE setImageQuality NOTIFY imageQualityChanged)
    Q_PROPERTY(bool saveImageToCameraRoll READ saveImageToCameraRoll WRITE setSaveImageToCameraRoll NOTIFY
                   saveImageToCameraRollChanged)
    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)

public:
#ifdef Q_OS_IOS
    explicit ImagePicker(QQuickItem *parent = 0);
    Q_INVOKABLE void openPicker();
    Q_INVOKABLE void openCamera();
    Q_INVOKABLE void openFiles();
#else
    explicit ImagePicker(QQuickItem *parent = 0)
        : QQuickItem(parent) {
    }
    Q_INVOKABLE void openPicker() {
    }
    Q_INVOKABLE void openCamera() {
    }
    Q_INVOKABLE void openFiles() {
    }
#endif

    QString imagePath() const {
        return m_imagePath;
    }

    float imageScale() const {
        return m_imageScale;
    }

    float imageQuality() const {
        return m_imageQuality;
    }

    bool saveImageToCameraRoll() const {
        return m_saveImageToCameraRoll;
    }

signals:
    void imagePathChanged(QString imagePath);
    void imageScaleChanged(float arg);
    void imageQualityChanged(float arg);
    void saveImageToCameraRollChanged(bool arg);
    void file(QString f);

    void pathChanged();

public slots:

    void setImagePath(QString arg) {
        if (m_imagePath != arg) {
            m_imagePath = arg;
            emit imagePathChanged(arg);
        }
    }

    void setImageScale(float arg) {
        if (m_imageScale != arg) {
            m_imageScale = arg;
            emit imageScaleChanged(arg);
        }
    }

    void setImageQuality(float arg) {
        if (m_imageQuality != arg) {
            m_imageQuality = arg;
            emit imageQualityChanged(arg);
        }
    }

    void setSaveImageToCameraRoll(bool arg) {
        if (m_saveImageToCameraRoll != arg) {
            m_saveImageToCameraRoll = arg;
            emit saveImageToCameraRollChanged(arg);
        }
    }

    QString path() const {
        return m_path;
    }

    void setPath(const QString &newPath) {
        if (m_path == newPath)
            return;
        m_path = newPath;
        emit pathChanged();
    }

private:
    void   *m_delegate;
    QString m_imagePath;
    float   m_imageScale;
    float   m_imageQuality;
    bool    m_saveImageToCameraRoll;
    QString m_path;
};

#endif // IMAGEPICKER_H
