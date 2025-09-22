#ifndef PROFILEDATA_H
#define PROFILEDATA_H

#include "utils/bignumber.h"
#include "utils/exc_utils.h"
#include <QDir>
#include <QFile>
#include <QList>
#include <QObject>
#include <QTextStream>

class WelcomePage : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isReg READ isReg WRITE setIsReg NOTIFY isRegChanged)
    Q_PROPERTY(QByteArray email READ email WRITE setEmail NOTIFY emailChanged)
    Q_PROPERTY(QByteArray password READ password WRITE setPassword NOTIFY passwordChanged)

private:
    bool status;

    bool passwordReapeat(QList<QString> data);
    bool emailRule(QList<QString> data);

    bool       m_isReg;
    QByteArray m_email;
    QByteArray m_password;
    QByteArray m_profileData;
    QByteArray m_userHash;

public:
    WelcomePage(QObject* parent = nullptr);
    ~WelcomePage();

    Q_INVOKABLE int     passwordRule(QString data);
    Q_INVOKABLE bool    emailCheck(QString data);
    Q_INVOKABLE QString hash() const;
    Q_INVOKABLE void    newUserHash(QByteArray hash);
    Q_INVOKABLE void    autoLogIn();

    bool       isReg() const;
    QByteArray email() const;
    QByteArray password() const;
    QByteArray getHash() const;
    QByteArray getChanges() const;

signals:
    void regStarted(QByteArray hash);
    // to userControler
    void logInStarted();
    //
    void autoLogInStarted();

    void isRegChanged(bool isReg);
    void emailChanged(QByteArray email);
    void passwordChanged(QByteArray password);

public slots:
    void setIsReg(bool isReg);
    void setEmail(QByteArray email);
    void setPassword(QByteArray password);
    void startReg(QByteArray email, QByteArray password);
};

#endif // PROFILEDATA_H
