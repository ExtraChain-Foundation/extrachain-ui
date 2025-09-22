#include "SRC/etutils.h"

#include <QCryptographicHash>
#include <QElapsedTimer>
#include <QFileInfoList>
#include <QHostInfo>
#include <QImageReader>
#include <QUrl>

#include "managers/extrachain_node.h"
#include "managers/account_controller.h"
#include "network/network_manager.h"
#include "utils/bignumber.h"

#ifdef Q_OS_IOS
    #include <AudioToolbox/AudioToolbox.h>
#endif

EtUtils::EtUtils(ExtraChainNode *node, QObject *parent)
    : QObject(parent) {
    this->node = node;

#ifdef Q_OS_ANDROID
    QJniObject vibroString = QJniObject::fromString("vibrator");
    QJniObject activity    = QNativeInterface::QAndroidApplication::context();
    QJniObject appctx      = activity.callObjectMethod("getApplicationContext", "()Landroid/content/Context;");
    vibratorService        = appctx.callObjectMethod("getSystemService",
                                              "(Ljava/lang/String;)Ljava/lang/Object;",
                                              vibroString.object<jstring>());
#endif

#ifdef Q_OS_IOS
    iosUtils = new ApplePlatformUtils(this);
#endif

#ifdef QT_DEBUG
    setIsRelease(false);
#else
    setIsRelease(true);
#endif
}

QString EtUtils::calcHash(const QString &value) {
    return QString::fromStdString(Utils::calculate_hash(value.toStdString()));
}

bool EtUtils::fileExists(const QString &filePath) {
    return QFile::exists(QUrl(filePath).toLocalFile());
}

bool EtUtils::dirExists(const QString &dirPath) {
    return QDir(QUrl(dirPath).toLocalFile()).exists();
}

bool EtUtils::dirRemove(const QString &dirPath) {
    return QDir(QUrl(dirPath).toLocalFile()).removeRecursively();
}

bool EtUtils::isImage(const QString &filePath) {
    QImageReader image(QUrl(filePath).toLocalFile());
    return image.canRead();
}

bool EtUtils::fileRemove(const QString &filePath) {
    return QFile::remove(QUrl(filePath).toLocalFile());
}

bool EtUtils::testFile(const QString &filePath) {
    QFile file(QUrl(filePath).toLocalFile());
    eLog("{}", file.open(QFile::ReadOnly));
    eLog("{}", file.readAll());
    return true;
}

bool EtUtils::vibrate(int milliseconds) {
#if defined(Q_OS_ANDROID)
    if (vibratorService.isValid()) {
        jlong    ms       = milliseconds;
        jboolean hasVibro = vibratorService.callMethod<jboolean>("hasVibrator", "()Z");
        vibratorService.callMethod<void>("vibrate", "(J)V", ms);
        return hasVibro;
    } else {
        eLog("[Android] No vibrator service available");
    }
#elif defined(Q_OS_IOS)
    iosUtils->vibrate();
#else
    Q_UNUSED(milliseconds)
#endif
    return false;
}

void EtUtils::wipe() {
    // Utils::wipeDataFiles();
}

QString EtUtils::toFilePath(const QString &path) // from absolute path to file:///
{
    return QUrl::fromLocalFile(path).toString();
}

QSize EtUtils::imageSize(const QString &path) {
    QImageReader image(QUrl(path).toLocalFile());
    return image.size();
}

QString EtUtils::serverIp() {
    return QString::fromStdString(node->network()->first_node());
}

bool EtUtils::setServerIp(const QString &serverIp) {
    eLog("[UI] Set server IP to {}", serverIp);
    return node->network()->save_first_node(serverIp.toStdString());
}

Network::Protocol EtUtils::networkProtocol() {
    return Network::Protocol::WebSocket;
}

bool EtUtils::setNetworkProtocol(Network::Protocol networkProtocol) {
    return false;
}

bool EtUtils::serverAllowLocal() {
    return true;
}

bool EtUtils::setAllowLocal(bool allowLocalServer) {
    return false;
}

QByteArray EtUtils::serialize(QList<QByteArray> list) {
    for (auto &&value : list) {
        if (value.indexOf("'") != -1)
            value.replace("'", "\\'");
    }

    QByteArray serialized = "'" + list.join("','") + "'";
    return serialized;
}

QString EtUtils::serializeStr(QStringList list) {
    for (auto &&value : list) {
        if (value.indexOf("'") != -1)
            value.replace("'", "\\'");
    }

    QString serialized = "'" + list.join("','") + "'";
    return serialized;
}

QList<QByteArray> EtUtils::deserialize(const QString &serialized) {
    QStringList       deserializedStr = serialized.mid(1, serialized.length() - 2).split("','");
    QList<QByteArray> deserialized;

    for (auto &&value : deserializedStr) {
        if (value.indexOf("'") != -1)
            value.replace("\\'", "'");
        deserialized << value.toUtf8();
    }

    return deserialized;
}

