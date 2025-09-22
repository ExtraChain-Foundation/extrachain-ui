#include <QDebug>
#include <QStandardPaths>
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    #include <unistd.h>
    #include <sys/types.h>
#endif

#include "keychainclass.h"

KeyChainClass::KeyChainClass(QObject *parent)
    : QObject(parent)
#ifdef RACCOON_MESSENGER
    , m_readCredentialJob(QLatin1String("com.raccoonline.messenger"))
    , m_writeCredentialJob(QLatin1String("com.raccoonline.messenger"))
    , m_deleteCredentialJob(QLatin1String("com.raccoonline.messenger")) {
#else
    , m_readCredentialJob(QLatin1String("com.raccoonline.vpnapp"))
    , m_writeCredentialJob(QLatin1String("com.raccoonline.vpnapp"))
    , m_deleteCredentialJob(QLatin1String("com.raccoonline.vpnapp")) {
#endif
    m_readCredentialJob.setAutoDelete(false);
    m_writeCredentialJob.setAutoDelete(false);
    m_deleteCredentialJob.setAutoDelete(false);
}

void KeyChainClass::readKey(const QString &key) {
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    // If running under root - try to switch to user context
    if (geteuid() == 0) {
        readKeyAsUser(key);
        return;
    }
#endif

    m_readCredentialJob.setKey(key);

    QObject::connect(&m_readCredentialJob, &QKeychain::ReadPasswordJob::finished, this, [this, key]() {
        if (m_readCredentialJob.error()) {
            emit error(tr("Read key failed: %1").arg(qPrintable(m_readCredentialJob.errorString())));
            return;
        }
        emit keyRestored(key, m_readCredentialJob.textData());
    });

    m_readCredentialJob.start();
}

void KeyChainClass::writeKey(const QString &key, const QString &value) {
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    // If running under root - try to switch to user context
    if (geteuid() == 0) {
        writeKeyAsUser(key, value);
        return;
    }
#endif

    m_writeCredentialJob.setKey(key);

    QObject::connect(&m_writeCredentialJob, &QKeychain::WritePasswordJob::finished, this, [this, key]() {
        if (m_writeCredentialJob.error()) {
            emit error(tr("Write key failed: %1").arg(qPrintable(m_writeCredentialJob.errorString())));
            return;
        }

        emit keyStored(key);
    });

    m_writeCredentialJob.setTextData(value);
    m_writeCredentialJob.start();
}

void KeyChainClass::deleteKey(const QString &key) {
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    // If running under root - try to switch to user context
    if (geteuid() == 0) {
        deleteKeyAsUser(key);
        return;
    }
#endif

    m_deleteCredentialJob.setKey(key);

    QObject::connect(&m_deleteCredentialJob, &QKeychain::DeletePasswordJob::finished, this, [this, key]() {
        if (m_deleteCredentialJob.error()) {
            emit error(tr("Delete key failed: %1").arg(qPrintable(m_deleteCredentialJob.errorString())));
            return;
        }
        emit keyDeleted(key);
    });

    m_deleteCredentialJob.start();
}

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
// Linux-specific methods for working under root privileges
void KeyChainClass::readKeyAsUser(const QString &key) {
    QString realUser = qgetenv("SUDO_USER");
    if (realUser.isEmpty()) {
        emit error(tr("Cannot determine real user for keychain access"));
        return;
    }

    // Temporarily drop privileges to user level
    uid_t sudo_uid = getenv("SUDO_UID") ? QString(getenv("SUDO_UID")).toInt() : 1000;
    gid_t sudo_gid = getenv("SUDO_GID") ? QString(getenv("SUDO_GID")).toInt() : 1000;

    uid_t old_euid = geteuid();
    gid_t old_egid = getegid();

    if (setegid(sudo_gid) != 0 || seteuid(sudo_uid) != 0) {
        emit error(tr("Failed to switch to user context"));
        return;
    }

    // Create temporary job for keychain operation
    QKeychain::ReadPasswordJob *tempJob = new QKeychain::ReadPasswordJob(m_readCredentialJob.service());
    tempJob->setKey(key);

    QObject::connect(tempJob,
                     &QKeychain::ReadPasswordJob::finished,
                     this,
                     [this, tempJob, key, old_euid, old_egid]() {
                         // Restore root privileges
                         seteuid(old_euid);
                         setegid(old_egid);

                         if (tempJob->error()) {
                             emit error(tr("Read key failed: %1").arg(qPrintable(tempJob->errorString())));
                         } else {
                             emit keyRestored(key, tempJob->textData());
                         }

                         tempJob->deleteLater();
                     });

    tempJob->start();
}

void KeyChainClass::writeKeyAsUser(const QString &key, const QString &value) {
    QString realUser = qgetenv("SUDO_USER");
    if (realUser.isEmpty()) {
        emit error(tr("Cannot determine real user for keychain access"));
        return;
    }

    // Temporarily drop privileges to user level
    uid_t sudo_uid = getenv("SUDO_UID") ? QString(getenv("SUDO_UID")).toInt() : 1000;
    gid_t sudo_gid = getenv("SUDO_GID") ? QString(getenv("SUDO_GID")).toInt() : 1000;

    uid_t old_euid = geteuid();
    gid_t old_egid = getegid();

    if (setegid(sudo_gid) != 0 || seteuid(sudo_uid) != 0) {
        emit error(tr("Failed to switch to user context"));
        return;
    }

    // Create temporary job for keychain operation
    QKeychain::WritePasswordJob *tempJob = new QKeychain::WritePasswordJob(m_writeCredentialJob.service());
    tempJob->setKey(key);
    tempJob->setTextData(value);

    QObject::connect(tempJob,
                     &QKeychain::WritePasswordJob::finished,
                     this,
                     [this, tempJob, key, old_euid, old_egid]() {
                         // Restore root privileges
                         seteuid(old_euid);
                         setegid(old_egid);

                         if (tempJob->error()) {
                             emit error(tr("Write key failed: %1").arg(qPrintable(tempJob->errorString())));
                         } else {
                             emit keyStored(key);
                         }

                         tempJob->deleteLater();
                     });

    tempJob->start();
}

void KeyChainClass::deleteKeyAsUser(const QString &key) {
    QString realUser = qgetenv("SUDO_USER");
    if (realUser.isEmpty()) {
        emit error(tr("Cannot determine real user for keychain access"));
        return;
    }

    // Temporarily drop privileges to user level
    uid_t sudo_uid = getenv("SUDO_UID") ? QString(getenv("SUDO_UID")).toInt() : 1000;
    gid_t sudo_gid = getenv("SUDO_GID") ? QString(getenv("SUDO_GID")).toInt() : 1000;

    uid_t old_euid = geteuid();
    gid_t old_egid = getegid();

    if (setegid(sudo_gid) != 0 || seteuid(sudo_uid) != 0) {
        emit error(tr("Failed to switch to user context"));
        return;
    }

    // Create temporary job for keychain operation
    QKeychain::DeletePasswordJob *tempJob = new QKeychain::DeletePasswordJob(m_deleteCredentialJob.service());
    tempJob->setKey(key);

    QObject::connect(tempJob,
                     &QKeychain::DeletePasswordJob::finished,
                     this,
                     [this, tempJob, key, old_euid, old_egid]() {
                         // Restore root privileges
                         seteuid(old_euid);
                         setegid(old_egid);

                         if (tempJob->error()) {
                             emit error(tr("Delete key failed: %1").arg(qPrintable(tempJob->errorString())));
                         } else {
                             emit keyDeleted(key);
                         }

                         tempJob->deleteLater();
                     });

    tempJob->start();
}
#endif // Q_OS_LINUX
