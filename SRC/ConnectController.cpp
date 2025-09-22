#include "ConnectController.h"
#include <QFuture>
#include <QUuid>
#include <QtConcurrent/QtConcurrent>

#include "managers/extrachain_node.h"
#include "network/network_manager.h"
#include "vpn_connector_manager.h"

ConnectController::ConnectController(QObject *parent)
    : QObject(parent) {
    setChainList(new VpnConnectionChainList(this));
    setConnectTextButton("Quick connect");
#ifdef RACCOON_DISABLE_VPN
    setConnectTextButton("VPN disabled");

#endif
    setConnectStatus(StatusConnect::NotConnected);
    _countryModel = new CountryModel(this);
    timer         = new QTimer(this);

    _sortFilterCountryModel = new QSortFilterProxyModel;
    _sortFilterCountryModel->setSourceModel(_countryModel);
    _sortFilterCountryModel->setFilterRole(CountryModel::CountryRoles::NameCountryRole);
    _sortFilterCountryModel->setFilterCaseSensitivity(Qt::CaseInsensitive);

#ifndef RACCOON_DISABLE_VPN
    connect(timer, &QTimer::timeout, this, [this] {
        if ((!m_vpnConnectorManager->vpnManagerMain || !m_vpnConnectorManager->vpnManagerMain->isConnected())
            && _connectStatus == StatusConnect::InProcess) {
            if (m_vpn_send_try_counter > 3 && m_vpn_random_sended) {
                m_vpnConnectorManager->ClearSavedCacheBeforeNextHandshake();

                setConnectTextButton("Quick connect");
                setConnectStatus(StatusConnect::NotConnected);
                emit errorConnectToVpn();
            } else if (m_vpn_send_try_counter > 3 && !m_vpn_random_sended) {
                eLog("Trying to send VPN connection request for RANDOM country.");
                sendVPNCommand(true);
            } else if (m_vpn_send_try_counter <= 3) {
                eLog("Trying to send VPN connection request, try number: {}", m_vpn_send_try_counter + 1);
                sendVPNCommand();
            }
        }
        setEnableConnectButton(true);
    });
    timer->setInterval(timer_interval);
#endif
}

void ConnectController::setVPNConnectorManager(VPNConnectorManager *vpnConnectorManager) {
    m_vpnConnectorManager = vpnConnectorManager;
    connect(m_vpnConnectorManager, &VPNConnectorManager::closeApp, this, &ConnectController::closeApp);

    m_vpnConnectorManager->setShutdownAllSlotCallback([this](bool isConnected) {
        eLog("VPN disconnected.");
        setConnectStatus(isConnected ? StatusConnect::Connected : StatusConnect::NotConnected);
        // _chainList->removeLastChainItem();
        // _chainList->removeLastChainItem();
        _chainList->removeToOne();
        setCurrentConnectedIpAddress(node->getInitPublicIPAndCountry().first);
        setCurrentCountry(node->getInitPublicIPAndCountry().second);
        emit chainListChanged();
        setConnectTextButton("Quick connect");

        setEnableConnectButton(true);
    });
}

ConnectController::~ConnectController() {
    eLog("[Destructor ConnectController]");
}

ConnectController::StatusConnect ConnectController::connectStatus() const {
    return _connectStatus;
}

void ConnectController::setConnectStatus(StatusConnect newConnectStatus) {
    if (_connectStatus == newConnectStatus)
        return;
    _connectStatus = newConnectStatus;
    emit connectStatusChanged();
}

void ConnectController::sendVPNCommand(bool is_random) {
    VPNMessage outputMsg;
#if defined(Q_OS_IOS)
    outputMsg.is_wireguard = true;
#endif
    outputMsg.vpnCommand      = static_cast<int>(NetworkVPNCommand::HANDSHAKE);
    outputMsg.vpnType         = static_cast<int>(NetworkVPNType::PROXY);
    outputMsg.countryEndpoint = is_random ? "RANDOM" : m_currentCountrySelected.toStdString();
    outputMsg.uuid            = QUuid::createUuid().toString(QUuid::WithoutBraces).toStdString();
    outputMsg.proxyCounter    = 1;
    outputMsg.publicIP        = node->getInitPublicIPAndCountry().first.toStdString();
    outputMsg.networkIdentifiersToIgnore.emplace(node->accountController()->system_actor().id().to_string());
    outputMsg.senderID = node->accountController()->system_actor().id().to_string();

    {
        auto tryingConnectionAllSendersLocked = *m_vpnConnectorManager->tryingConnectionAllSenders;
        outputMsg.blockedSenders.insert(tryingConnectionAllSendersLocked->begin(),
                                        tryingConnectionAllSendersLocked->end());
    }
    node->vpnConfigStorage.vpnIsClient = true;
    eInfo("ConnectController::connectToVpnServer, send VPN Handshake for \"{}\" with senderID: {}",
          outputMsg.countryEndpoint,
          node->accountController()->system_actor().id().to_string());
    eInfo("[VPN] network identifier: {}", node->network_identifier());

    CustomMessage customMessage;
    customMessage.data = MessagePack::serialize(outputMsg);
    node->network()->send_message(customMessage, MessageType::Custom, SendMode::Broadcast, MessageStatus::Request);

    m_vpn_send_try_counter++;
    if (is_random)
        m_vpn_random_sended = true;

    timer->start();
}