QStringList EtUtils::deserializeStr(const QString &serialized) {
    QStringList deserialized = serialized.mid(1, serialized.length() - 2).split("','");

    for (auto &&value : deserialized) {
        if (value.indexOf("'") != -1)
            value.replace("'", "\\'");
    }

    return deserialized;
}

bool EtUtils::isRelease() const {
    return m_isRelease;
}

QString EtUtils::clipboardText() {
    QString text = clipboard->text();
    text.replace("￼", "");
    text.replace("<", "&lt;");
    text.replace(">", "&gt;");
    return text;
}

QString EtUtils::getPureHtml(QString newText) {
    int toDel = newText.indexOf("<p");
    newText   = newText.remove(0, toDel);
    toDel     = newText.indexOf(">") + 1;
    newText   = newText.remove(0, toDel);
    int end   = QString("</p></body></html>").length();
    // if (newText.right(end) == "</p></body></html>")
    newText.chop(end);
    newText.replace("<!--StartFragment-->", "");
    newText.replace("<!--EndFragment-->", "");
    if (newText == "<br />")
        newText = "";
    return newText;
}

QVariantList EtUtils::fieldNames(const QString &field) {
    const QMap<int, QString> *original;

    if (field == "unit")
        original = &Profile::unitMap;
    else if (field == "category")
        original = &Profile::categoryMap;
    else if (field == "body")
        original = &Profile::bodyMap;
    else if (field == "hair")
        original = &Profile::hairMap;
    else if (field == "hairLength")
        original = &Profile::hairLengthMap;
    else if (field == "eye")
        original = &Profile::eyeMap;
    else if (field == "ethnicity")
        original = &Profile::ethnicityMap;
    else if (field == "style")
        original = &Profile::styleMap;
    else if (field == "sports")
        original = &Profile::sportsMap;
    else if (field == "skin")
        original = &Profile::skinMap;
    else if (field == "direction")
        original = &Profile::directionMap;
    else if (field == "workStyle")
        original = &Profile::workStyleMap;
    else if (field == "fashion")
        original = &Profile::fashionMap;
    else if (field == "scope")
        original = &Profile::scopeMap;
    else
        return QVariantList();

    QVariantList list;

    for (const auto &el : original->keys()) {
        QVariantMap map = { { "index", el }, { "name", original->value(el) } };
        list << map;
    }

    return list;
}

void EtUtils::setIsRelease(bool isRelease) {
    if (m_isRelease == isRelease)
        return;

    m_isRelease = isRelease;
    emit isReleaseChanged(m_isRelease);
}

