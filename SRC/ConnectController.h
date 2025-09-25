#pragma once

#include <QObject>
#include <qsortfilterproxymodel.h>
#include "VpnConnectionChainList.h"

#include "SRC/ClientController.h"
#ifndef RACCOON_DISABLE_VPN
    #include "vpnmanager.h"
#endif
#include "Model/CountryModel.h"

constexpr int timer_interval = 30000;
class ExtraChainNode;
class ConnectStatus;

class ConnectController : public QObject {
    Q_OBJECT

public:
    enum StatusConnect {
        NotConnected,
        InProcess,
        Connected
    };

    Q_PROPERTY(StatusConnect connectStatus READ connectStatus WRITE setConnectStatus NOTIFY connectStatusChanged)
    Q_PROPERTY(QString connectTextButton READ connectTextButton WRITE setConnectTextButton NOTIFY
                   connectTextButtonChanged)
    Q_PROPERTY(QString currentConnectedIpAddress READ currentConnectedIpAddress WRITE setCurrentConnectedIpAddress
                   NOTIFY currentConnectedIpAddressChanged)
    Q_PROPERTY(VpnConnectionChainList *chainList READ chainList WRITE setChainList NOTIFY chainListChanged)
    Q_PROPERTY(bool enableConnectButton READ enableConnectButton WRITE setEnableConnectButton NOTIFY
                   enableConnectButtonChanged)
    Q_PROPERTY(bool signUpStage READ signUpStage WRITE setSignUpStage NOTIFY signUpStageChanged)
    Q_PROPERTY(CountryModel *countryModel READ countryModel WRITE setCountryModel NOTIFY countryModelChanged)
    Q_PROPERTY(QString currentCountry READ currentCountry WRITE setCurrentCountry NOTIFY currentCountryChanged)
    Q_PROPERTY(QSortFilterProxyModel *sortFilterCountryModel READ sortFilterCountryModel WRITE
                   setSortFilterCountryModel NOTIFY sortFilterCountryModelChanged FINAL)

    explicit ConnectController(QObject *parent = nullptr);
    ~ConnectController();


    StatusConnect connectStatus() const;
    void          setConnectStatus(StatusConnect newConnectStatus);

    QString connectTextButton() const;
    void    setConnectTextButton(const QString &newConnectTextButton);

    QString currentConnectedIpAddress() const;
    void    setCurrentConnectedIpAddress(const QString &newCurrentConnectedIpAddress);

    VpnConnectionChainList *chainList() const;
    void                    setChainList(VpnConnectionChainList *newChainList);

    bool enableConnectButton() const;
    void setEnableConnectButton(bool newEnableConnectButton);

    void changeRegistrationState() {
        emit showRegistrationMenu();
    }
    bool signUpStage() const;
    void setSignUpStage(bool newSignUpStage);
    void SetExtrachainNode(ExtraChainNode *node);

    QString currentCountry() const;

    const std::vector<CountryDetail> getCountriesList();
    void                             resetCoutryList();
    void                             addCountryToList(const QString                          &countryName,
                                                      const std::string                       actorID,
                                                      const raccoon::vpn::VPNManager::VPNType vpnType);
    void                             removeCountryFromList(const QString &countryName, const std::string actorID);
    bool                             containCountry(const QString &nameCountry);

    CountryModel *countryModel() const;
    void          setCountryModel(CountryModel *newCountryModel);

    void setCurrentCountry(const QString &newCurrentCountry);

    QSortFilterProxyModel *sortFilterCountryModel() const;
    void                   setSortFilterCountryModel(QSortFilterProxyModel *newSortFilterCountryModel);

public slots:
    void connectToVpnServer(const bool &random = false);
    void disconnectVpnServer();
    void disconnectVpnOnlyUI();
    void connectedToVpnServer(std::pair<QString, QString> publicIPAndCountry, bool proxy);
    void selectConnectCountry(const QString &country);
    void setCountSocketConnections(const int &count);

signals:
    void connectStatusChanged();
    void connectTextButtonChanged();
    void currentConnectedIpAddressChanged();
    void chainListChanged();
    void enableConnectButtonChanged();
    void showRegistrationMenu();
    void signUpStageChanged();
    void countryModelChanged();
    void currentCountryChanged();
    void errorConnectToVpn();
    void sortFilterCountryModelChanged();
    void closeApp();

protected:
    bool checkPossibleEnableButton();

private:
    void sendVPNCommand(bool is_random = false);

    ExtraChainNode         *node;
    StatusConnect           _connectStatus = StatusConnect::NotConnected;
    QString                 _connectTextButton;
    QString                 _currentConnectedIpAddress;
    QString                 _currentCountry;
    VpnConnectionChainList *_chainList            = nullptr;
    bool                    m_enableConnectButton = false;
    bool                    _signUpStage;
    int                     _countConnection;
    CountryModel           *_countryModel = nullptr;
    QTimer                 *timer;
    int                     m_vpn_send_try_counter = 0;
    bool                    m_vpn_random_sended    = false;
    QString                 m_currentCountrySelected;
    QSortFilterProxyModel  *_sortFilterCountryModel;
};

class MenuSelector : public QObject {
    Q_OBJECT
public:
    enum SelectorMenu {
        Vpn,
        Wallet,
        Dfs,
        Settings,
        Messenger,
        Locations,
        Notification
    };
    Q_ENUM(SelectorMenu)
};

class Onboarding : public QObject {
    Q_OBJECT
public:
    enum OnboardingPage {
        Vpn_Tab_To_Connect,                // 0
        Vpn_Connection_Status,             // 1
        Vpn_Location_Select,               // 2
        Mining_Info,                       // 3
        Wallet_Access,                     // 4
        Notifications_And_Settings,        // 5
        Storage_Space,                     // 6
        Storage_Upgrade,                   // 7
        Storage_Search,                    // 8
        Storage_View_Options,              // 9
        Storage_Notification_and_Settings, // 10
        Wallet_Estimate_Balance,           // 11
        Wallet_Transaction_List,           // 12
        Wallet_Select,                     // 13
        Finished
    };
    Q_ENUM(OnboardingPage)
};

class Tooltip : public QObject {
    Q_OBJECT
public:
    enum TooltipType {
        Deposit,
        Withdraw,
        Settings,
        UploadFile,
        Mining,
        CopiedAddress,
        Message
    };
    Q_ENUM(TooltipType)
};

class ConnectStatus : public QObject {
    Q_OBJECT

public:
    enum StatusConnect {
        NotConnected,
        InProcess,
        Connected
    };
    Q_ENUM(StatusConnect)
};