void ConnectController::connectToVpnServer(const bool &random) {
    if (_connectStatus == StatusConnect::NotConnected) {
        sendVPNCommand(random);
        setConnectStatus(StatusConnect::InProcess);
        setEnableConnectButton(true);
    }
}

void ConnectController::disconnectVpnServer() {
    if (_connectStatus == StatusConnect::Connected /*&& enableConnectButton()*/) {
        eInfo("MUTEX 2");
        setEnableConnectButton(false);

        auto vpnUuidToVPNWorkersLocked = *node->vpnConfigStorage.vpnUuidToVPNWorkers;
        auto item                      = vpnUuidToVPNWorkersLocked->begin();

        m_vpnConnectorManager->sendDisconnect(item->second.uuid,
                                              item->second.nextNodeID,
                                              item->second.nextNodeNetworkIdentifier);
        eInfo("VPNDisconnect send because triggered by USER: {}", item->second.nextNodeNetworkIdentifier);

        vpnUuidToVPNWorkersLocked->erase(item);
        node->vpnConfigStorage.vpnConnectedType = {};
        node->vpnConfigStorage.vpnIsClient      = false;

        // TODO: check do I need it or not on all OS ? QTimer::singleShot(2000, this, [this]() {...})
        eLog("Send shutdownAll");
        emit m_vpnConnectorManager->shutdownAll();
    }

    eLog("[ConnectController] Disconnect. Connection status: {}, button enabled: {}",
         _connectStatus,
         enableConnectButton());
}

void ConnectController::disconnectVpnOnlyUI() {
#ifndef RACCOON_DISABLE_VPN
    eLog("VPN disconnected due to Update Connection failure.");
    bool isConnected =
        (m_vpnConnectorManager->vpnManagerMain && m_vpnConnectorManager->vpnManagerMain->isConnected());
    setConnectStatus(isConnected ? StatusConnect::Connected : StatusConnect::NotConnected);
    // _chainList->removeLastChainItem();
    // _chainList->removeLastChainItem();
    _chainList->removeToOne();
    setCurrentConnectedIpAddress(node->getInitPublicIPAndCountry().first);
    setCurrentCountry(node->getInitPublicIPAndCountry().second);
    emit chainListChanged();
    setConnectTextButton("Quick connect");

    setEnableConnectButton(true);
#endif
}

// temp function
bool checkDomainConnection(const QString &domain, int port = 80, int timeoutMs = 1500) {
    QTcpSocket socket;
    bool       connectionSuccess = false;

    socket.connectToHost(domain, port);

    if (socket.waitForConnected(timeoutMs)) {
        connectionSuccess = true;

        QHostAddress localAddress  = socket.localAddress();
        QHostAddress remoteAddress = socket.peerAddress();

        qDebug() << "Connected successfully!";
        qDebug() << "Local IP:" << localAddress.toString();
        qDebug() << "Remote IP:" << remoteAddress.toString();

        bool isLocalNetwork = localAddress.isSiteLocal() && !localAddress.isLoopback();
        qDebug() << "Local IP is in local network:" << isLocalNetwork;

        socket.disconnectFromHost();
    } else {
        qDebug() << "Connection failed:" << socket.errorString();
    }

    return connectionSuccess;
}

void ConnectController::connectedToVpnServer(std::pair<QString, QString> publicIPAndCountry, bool proxy) {
    m_vpn_send_try_counter = 0;
    if (!publicIPAndCountry.second.isEmpty()) {
        _chainList->addChainItem(publicIPAndCountry.second, publicIPAndCountry.first);
        if (proxy) {
            _chainList->addChainItem("...", "");
        }

        emit chainListChanged();
        setConnectTextButton("Disconnect");
        setConnectStatus(StatusConnect::Connected);
        setCurrentConnectedIpAddress(publicIPAndCountry.first);
        setCurrentCountry(publicIPAndCountry.second);
        setEnableConnectButton(true);
    } else { // TODO: move to vpn connector
        auto is_connected = checkDomainConnection("http://raccoonline.com/");
        if (is_connected) {
            return;
        }

        eLog("VPN disconnected. Because No network...");
        emit m_vpnConnectorManager->shutdownAll();

        setEnableConnectButton(true);
        QTimer::singleShot(2000, this, [this]() {
            auto vpnUuidToVPNWorkersLocked = *node->vpnConfigStorage.vpnUuidToVPNWorkers;
            if (!vpnUuidToVPNWorkersLocked->empty()) {
                auto item = vpnUuidToVPNWorkersLocked->begin();

                m_vpnConnectorManager->sendDisconnect(item->second.uuid,
                                                      item->second.nextNodeID,
                                                      item->second.nextNodeNetworkIdentifier);
                eInfo("VPNDisconnect send because no network!");
                vpnUuidToVPNWorkersLocked->erase(item);
            }

            node->vpnConfigStorage.vpnConnectedType = {};
            node->vpnConfigStorage.vpnIsClient      = false;

            setConnectStatus(StatusConnect::NotConnected);
            setEnableConnectButton(true);
        });
    }
}

