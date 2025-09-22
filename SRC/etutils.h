#ifndef ETUTILS_H
#define ETUTILS_H

#include <QGuiApplication>
#include <QClipboard>
#include <QDir>
#include <QJSValue>
#include <QProcess>

#include "utils/exc_utils.h"

#include "SRC/profile.h"
#include "SRC/MacOs/MacosUtils.h"

#ifdef Q_OS_ANDROID
    #include <QJniObject>
#endif

class ExtraChainNode;

class EtUtils : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isRelease READ isRelease WRITE setIsRelease NOTIFY isReleaseChanged)

public:
    EtUtils(ExtraChainNode* node, QObject* parent = nullptr);

    // data readFile(file)
    // writeFile(file, data)
    Q_INVOKABLE QString calcHash(const QString& value);
    Q_INVOKABLE bool    fileExists(const QString& filePath);
    Q_INVOKABLE bool    dirExists(const QString& dirPath);
    Q_INVOKABLE bool    dirRemove(const QString& dirPath);
    Q_INVOKABLE bool    isImage(const QString& filePath);
    Q_INVOKABLE bool    fileRemove(const QString& filePath);
    Q_INVOKABLE bool    testFile(const QString& filePath);
    Q_INVOKABLE bool    vibrate(int milliseconds = 400);
    Q_INVOKABLE void    wipe();
    Q_INVOKABLE QString toFilePath(const QString& path);
    Q_INVOKABLE QSize   imageSize(const QString& path);
    Q_INVOKABLE QString serverIp();
    Q_INVOKABLE bool    setServerIp(const QString& serverIp);
    Q_INVOKABLE Network::Protocol networkProtocol();
    Q_INVOKABLE bool              setNetworkProtocol(Network::Protocol networkProtocol);
    Q_INVOKABLE bool              serverAllowLocal();
    Q_INVOKABLE bool              setAllowLocal(bool allowLocalServer);
    Q_INVOKABLE void              copyDir(const QString& src, const QString& dst);
    Q_INVOKABLE bool              copyFile(const QString& src, const QString& dst);
    Q_INVOKABLE uint              filesCountInDir(const QString& path);
    Q_INVOKABLE Profile           makeProfile();
    Q_INVOKABLE int               privateProfileExist();
    Q_INVOKABLE QString           country(int id);
    Q_INVOKABLE QVariantList      findCountries(QString country);
    Q_INVOKABLE void              copyToClipboard(const QString& str);
    Q_INVOKABLE void              makePath(const QString& str);
    Q_INVOKABLE QString           parentFolder();
    Q_INVOKABLE QString           fileName(const QString& url);
    Q_INVOKABLE QString           findLocalIp();
    Q_INVOKABLE int               androidSdk();

    static QByteArray        serialize(QList<QByteArray> list);
    static QString           serializeStr(QStringList list);
    static QList<QByteArray> deserialize(const QString& serialized);
    static QStringList       deserializeStr(const QString& serialized);
    bool                     isRelease() const;
    Q_INVOKABLE QString      clipboardText();
    Q_INVOKABLE QString      getPureHtml(QString newText);
    Q_INVOKABLE QVariantList fieldNames(const QString& field);

    Q_INVOKABLE int          freeMemory();
    Q_INVOKABLE bool         isSqlite(QString filePath);
    Q_INVOKABLE bool         isGif(QString fileUrl);
    Q_INVOKABLE QString      fileType(const QString& fileName);
    Q_INVOKABLE int          tableCount(QString dbPath, QString table);
    Q_INVOKABLE QVariantList tableNames(QString dbPath);
    Q_INVOKABLE QVariantList tableData(QString dbPath, QString table);
    Q_INVOKABLE void         openFolder(QString folder, QString program);
    Q_INVOKABLE QString      randomId(int n);
    Q_INVOKABLE void         lookupHost(const QString& hostName, QJSValue callback);
    Q_INVOKABLE bool         isValidIp(const QString& ip);

    static QImage  blur(const QImage& image, int radius = 100);
    static QString defaultServerIp();
    static QString formatterNumber(const BigNumberFloat number);
public slots:
    void setIsRelease(bool isRelease);

signals:
    void isReleaseChanged(bool isRelease);

private:
#ifdef Q_OS_ANDROID
    QJniObject vibratorService;
#endif
#ifdef Q_OS_IOS
    ApplePlatformUtils* iosUtils;
#endif
    bool        m_isRelease = false;
    QClipboard* clipboard   = qApp->clipboard();

    ExtraChainNode* node;
};

#ifndef Q_OS_IOS
class ImagePicker : public QObject {
    Q_OBJECT
public:
    ImagePicker(QObject* parent = nullptr)
        : QObject(parent) {};

signals:
    void file(const QString& f);
    void imagePathChanged(const QString&);
};
#endif

#endif // ETUTILS_H