void EtUtils::copyDir(const QString &src, const QString &dst) {
    const QDir dir(src);

    if (!dir.exists() || !QDir().mkpath(dst)) {
        if (!QDir(dst).exists())
            return;
    }

    for (QString &d : dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
        copyDir(src + QDir::separator() + d, dst + QDir::separator() + d);

    for (QString &f : dir.entryList(QDir::Files)) {
        const QString   oneFileName = src + QDir::separator() + f;
        const QString   twoFileName = dst + QDir::separator() + f;
        const QFileInfo oneFile(oneFileName);
        const QFileInfo twoFile(twoFileName);

        if (twoFile.exists() && oneFile.size() == twoFile.size())
            continue;
        else
            QFile::remove(twoFileName);

        QFile::copy(oneFileName, twoFileName);
    }
}

bool EtUtils::copyFile(const QString &src, const QString &dst) {
    return QFile::copy(QUrl(src).toLocalFile(), QUrl(dst).toLocalFile());
}

uint EtUtils::filesCountInDir(const QString &path) {
    QDir dir(path);
    dir.setFilter(QDir::AllEntries | QDir::NoDotAndDotDot);
    return dir.count();
}

Profile EtUtils::makeProfile() {
    return Profile();
}

int EtUtils::privateProfileExist() {
    return AccountController::profilesList().size() != 0;
}

QString EtUtils::country(int id) {
    if (id == QLocale::UnitedStates)
        return "USA";

    QString country = QLocale::countryToString(QLocale::Country(id));

    static const QList<int> andish { QLocale::AntiguaAndBarbuda,
                                     QLocale::BosniaAndHerzegowina,
                                     QLocale::CeutaAndMelilla,
                                     QLocale::HeardAndMcDonaldIslands,
                                     QLocale::SaintKittsAndNevis,
                                     QLocale::SaintPierreAndMiquelon,
                                     QLocale::SaintVincentAndTheGrenadines,
                                     QLocale::SaoTomeAndPrincipe,
                                     QLocale::SouthGeorgiaAndTheSouthSandwichIslands,
                                     QLocale::SvalbardAndJanMayenIslands,
                                     QLocale::TrinidadAndTobago,
                                     QLocale::TurksAndCaicosIslands,
                                     QLocale::WallisAndFutunaIslands };

    if (andish.contains(id))
        country.replace("And", "&");

    return country;
}

QVariantList EtUtils::findCountries(QString find) {
    static const QList<int> ignored { QLocale::World,
                                      QLocale::Europe,
                                      QLocale::EuropeanUnion,
                                      QLocale::LatinAmerica,
                                      QLocale::BritishIndianOceanTerritory,
                                      QLocale::FrenchGuiana,
                                      QLocale::OutlyingOceania,
                                      QLocale::PalestinianTerritories,
                                      QLocale::WesternSahara };

    find = find.toLower();
    QVariantList list;

    for (int i = 1; i < QLocale::LastCountry; i++) {
        if (ignored.contains(i))
            continue;

        const QString country = this->country(i).toLower();
        if (country.contains(find) || (find.contains("and") && country.contains(find.replace("and", "&"))))
            list << i;
    }

    return list;
}

void EtUtils::copyToClipboard(const QString &str) {
    clipboard->setText(str, QClipboard::Clipboard);

    if (clipboard->supportsSelection()) {
        clipboard->setText(str, QClipboard::Selection);
    }
}

void EtUtils::makePath(const QString &str) {
    QDir().mkpath(str);
}

QString EtUtils::parentFolder() {
    static QString dirPath;
    if (dirPath.isEmpty()) {
        QDir dir(QDir::currentPath());
        dir.cdUp();
        dirPath = QString::fromStdWString(Utils::filePrefix) + dir.absolutePath();
    }

    return dirPath;
}

QString EtUtils::fileName(const QString &url) {
    return QFileInfo(QUrl(url).toLocalFile()).fileName();
}

QString EtUtils::findLocalIp() {
    static QString ip = Utils::findLocalIp().ip().toString();
    if (ip == "0.0.0.0")
        ip = "127.0.0.1";
    return ip;
}

int EtUtils::androidSdk() {
#ifdef Q_OS_ANDROID
    return QNativeInterface::QAndroidApplication::sdkVersion();
#endif
    return -1;
}

int EtUtils::freeMemory() {
    // qint64 total = Utils::checkMemoryTotal() / 1024 / 1024;
    int free = Utils::diskFreeMemory() / 1024 / 1024;
    // int available = total - free;
    return free;
}

bool EtUtils::isSqlite(QString filePath) {
    QFile file(filePath);
    if (!file.open(QFile::ReadOnly))
        return false;

    QByteArray read = file.read(13);

    return read == "SQLite format";
}

bool EtUtils::isGif(QString fileUrl) {
    if (fileUrl.indexOf(".gif", Qt::CaseInsensitive) != -1)
        return true;

    QString filePath = QUrl(fileUrl).toLocalFile();
    QFile   file(filePath);
    if (!file.open(QFile::ReadOnly))
        return false;

    QByteArray read = file.read(3);

    return read == "GIF";
}

QString EtUtils::fileType(const QString &fileName) {
    QString filePath = QUrl(fileName).toLocalFile();
    return Utils::fileMimeSuffix(filePath);
}

int EtUtils::tableCount(QString dbPath, QString table) {
    if (dbPath.isEmpty() || !QFile::exists(dbPath))
        return -1;
    DbConnector db(dbPath.toStdString());
    db.open();
    return db.count(table.toStdString());
}

QVariantList EtUtils::tableNames(QString dbPath) {
    if (dbPath.isEmpty() || !QFile::exists(dbPath))
        return {};
    DbConnector db(dbPath.toStdString());
    db.open();
    auto tables = db.table_names();

    QVariantList list;
    for (const std::string &table : tables) {
        list << QString::fromStdString(table);
    }

    return list;
}

QVariantList EtUtils::tableData(QString dbPath, QString table) {
    if (dbPath.isEmpty() || table.isEmpty() || !QFile::exists(dbPath))
        return {};
    DbConnector db(dbPath.toStdString());
    db.open();
    auto        columnsRes = db.select("PRAGMA table_info(" + table.toStdString() + ");");
    QStringList columns    = { "rowid" };
    for (auto row : columnsRes)
        columns << row["name"].c_str();

    auto data = db.select("SELECT ROWID, * FROM " + table.toStdString());
    db.close();

    QVariantList all;

    if (data.empty())
        return {};

    QVariantMap mapRow;
    int         j = 1;
    for (const QString &column : std::as_const(columns)) {
        mapRow[(j > 9 ? "cc" : "c") + QString::number(j)] = column;
        j++;
    }
    for (; j != 15; j++)
        mapRow[(j > 9 ? "cc" : "c") + QString::number(j)] = "";
    all << mapRow;

    for (DbRow row : data) {
        int i = 1;

        QVariantMap mapRow;
        for (const QString &column : std::as_const(columns)) {
            mapRow[(i > 9 ? "cc" : "c") + QString::number(i)] = row[column.toStdString()].c_str();
            i++;
        }
        for (; i != 15; i++)
            mapRow[(i > 9 ? "cc" : "c") + QString::number(i)] = "";

        all << mapRow;
    }

    return all;
}

void EtUtils::openFolder(QString folder, QString program) {
#ifndef Q_OS_IOS
    if (!program.isEmpty()) {
        QProcess::startDetached(program, { QDir::currentPath() });
        return;
    }

    #if defined(Q_OS_LINUX)
    QProcess::startDetached("xdg-open", { folder });
    #elif defined(Q_OS_WIN)
    QProcess::startDetached("explorer.exe", { folder.replace("/", "\\") });
    #elif defined(Q_OS_MACOS)
    QProcess::startDetached("open", { folder });
    #else
    eLog("openFolder not implemented for this platform");
    #endif
#endif
}

QString EtUtils::randomId(int n) {
    return Utils::generate_random_hex(n).c_str();
}

void EtUtils::lookupHost(const QString &hostName, QJSValue callback) {
    QJSValue *cb = new QJSValue(callback);
    QHostInfo::lookupHost(hostName, [cb](const QHostInfo &host) {
        if (host.error() != QHostInfo::NoError) {
            cb->call({ host.errorString() });
        }

        const auto addresses = host.addresses();
        for (const QHostAddress &address : addresses) {
            cb->call({ address.toString() });
        }

        delete cb;
    });
}

bool EtUtils::isValidIp(const QString &ip) {
    return Utils::isValidIp(ip);
}

QImage EtUtils::blur(const QImage &image, int radius) {
    int            alphas[] = { 14, 10, 8, 6, 5, 5, 4, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2 };
    auto           alpha    = (radius < 1) ? 16 : (radius > 17) ? 1 : alphas[radius - 1];
    auto           rect     = image.rect();
    auto           blurred  = image.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    auto           rTop = rect.top(), rBottom = rect.bottom(), rLeft = rect.left(), rRight = rect.right();
    auto           perLine = blurred.bytesPerLine();
    int            rgba[4];
    unsigned char *pntr;
    auto           i1 = 0, i2 = 3;

    for (int col = rLeft; col <= rRight; col++) {
        pntr = blurred.scanLine(rTop) + col * 4;
        for (int i = i1; i <= i2; i++)
            rgba[i] = pntr[i] << 4;

        pntr += perLine;
        for (int j = rTop; j < rBottom; j++, pntr += perLine)
            for (int i = i1; i <= i2; i++)
                pntr[i] = (rgba[i] += ((pntr[i] << 4) - rgba[i]) * alpha / 16) >> 4;
    }

    for (int row = rTop; row <= rBottom; row++) {
        pntr = blurred.scanLine(row) + rLeft * 4;
        for (int i = i1; i <= i2; i++)
            rgba[i] = pntr[i] << 4;

        pntr += 4;
        for (int j = rLeft; j < rRight; j++, pntr += 4)
            for (int i = i1; i <= i2; i++)
                pntr[i] = (rgba[i] += ((pntr[i] << 4) - rgba[i]) * alpha / 16) >> 4;
    }

    for (int col = rLeft; col <= rRight; col++) {
        pntr = blurred.scanLine(rBottom) + col * 4;
        for (int i = i1; i <= i2; i++)
            rgba[i] = pntr[i] << 4;

        pntr -= perLine;
        for (int j = rTop; j < rBottom; j++, pntr -= perLine)
            for (int i = i1; i <= i2; i++)
                pntr[i] = (rgba[i] += ((pntr[i] << 4) - rgba[i]) * alpha / 16) >> 4;
    }

    for (int row = rTop; row <= rBottom; row++) {
        pntr = blurred.scanLine(row) + rRight * 4;
        for (int i = i1; i <= i2; i++)
            rgba[i] = pntr[i] << 4;

        pntr -= 4;
        for (int j = rLeft; j < rRight; j++, pntr -= 4)
            for (int i = i1; i <= i2; i++)
                pntr[i] = (rgba[i] += ((pntr[i] << 4) - rgba[i]) * alpha / 16) >> 4;
    }

    return blurred;
}

QString EtUtils::defaultServerIp() {
#ifdef QT_DEBUG
    return "57.128.191.73";
#else
    return "51.68.181.52";
#endif
}

QString EtUtils::formatterNumber(const BigNumberFloat number) {
    double             numberConverted = std::stod(number.to_string(NumeralBase::Dec));
    std::ostringstream stream;
    stream << std::fixed << std::setprecision(2) << numberConverted;
    std::string formattedNumber = stream.str();

    return QString::fromStdString(formattedNumber);
}