void ConnectController::selectConnectCountry(const QString &country) {
    eLog("select connect country: {}", country);
    m_currentCountrySelected = country;
}

void ConnectController::setCountSocketConnections(const int &count) {
    eLog("count connections now: {}", count);
    _countConnection = count;
    setEnableConnectButton(checkPossibleEnableButton());
}

bool ConnectController::checkPossibleEnableButton() {
    return (_countConnection > 0 && !_connectStatus && !_countryModel->empty());
}

QString ConnectController::currentCountry() const {
    return _currentCountry;
}

QString ConnectController::connectTextButton() const {
    return _connectTextButton;
}

void ConnectController::setConnectTextButton(const QString &newConnectTextButton) {
    if (_connectTextButton == newConnectTextButton)
        return;
    _connectTextButton = newConnectTextButton;
    emit connectTextButtonChanged();
}

QString ConnectController::currentConnectedIpAddress() const {
    return _currentConnectedIpAddress;
}

void ConnectController::setCurrentConnectedIpAddress(const QString &newCurrentConnectedIpAddress) {
    if (_currentConnectedIpAddress == newCurrentConnectedIpAddress)
        return;
    _currentConnectedIpAddress = newCurrentConnectedIpAddress;
    emit currentConnectedIpAddressChanged();
}

VpnConnectionChainList *ConnectController::chainList() const {
    return _chainList;
}

void ConnectController::setChainList(VpnConnectionChainList *newChainList) {
    if (_chainList == newChainList)
        return;
    _chainList = newChainList;
    emit chainListChanged();
}

bool ConnectController::enableConnectButton() const {
    return m_enableConnectButton;
}

void ConnectController::setEnableConnectButton(bool newEnableConnectButton) {
    if (m_enableConnectButton == newEnableConnectButton)
        return;
    m_enableConnectButton = newEnableConnectButton;
    emit enableConnectButtonChanged();
}

bool ConnectController::signUpStage() const {
    return _signUpStage;
}

void ConnectController::setSignUpStage(bool newSignUpStage) {
    if (_signUpStage == newSignUpStage)
        return;
    _signUpStage = newSignUpStage;
    emit signUpStageChanged();
}

void ConnectController::SetExtrachainNode(ExtraChainNode *node) {
    this->node = node;

    setCurrentConnectedIpAddress(this->node->getInitPublicIPAndCountry().first);
    setCurrentCountry(this->node->getInitPublicIPAndCountry().second);
    _chainList->addChainItem(this->node->getInitPublicIPAndCountry().second,
                             this->node->getInitPublicIPAndCountry().first);
    setEnableConnectButton(false);
}

const std::vector<CountryDetail> ConnectController::getCountriesList() {
    return _countryModel->getCountries();
}

void ConnectController::addCountryToList(const QString                          &countryName,
                                         const std::string                       actorID,
                                         const raccoon::vpn::VPNManager::VPNType vpnType) {
    _countryModel->addCountry(countryName, actorID, vpnType);
    setEnableConnectButton(checkPossibleEnableButton());
}

void ConnectController::removeCountryFromList(const QString &countryName, const std::string actorID) {
    _countryModel->removeCountry(countryName, actorID);
}

bool ConnectController::containCountry(const QString &nameCountry) {
    return _countryModel->contain(nameCountry);
}

void ConnectController::resetCoutryList() {
    _countryModel->clear();
    emit countryModelChanged();
}

CountryModel *ConnectController::countryModel() const {
    return _countryModel;
}

void ConnectController::setCountryModel(CountryModel *newCountryModel) {
    if (_countryModel == newCountryModel)
        return;
    _countryModel = newCountryModel;
    emit countryModelChanged();
}

void ConnectController::setCurrentCountry(const QString &newCurrentCountry) {
    if (_currentCountry == newCurrentCountry)
        return;
    _currentCountry = newCurrentCountry;
    emit currentCountryChanged();
}

QSortFilterProxyModel *ConnectController::sortFilterCountryModel() const {
    return _sortFilterCountryModel;
}

void ConnectController::setSortFilterCountryModel(QSortFilterProxyModel *newSortFilterCountryModel) {
    if (_sortFilterCountryModel == newSortFilterCountryModel)
        return;
    _sortFilterCountryModel = newSortFilterCountryModel;
    emit sortFilterCountryModelChanged();
}
