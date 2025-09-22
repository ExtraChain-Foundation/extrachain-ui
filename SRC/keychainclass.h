#ifndef KEYCHAINCLASS_H
#define KEYCHAINCLASS_H

#include <QObject>

#include <qtkeychain/keychain.h>

class KeyChainClass : public QObject {
    Q_OBJECT

public:
    KeyChainClass(QObject* parent = nullptr);

public slots:
    void readKey(const QString& key);
    void writeKey(const QString& key, const QString& value);
    void deleteKey(const QString& key);

signals:
    void keyStored(const QString& key);
    void keyRestored(const QString& key, const QString& value);
    void keyDeleted(const QString& key);
    void error(const QString& errorText);

private:
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    void readKeyAsUser(const QString& key);
    void writeKeyAsUser(const QString& key, const QString& value);
    void deleteKeyAsUser(const QString& key);
#endif

    QKeychain::ReadPasswordJob   m_readCredentialJob;
    QKeychain::WritePasswordJob  m_writeCredentialJob;
    QKeychain::DeletePasswordJob m_deleteCredentialJob;
};

#endif // KEYCHAINCLASS_H
