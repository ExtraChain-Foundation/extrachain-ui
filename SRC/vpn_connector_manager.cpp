#include "vpn_connector_manager.h"

#include <managers/extrachain_node.h>
#include <managers/account_controller.h>
#include "managers/data_mining_manager.h"
#include <network/network_manager.h>
#include "dfs/dfs_controller.h"
#include "network/websocket_service.h"
#include "ipnetwork.h"

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    #include "SRC/Linux/InterfaceStats.h"
#endif

#ifdef __APPLE__
    #ifdef USE_SWIFT
extern "C" {

void startVPN(const char* config, const char* server, bool* result);
void stopVPN(void);
}
    #endif
#endif

VPNConnectorManagerWrapper::VPNConnectorManagerWrapper(ExtraChainNode* node, QObject* parent)
    : QObject(parent)
    , vpnConnectorManager(new VPNConnectorManager(node)) {
    m_thread = new QThread();
    vpnConnectorManager->moveToThread(m_thread);
    connect(m_thread, &QThread::started, vpnConnectorManager, &VPNConnectorManager::Init);
    connect(m_thread, &QThread::finished, m_thread, &QObject::deleteLater);
    m_thread->start();
}

VPNConnectorManagerWrapper::~VPNConnectorManagerWrapper() {
    eLog("[VPN] VPNConnectorManagerWrapper::~VPNConnectorManagerWrapper");

    m_thread->quit();
    m_thread->wait();
    vpnConnectorManager->deleteLater();
}

VPNConnectorManager::VPNConnectorManager(ExtraChainNode* node)
    : m_node(node) {
#ifdef Q_OS_ANDROID
    m_singBoxController = new SingBoxController(this);
    connect(m_singBoxController, &SingBoxController::closeApp, this, &VPNConnectorManager::closeApp);
#endif
    g_vpnConnectorManagerInstance = this;
    // send_vpns_request();
}

void VPNConnectorManager::Init() {
#ifndef RACCOON_DISABLE_VPN
    // vpnManager = raccoon::vpn::VPNManager::create();
    vpnManagerWg = raccoon::vpn::VPNManager::create(raccoon::vpn::VPNManager::VPNType::WIREGUARD);
    #if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
    vpnManagerSing = raccoon::vpn::VPNManager::create(raccoon::vpn::VPNManager::VPNType::SINGBOX);
    #else
    vpnManagerSing = vpnManagerWg;
    #endif

    QCoreApplication* app = QCoreApplication::instance();
    m_workerThread        = std::make_unique<VPNWorkerThread>(this, m_node, app);
    m_workerThread->start();

    QObject::connect(app, &QCoreApplication::aboutToQuit, m_workerThread.get(), [this]() {
        m_workerThread->stop();
        m_workerThread->wait();
    });

    eLog("[VPN] VPNConnectorManager::Init");
    connect(m_node->network(),
            &NetworkManager::customMessageReceived,
            this,
            &VPNConnectorManager::networkCallbackSlot);

    connect(this, &VPNConnectorManager::shutdownAll, this, &VPNConnectorManager::shutdownAllSlot);

    connect(m_node->network(),
            &NetworkManager::newSocketActivatedWithParams,
            [this](const std::string ip, const std::string identifier) {
                // send_vpn_status(current_status, identifier);

                auto waitNewSocketCommandStorage = *m_waitNewSocketCommandStorage;
                auto res                         = waitNewSocketCommandStorage->find(ip);
                if (res != waitNewSocketCommandStorage->end())
                    res->second(identifier);
            });

    m_clearSocketsTimer = new QTimer(this);
    connect(m_clearSocketsTimer, &QTimer::timeout, this, &VPNConnectorManager::clearSockets);
    m_clearSocketsTimer->start(5000);
#else
    connect(m_node->network(),
            &NetworkManager::customMessageReceived,
            this,
            &VPNConnectorManager::networkCallbackSlot);
#endif
}

void VPNConnectorManager::clearSockets() {
#ifndef RACCOON_DISABLE_VPN
    if (vpnManagerMain == nullptr || !vpnManagerMain->isConnected()) {
        auto networkConnections = *m_node->network()->connections();
        int  constantAmount     = 0;
        for (auto& itNetwork : *networkConnections) {
            if (itNetwork->is_constant())
                constantAmount++;
        }

        for (auto itNetwork = networkConnections->begin(); itNetwork != networkConnections->end(); ++itNetwork) {
            if ((*itNetwork)->is_vpn()) {
                if (constantAmount > 1 && itNetwork != networkConnections->begin()) {
                    (*itNetwork)->set_constant(false);
                    constantAmount--;
                }
                (*itNetwork)->set_vpn(false);
            }
        }
    }
#endif
}

VPNConnectorManager::~VPNConnectorManager() {
    if (g_vpnConnectorManagerInstance == this) {
        g_vpnConnectorManagerInstance = nullptr;
    }

    eLog("[VPN] VPNConnectorManager::~VPNConnectorManager start destruction.");
    m_workerThread->stop();
    m_workerThread->wait();
    eLog("[VPN] VPNConnectorManager::~VPNConnectorManager destruction finished.");
}

bool VPNConnectorManager::CheckVPNHandshakeAccess(const std::string& requesterNodeID, const int counter) {
    // eLog("[VPN] VPNConnectorManager::CheckVPNHandshakeAccess, size: {}",
    //      m_node->vpnConfigStorage.vpnHandhakeCacheInProccess->size());
    auto vpnHandhakeCacheInProccessLocked = *m_node->vpnConfigStorage.vpnHandhakeCacheInProccess;
    for (auto it = vpnHandhakeCacheInProccessLocked->begin(); it != vpnHandhakeCacheInProccessLocked->end();) {
        if (it->requesterNodeID == requesterNodeID) {
            eLog("[VPN] VPNConnectorManager::CheckVPNHandshakeAccess found");
            it->timestamp = QDateTime::currentDateTime();
            ++it;
            return true;
        } else {
            QDateTime currentTime = QDateTime::currentDateTime();
            if (it->timestamp.secsTo(currentTime) >= 10) {
                eLog("[VPN] DELETED vpnHandhakeCacheInProccess {}", it->uuid);
                it = vpnHandhakeCacheInProccessLocked->erase(it);
            } else
                ++it;
        }
    }

    eLog("[VPN] VPNConnectorManager::CheckVPNHandshakeAccess not found");
    return vpnHandhakeCacheInProccessLocked->size() < counter;
}

VPNWorkerThread::VPNWorkerThread(VPNConnectorManager* vpnConnectorManager, ExtraChainNode* node, QObject* parent)
    : QThread(parent)
    , m_vpnConnectorManager(vpnConnectorManager)
    , m_node(node)
    , m_running(true) {
}

void VPNWorkerThread::run() {
    auto updateLastSingSync =
        [&](VPNConfigStorage::VPNWorkers& cache, qint64 currentTimestamp, bool isClient = false) -> bool {
        if (!m_vpnConnectorManager->vpnManagerMain) {
            eLog("[Vpn] VPN run number {}, invalid vpn manager pointer", cache.chainIndex);
            return false;
        }
        auto transferedData = m_vpnConnectorManager->vpnManagerMain->getSignBoxActiveData(cache.chainIndex);
        if (!transferedData.has_value()) {
            eLog("[Vpn] VPN run number {}, no transfered data", cache.chainIndex);
            return false;
        }
        auto transferedDataObj = *transferedData;
        eLog("[Vpn] VPN number: {},  Received bytes: {}; Transfered bytes: {}; Memory: {}",
             cache.chainIndex,
             transferedDataObj.downloadTotal,
             transferedDataObj.uploadTotal,
             transferedDataObj.memory);

        bool wasUpdated = false;

        if (cache.lastSingDownloadedBytes != transferedDataObj.downloadTotal) {
            cache.lastSingDownloadedBytes = transferedDataObj.downloadTotal;
            wasUpdated                    = true;
        }
        if (!isClient && cache.lastSingUploadedBytes != transferedDataObj.uploadTotal) {
            cache.lastSingUploadedBytes = transferedDataObj.uploadTotal;
            wasUpdated                  = true;
        }
        if (wasUpdated)
            cache.lastUpdateRequsterTS = currentTimestamp;
        return true;
    };

    eLog("[VPN] VPNWorkerThread thread running...");
    while (m_running) {
        if (m_vpnConnectorManager->m_node->vpnConfigStorage.vpnConnectedType.has_value()) {
            auto vpnUuidToVPNWorkersLocked = *m_vpnConnectorManager->m_node->vpnConfigStorage.vpnUuidToVPNWorkers;
            for (auto it = vpnUuidToVPNWorkersLocked->begin(); it != vpnUuidToVPNWorkersLocked->end(); ++it) {
                if (m_vpnConnectorManager->m_node->vpnConfigStorage.vpnConnectedType != NetworkVPNType::CLIENT) {
                    if (m_vpnConnectorManager->vpnManagerMain->getVPNType()
                        == raccoon::vpn::VPNManager::VPNType::WIREGUARD) {
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
                        qint64 currentTimestamp = QDateTime::currentMSecsSinceEpoch();
                        if (currentTimestamp - it->second.lastRunExecuteTS >= 10000
                            || it->second.lastRunExecuteTS == -1) {
                            it->second.lastRunExecuteTS = currentTimestamp;

                            std::string interface_name =
                                m_vpnConnectorManager->m_node->vpnConfigStorage.vpnConnectedType
                                        == NetworkVPNType::PROXY
                                    ? "RACCOON_PROXY_" + std::to_string(it->second.chainIndex)
                                    : "RACCOON_SERVER";
                            eLog("[Vpn] Check interface: {}...", interface_name);

                            auto stats = m_vpnConnectorManager->vpnManagerWg->getLatestHandshake(interface_name);
                            auto [received_bytes, transfered_bytes] =
                                m_vpnConnectorManager->vpnManagerWg->getLatestTransfer(interface_name);
                            eLog("[Vpn] Received bytes: {}; Transfered bytes: {}",
                                 received_bytes,
                                 transfered_bytes);
                            QMap<QString, quint64> handshake_wg_container;

                            const QStringList stats_lines =
                                QString::fromStdString(stats).split('\n', Qt::SkipEmptyParts);
                            for (const QString& line : stats_lines) {
                                const QStringList parts = line.split('\t');
                                if (parts.size() != 2)
                                    continue;

                                QString key   = parts[0];
                                bool    ok    = false;
                                quint64 value = parts[1].toULongLong(&ok);
                                if (ok)
                                    handshake_wg_container.insert(key, value);
                                else
                                    eWarning("[Vpn] Checker: Failed to parse value for key: {}", key);
                            }

                            qint64 handshake_wg_timestamp_requester = -1;
                            auto   handshake_wg_timestamp_it =
                                handshake_wg_container.find(QString::fromStdString(it->second.requesterPublicKey));
                            if (handshake_wg_timestamp_it != handshake_wg_container.end()) {
                                handshake_wg_timestamp_requester = handshake_wg_timestamp_it.value();
                                eLog("[Vpn] Checker: last handshake timestamp found for requester: {}",
                                     handshake_wg_timestamp_requester);
                            }

                            qint64 handshake_wg_timestamp_next = -1;
                            if (m_vpnConnectorManager->m_node->vpnConfigStorage.vpnConnectedType
                                == NetworkVPNType::PROXY) {
                                handshake_wg_timestamp_it =
                                    handshake_wg_container.find(QString::fromStdString(it->second.nextPublicKey));
                                if (handshake_wg_timestamp_it != handshake_wg_container.end()) {
                                    handshake_wg_timestamp_next = handshake_wg_timestamp_it.value();
                                    eLog("[Vpn] Checker: last handshake timestamp found for next: {}",
                                         handshake_wg_timestamp_next);
                                }

                                if (handshake_wg_timestamp_next == -1) {
                                    eLog(
                                        "[Vpn] Checker: last handshake timestamp for next not found! Achieved "
                                        "output: ",
                                        stats);
                                } else if (it->second.lastWGTimestampNext != handshake_wg_timestamp_next) {
                                    it->second.lastWGTimestampNext = handshake_wg_timestamp_next;
                                    it->second.lastUpdateNextTS    = currentTimestamp;
                                    continue;
                                }
                            }

                            if (handshake_wg_timestamp_requester == -1) {
                                eLog(
                                    "[Vpn] Checker: last handshake timestamp for requester not found! Achieved "
                                    "output: ",
                                    stats);
                            } else if (it->second.lastWGTimestampRequester != handshake_wg_timestamp_requester) {
                                it->second.lastWGTimestampRequester = handshake_wg_timestamp_requester;
                                it->second.lastUpdateRequsterTS     = currentTimestamp;
                                continue;
                            }
                        }

                        qint64 currentTimestamp_new = QDateTime::currentMSecsSinceEpoch();
                        bool   server_loss = ((m_vpnConnectorManager->m_node->vpnConfigStorage.vpnConnectedType
                                             == NetworkVPNType::PROXY)
                                            && (currentTimestamp_new - it->second.lastUpdateNextTS >= 150000));
                        if (server_loss || (currentTimestamp_new - it->second.lastUpdateRequsterTS >= 150000)) {
                            eLog("[Vpn] Checker: vpn shutdown. Server status: {}.  ", server_loss);
                            auto uuid = it->first;
                            m_vpnConnectorManager->disconnectVPN(uuid);
                            break;

                            if (!server_loss
                                && m_vpnConnectorManager->m_node->vpnConfigStorage.vpnConnectedType
                                       == NetworkVPNType::PROXY) {
                                eLog("[Vpn] Checker: vpn shutdown. Send disconnect to the server.");
                                m_vpnConnectorManager->sendDisconnect(uuid,
                                                                      it->second.nextNodeID,
                                                                      it->second.nextNodeNetworkIdentifier);
                            }
                        }
#endif
                    } else {
                        qint64 currentTimestamp = QDateTime::currentMSecsSinceEpoch();
                        if (currentTimestamp - it->second.lastRunExecuteTS >= 10000
                            || it->second.lastRunExecuteTS == -1) {
                            it->second.lastRunExecuteTS = currentTimestamp;

                            if (!updateLastSingSync(it->second, currentTimestamp))
                                continue;
                        }

                        qint64 currentTimestamp_new = QDateTime::currentMSecsSinceEpoch();
                        if (currentTimestamp_new - it->second.lastUpdateRequsterTS >= 150000
                            && it->second.lastUpdateRequsterTS != -1) {
                            eLog("[Vpn] Checker: vpn shutdown. VPN index: {}.", it->second.chainIndex);
                            auto uuid = it->first;
                            m_vpnConnectorManager->disconnectVPN(uuid);
                            break;

                            if (m_vpnConnectorManager->m_node->vpnConfigStorage.vpnConnectedType
                                == NetworkVPNType::PROXY) {
                                eLog("[Vpn] Checker: vpn shutdown. Send disconnect to the server.");
                                m_vpnConnectorManager->sendDisconnect(uuid,
                                                                      it->second.nextNodeID,
                                                                      it->second.nextNodeNetworkIdentifier);
                            }
                        }
                    }
                } else {
                    qint64 currentTimestamp = QDateTime::currentMSecsSinceEpoch();
                    if (currentTimestamp - it->second.lastRunExecuteTS >= 10000
                        || it->second.lastRunExecuteTS == -1) {
                        it->second.lastRunExecuteTS = currentTimestamp;

                        if (!updateLastSingSync(it->second, currentTimestamp, true))
                            continue;
                    }

                    qint64 currentTimestamp_new = QDateTime::currentMSecsSinceEpoch();
                    if (currentTimestamp_new - it->second.lastUpdateRequsterTS >= 150000
                        && it->second.lastUpdateRequsterTS != -1) {
                        eLog("[Vpn] Checker: vpn shutdown. VPN index: {}. it->second.lastUpdateRequsterTS: {}",
                             it->second.chainIndex,
                             it->second.lastUpdateRequsterTS);
                        auto uuid = it->first;

                        emit m_vpnConnectorManager->disconnectVpn();
                    }
                }
            }
        }

        {
            auto vpnHandhakeCacheInProccessLocked = *m_node->vpnConfigStorage.vpnHandhakeCacheInProccess;
            for (auto it = vpnHandhakeCacheInProccessLocked->begin();
                 it != vpnHandhakeCacheInProccessLocked->end();) {
                QDateTime currentTime = QDateTime::currentDateTime();
                if (it->timestamp.secsTo(currentTime) >= 10) {
                    eLog("[VPN] DELETED vpnHandhakeCacheInProccess {}", it->uuid);
                    it = vpnHandhakeCacheInProccessLocked->erase(it);
                } else
                    ++it;
            }
        }

        {
            auto m_indexes_handshake_can_be_blocked_locked =
                *m_vpnConnectorManager->m_indexes_handshake_can_be_blocked;
            for (auto it = m_indexes_handshake_can_be_blocked_locked->begin();
                 it != m_indexes_handshake_can_be_blocked_locked->end();) {
                QDateTime currentTime = QDateTime::currentDateTime();
                if (it->second.secsTo(currentTime) >= 10) {
                    it = m_indexes_handshake_can_be_blocked_locked->erase(it);
                } else
                    ++it;
            }
        }

        QThread::sleep(2);
    }
    eLog("[VPN] VPNWorkerThread thread stopped.");
}

void VPNWorkerThread::stop() {
    m_running = false;
}

void VPNConnectorManager::ClearSavedCacheBeforeNextHandshake() {
    m_tryingConnection = false;
    tryingConnectionAllSenders->clear();
}

void VPNConnectorManager::send_vpn_status(bool                              status,
                                          raccoon::vpn::VPNManager::VPNType type,
                                          const std::string&                identifier) {
#ifndef RACCOON_CONSOLE
    return;
#endif

    if (status != current_status || current_type != type) {
        current_status = status;
        current_type   = type;
    }

    auto          system_id = m_node->accountController()->system_actor().id();
    auto          country   = m_node->getInitPublicIPAndCountry().second.toStdString();
    CustomMessage customMessage;
    auto          country_message = VpnCountryMessage { .actor   = system_id,
                                                        .country = country.empty() ? "Other" : country,
                                                        .status  = status,
                                                        .type    = type };
    customMessage.data            = MessagePack::serialize(country_message);
    Responder responder;

    eDebug("VPNConnectorManager::send_vpn_status: {}, {}, {}",
           country_message.country,
           country_message.status,
           country_message.type);

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    if (identifier.empty()) {
        // if server, for tests
        // eLog("Send country: '{}'", country);
        m_node->network()->send_message(customMessage,
                                        MessageType::Custom,
                                        SendMode::Broadcast,
                                        MessageStatus::NoStatus);
    } else {
        Responder responder;
        responder.add_identifier(identifier);
        m_node->network()->send_message(customMessage,
                                        MessageType::Custom,
                                        SendMode::Focused,
                                        MessageStatus::NoStatus,
                                        responder);

        // eLog("Send country: '{}' to '{}'", country, identifier);
    }
#endif
}

void VPNConnectorManager::setShutdownAllSlotCallback(std::function<void(bool)> callback) {
    m_shutdownAllSlotCallback = std::move(callback);
}

void VPNConnectorManager::send_vpns_request() {
    if (m_node->accountController()->empty()) {
        return;
    }

    eLog("Request vpns...");
    CustomMessage custom_message;
    custom_message.data = MessagePack::serialize(true);
    m_node->network()->send_message(custom_message, MessageType::Custom, SendMode::Broadcast);
}

void VPNConnectorManager::processHandshake(const CustomMessage&         customPackage,
                                           const VPNMessage&            inputMsg,
                                           const NetworkPackageStorage& packageData) {
#ifndef RACCOON_DISABLE_VPN
    auto inputVPNType = static_cast<NetworkVPNType>(inputMsg.vpnType);
    if (packageData.msg_body.status == MessageStatus::Response) {
        if (inputVPNType == NetworkVPNType::SERVER || inputVPNType == NetworkVPNType::PROXY) {
            eLog("[VPN] Response 1");
            if (m_node->vpnConfigStorage.vpnIsClient) {
                if (vpnManagerMain || /*vpnManager->isConnected() ||*/ m_tryingConnection) {
                    eLog("[VPN] VPN handshake response invalid. Client already in process.");
                    return;
                }

                eLog("[VPN] Response 1 1");
                std::string chainIndexStr = inputMsg.resultChainIndex < 10
                                                ? "0" + std::to_string(inputMsg.resultChainIndex)
                                                : std::to_string(inputMsg.resultChainIndex);

                // TODO: save ? inputMsg.publicIP;
                eLog("[VPN] Response 1 1 1");
                VPNMessage outputMsg;
                outputMsg.is_wireguard  = inputMsg.is_wireguard;
                outputMsg.initialSender = m_node->accountController()->currentProfile().system().id().to_string();
                outputMsg.vpnCommand    = static_cast<int>(NetworkVPNCommand::CONNECTION);
                outputMsg.vpnType       = static_cast<int>(NetworkVPNType::PROXY);
                outputMsg.allIPsToSet.emplace_back("100.1" + chainIndexStr + ".0.1");
                outputMsg.publicKey        = vpnManagerWg->getPublicKeys()[0];
                outputMsg.proxyCounter     = 1;
                outputMsg.resultChainIndex = inputMsg.resultChainIndex;
                outputMsg.uuid             = inputMsg.uuid;
                outputMsg.lookingForNodeID = inputMsg.senderID;

                eLog("[VPN] Response 1 1 2");

                QString identifierToSend;
                {
                    auto networkConnections = *m_node->network()->connections();
                    for (auto it = networkConnections->begin(); it != networkConnections->end(); ++it) {
                        if ((*it)->ip().toStdString() == inputMsg.publicIP
                            && (*it)->identifier() == inputMsg.initialSenderNetworkIdentifier) {
                            identifierToSend = (*it)->identifier();
                            break;
                        }
                    }
                }

                CustomMessage custom_message;
                custom_message.data = MessagePack::serialize(outputMsg);
                auto mainActor      = m_node->accountController()->system_actor();

                if (!identifierToSend.isEmpty()) {
                    m_tryingConnection = true;
                    tryingConnectionAllSenders->insert(inputMsg.allSenders.begin(), inputMsg.allSenders.end());

                    setConstantSocketByIdentifier(identifierToSend.toStdString(), true, true);

                    Responder responder(m_node->network());
                    responder.add_identifier(identifierToSend.toStdString());
                    auto sended_message_id = m_node->network()->send_message(custom_message,
                                                                             MessageType::Custom,
                                                                             SendMode::Focused,
                                                                             MessageStatus::Request,
                                                                             responder);

                    eLog("[VPN] SENDED VPN CONNECTION REQUEST {} {}", inputMsg.publicIP, sended_message_id);
                } else {
                    bool canProceed = true;
                    if (m_node->network()->active_connections_count() >= Network::maxConnections) {
                        canProceed = m_node->network()->removeOneConnection();
                    }
                    if (canProceed) {
                        m_tryingConnection = true;
                        tryingConnectionAllSenders->insert(inputMsg.allSenders.begin(), inputMsg.allSenders.end());

                        eLog("[VPN] processHandshake, Creating NEW connection {}",
                             QString::fromStdString(inputMsg.publicIP));
                        // TODO: may connect to wrong server if IP is same
                        m_node->network()->connectToNode(QString::fromStdString(inputMsg.publicIP),
                                                         Network::Protocol::WebSocket,
                                                         false,
                                                         true);

                        m_waitNewSocketCommandStorage->emplace(
                            inputMsg.publicIP,
                            [custom_message, publicIP = inputMsg.publicIP, this](
                                const std::string& identifierToSend) {
                                setConstantSocketByIdentifier(identifierToSend, true, true);

                                Responder responder(m_node->network());
                                responder.add_identifier(identifierToSend);
                                auto sended_message_id = m_node->network()->send_message(custom_message,
                                                                                         MessageType::Custom,
                                                                                         SendMode::Focused,
                                                                                         MessageStatus::Request,
                                                                                         responder);

                                eLog("[VPN] SENDED VPN CONNECTION REQUEST FROM wait socket storage {}, {}",
                                     publicIP,
                                     sended_message_id);
                            });
                    } else
                        eLog("[VPN] VPN connection request failed to send. (unknown identifier)");
                }
            } else {
                eLog("[VPN] Response 1 2");
                VPNMessage outputMsg;
                outputMsg.is_wireguard  = inputMsg.is_wireguard;
                outputMsg.initialSender = m_node->accountController()->currentProfile().system().id().to_string();
                outputMsg.allSenders    = inputMsg.allSenders;
                outputMsg.allSenders.emplace(outputMsg.initialSender);
                outputMsg.initialSenderNetworkIdentifier = m_node->network_identifier();
                outputMsg.vpnCommand                     = static_cast<int>(NetworkVPNCommand::HANDSHAKE);
                outputMsg.uuid                           = inputMsg.uuid;
                outputMsg.vpnType                        = inputMsg.vpnType;
                outputMsg.resultChainIndex               = inputMsg.resultChainIndex;
                outputMsg.publicIP                       = m_node->getInitPublicIPAndCountry().first.toStdString();
                outputMsg.senderID = m_node->accountController()->system_actor().id().to_string();

                eLog("[VPN] Response 1 2 1");

                eLog("[VPN] MUTEX 5");
                auto vpnHandhakeCacheInProccessLocked = *m_node->vpnConfigStorage.vpnHandhakeCacheInProccess;
                for (auto& it : *vpnHandhakeCacheInProccessLocked) {
                    if (it.uuid == inputMsg.uuid && !it.is_sended) {
                        it.nextNodeIP                = inputMsg.publicIP;
                        it.nextNodeNetworkIdentifier = inputMsg.initialSenderNetworkIdentifier;
                        it.nextNodeID                = inputMsg.senderID;
                        it.timestamp                 = QDateTime::currentDateTime();
                        it.chainIndex                = inputMsg.resultChainIndex;

                        auto emplace_res =
                            m_indexes_handshake_can_be_blocked->emplace(it.chainIndex, it.timestamp);
                        if (!emplace_res.second) {
                            eCritical(
                                "[VPN] Proxy handshake result from server ignored. Because chain Index already "
                                "blocked: {}",
                                it.chainIndex);
                            return;
                        }

                        outputMsg.lookingForNodeID = it.requesterNodeID;

                        it.is_sended = true;

                        eLog("[VPN] Response 1 2 2");
                        CustomMessage customMessage;
                        customMessage.data = MessagePack::serialize(outputMsg);
                        Responder responder(m_node->network());
                        responder.set_message_id(it.requesterMessageID);
                        auto sendedMessageID = m_node->network()->send_message(customMessage,
                                                                               MessageType::Custom,
                                                                               SendMode::Focused,
                                                                               MessageStatus::Response,
                                                                               responder);
                        eLog("[VPN] SENDED VPN handshake response {} {}",
                             m_node->accountController()->system_actor().id().to_string(),
                             sendedMessageID);

                        break;
                    }
                }
            }
        }
    } else if (packageData.msg_body.status == MessageStatus::Request) {
        if (inputVPNType == NetworkVPNType::SERVER) {
            // eLog("[VPN] Request server 1");
            auto vpnHandhakeCacheInProccessLocked = *m_node->vpnConfigStorage.vpnHandhakeCacheInProccess;
            for (const auto& it : *vpnHandhakeCacheInProccessLocked) {
                if (it.requesterMessageID == packageData.msg_body.message_id) {
                    eLog("[VPN] VPN Package ignored: dublicate.");
                    return;
                }
            }
            // eLog("[VPN] Request server 2");

            if (!checkHandshakeAccess(packageData.prev_identifier, 100)) {
                eLog("[VPN] VPN Package ignored: no empty handshake slots for SERVER {} {}",
                     m_node->accountController()->system_actor().id().to_string(),
                     packageData.msg_body.message_id);
                return;
            }

            if (inputMsg.blockedSenders.contains(
                    m_node->accountController()->currentProfile().system().id().to_string())) {
                eLog("[VPN] VPN Package ignored. Actor blocked by user.");
                return;
            }

            if (!inputMsg.countryEndpoint.empty()
                && inputMsg.countryEndpoint != m_node->getInitPublicIPAndCountry().second.toStdString()) {
                // eLog("{} {} {}",
                //      "[VPN] VPN Package ignored: SERVER country ("
                //          + m_node->getInitPublicIPAndCountry().second.toStdString() + ") not matched with - "
                //          + inputMsg.countryEndpoint,
                //      m_node->accountController()->system_actor().id().to_string(),
                //      packageData.msg_body.message_id);
                if (inputMsg.countryEndpoint != "RANDOM")
                    return;
            }

            if (checkVPNAvailability(NetworkVPNType::SERVER,
                                     inputMsg.is_wireguard ? raccoon::vpn::VPNManager::VPNType::WIREGUARD
                                                           : raccoon::vpn::VPNManager::VPNType::SINGBOX)) {
                eLog("[VPN] Request server 3 1 1");

                VPNMessage outputMsg;
                outputMsg.is_wireguard  = inputMsg.is_wireguard;
                outputMsg.initialSender = m_node->accountController()->currentProfile().system().id().to_string();
                outputMsg.allSenders.emplace(outputMsg.initialSender);
                outputMsg.initialSenderNetworkIdentifier = m_node->network_identifier();
                outputMsg.vpnCommand                     = static_cast<int>(NetworkVPNCommand::HANDSHAKE);
                outputMsg.vpnType                        = static_cast<int>(NetworkVPNType::SERVER);
                outputMsg.uuid                           = inputMsg.uuid;
                outputMsg.lookingForNodeID               = inputMsg.senderID;
                outputMsg.publicIP                       = m_node->getInitPublicIPAndCountry().first.toStdString();

                eLog("[VPN] Request server 3 1 2");

                std::set<int> blockedChainIndexes;
                if (vpnManagerMain)
                    blockedChainIndexes = vpnManagerMain->getBlockChainIndexes();
                else
                    blockedChainIndexes = vpnManagerSing->getBlockChainIndexes();

                eLog("[VPN] Request server 3 1 3");
                std::set<int> lockedChainIndexAll = inputMsg.lockedChainIndex;
                lockedChainIndexAll.insert(blockedChainIndexes.begin(), blockedChainIndexes.end());
                eLog("[VPN] Request server 3 1 4");
                bool isFound = false;
                for (int i = 0; i < 100; ++i) {
                    if (!lockedChainIndexAll.contains(i)) {
                        outputMsg.resultChainIndex = i;
                        isFound                    = true;
                        break;
                    }
                }
                eLog("[VPN] Request server 3 1 5 {} {}", isFound, outputMsg.resultChainIndex);
                if (!isFound)
                    return;

                CustomMessage customMessage;
                customMessage.data = MessagePack::serialize(outputMsg);

                Responder responder(m_node->network());
                responder.set_message_id(packageData.msg_body.message_id);
                auto sendedMessageID = m_node->network()->send_message(customMessage,
                                                                       MessageType::Custom,
                                                                       SendMode::Focused,
                                                                       MessageStatus::Response,
                                                                       responder);

                eLog("[VPN] Request server SEND Response {}", sendedMessageID);

                eLog("[VPN] Emplaced vpnHandhakeCacheInProccess {} {}", inputMsg.uuid, outputMsg.resultChainIndex);
                m_node->vpnConfigStorage.vpnHandhakeCacheInProccess->emplaceBack(
                    VPNConfigStorage::VPNHandhakeCache {
                        .uuid = inputMsg.uuid,
                        // .requesterIP        = inputMsg.publicIP,
                        // .requesterNetworkIdentifier = inputMsg.initialSenderNetworkIdentifier,
                        .requesterMessageID = packageData.msg_body.message_id,
                        .requesterNodeID    = inputMsg.senderID,
                        .chainIndex         = outputMsg.resultChainIndex,
                        .timestamp          = QDateTime::currentDateTime(),
                        .is_wireguard       = inputMsg.is_wireguard });
            } else {
                eLog("[VPN] VPN Package ignored: Server is impossible to create. {} {}",
                     m_node->accountController()->system_actor().id().to_string(),
                     packageData.msg_body.message_id);
            }
        } else if (inputVPNType == NetworkVPNType::PROXY) {
            eLog("[VPN] Request proxy 1");
            auto vpnHandhakeCacheInProccessLocked = *m_node->vpnConfigStorage.vpnHandhakeCacheInProccess;
            for (const auto& it : *vpnHandhakeCacheInProccessLocked) {
                if (it.requesterMessageID == packageData.msg_body.message_id) {
                    eLog("[VPN] VPN Package ignored: dublicate.");
                    return;
                }
            }

            eLog("[VPN] Request proxy 2");

            if (!checkHandshakeAccess(packageData.prev_identifier, 8)) {
                eLog("[VPN] VPN Package ignored: no empty handshake slots for Proxy {} {}",
                     m_node->accountController()->system_actor().id(),
                     packageData.msg_body.message_id);
                return;
            }

            if (inputMsg.blockedSenders.contains(
                    m_node->accountController()->currentProfile().system().id().to_string())) {
                eLog("[VPN] VPN Package ignored. Actor blocked by user.");
                return;
            }

            if (checkVPNAvailability(NetworkVPNType::PROXY,
                                     inputMsg.is_wireguard ? raccoon::vpn::VPNManager::VPNType::WIREGUARD
                                                           : raccoon::vpn::VPNManager::VPNType::SINGBOX)) {
                eLog("[VPN] Request proxy 2 1 1");

                VPNMessage outputMsg;
                outputMsg.is_wireguard  = inputMsg.is_wireguard;
                outputMsg.initialSender = m_node->accountController()->currentProfile().system().id().to_string();
                outputMsg.vpnCommand    = static_cast<int>(NetworkVPNCommand::HANDSHAKE);
                outputMsg.uuid          = inputMsg.uuid;
                outputMsg.countryEndpoint            = inputMsg.countryEndpoint;
                outputMsg.networkIdentifiersToIgnore = inputMsg.networkIdentifiersToIgnore;
                outputMsg.networkIdentifiersToIgnore.emplace(
                    m_node->accountController()->system_actor().id().to_string());
                outputMsg.publicIP = m_node->getInitPublicIPAndCountry().first.toStdString();
                outputMsg.senderID = m_node->accountController()->system_actor().id().to_string();

                std::set<int> blockedChainIndexes;
                if (vpnManagerMain)
                    blockedChainIndexes = vpnManagerMain->getBlockChainIndexes();
                else
                    blockedChainIndexes = vpnManagerSing->getBlockChainIndexes();

                outputMsg.lockedChainIndex = inputMsg.lockedChainIndex;
                outputMsg.lockedChainIndex.insert(blockedChainIndexes.begin(), blockedChainIndexes.end());

                {
                    auto m_indexes_handshake_can_be_blocked_locked = *m_indexes_handshake_can_be_blocked;
                    for (auto it : *m_indexes_handshake_can_be_blocked_locked) {
                        QDateTime currentTime = QDateTime::currentDateTime();
                        if (it.second.secsTo(currentTime) >= 10)
                            outputMsg.lockedChainIndex.insert(it.first);
                    }
                }

                if (inputMsg.proxyCounter - 1 > 0) {
                    outputMsg.vpnType      = static_cast<int>(NetworkVPNType::PROXY);
                    outputMsg.proxyCounter = inputMsg.proxyCounter - 1;
                } else {
                    outputMsg.vpnType = static_cast<int>(NetworkVPNType::SERVER);
                }

                eLog("[VPN] Emplaced vpnHandhakeCacheInProccess {} {}", inputMsg.uuid, outputMsg.resultChainIndex);
                m_node->vpnConfigStorage.vpnHandhakeCacheInProccess->emplaceBack(
                    VPNConfigStorage::VPNHandhakeCache {
                        .uuid = inputMsg.uuid,
                        // .requesterIP        = inputMsg.publicIP,
                        // .requesterNetworkIdentifier = inputMsg.initialSenderNetworkIdentifier,
                        .requesterMessageID = packageData.msg_body.message_id,
                        .requesterNodeID    = inputMsg.senderID,
                        .nextNodeIDType     = static_cast<NetworkVPNType>(outputMsg.vpnType),
                        .timestamp          = QDateTime::currentDateTime(),
                        .is_wireguard       = inputMsg.is_wireguard });

                eLog("[VPN] Request proxy 2 1 6");
                CustomMessage customMessage;
                customMessage.data   = MessagePack::serialize(outputMsg);
                auto sendedMessageID = m_node->network()->send_message(customMessage,
                                                                       MessageType::Custom,
                                                                       SendMode::Broadcast,
                                                                       MessageStatus::Request);
                eLog("[VPN] Request proxy SEND Request {} {} {}",
                     outputMsg.vpnType,
                     m_node->accountController()->system_actor().id().to_string(),
                     sendedMessageID);
            } else {
                eLog("[VPN] VPN Package ignored: Proxy is impossible to create. {} {}",
                     m_node->accountController()->system_actor().id().to_string(),
                     packageData.msg_body.message_id);
            }
        }
    }
#endif
}

void VPNConnectorManager::processConnection(const VPNMessage&            networkInput,
                                            const NetworkPackageStorage& packageData) {
#ifndef RACCOON_DISABLE_VPN
    auto inputMsg     = networkInput;
    auto inputVPNType = static_cast<NetworkVPNType>(inputMsg.vpnType);
    if (packageData.msg_body.status == MessageStatus::Response) {
        if (inputVPNType == NetworkVPNType::SERVER || inputVPNType == NetworkVPNType::PROXY) {
            if (m_node->vpnConfigStorage.vpnIsClient) {
                setConstantSocketByIdentifier(packageData.prev_identifier, true, true);
                QTimer::singleShot(2000,
                                   this,
                                   [this,
                                    inputMsg,
                                    senderID   = packageData.msg_body.sender_id,
                                    identifier = packageData.prev_identifier,
                                    inputVPNType]() mutable {
                                       eLog("[VPN] Response client 1");
                                       // here open client VPN
                                       raccoon::vpn::VPNManager::VPNType vpnType =
                                           inputMsg.is_wireguard ? raccoon::vpn::VPNManager::VPNType::WIREGUARD
                                                                 : raccoon::vpn::VPNManager::VPNType::SINGBOX;
                                       if (setClient(inputMsg, senderID, vpnType)) {
                                           m_tryingConnection = false;
                                           tryingConnectionAllSenders->clear();

                                           eLog("[VPN] Response client 1 1");
                                           if (vpnManagerMain->isConnected()) {
                                               QString ip;
                                               quint16 port;
                                               QString tempIdentifier = QString::fromStdString(identifier);
                                               auto    networkReconnectionsLocked =
                                                   *m_node->network()->reconnections();
                                               for (auto it = networkReconnectionsLocked->begin();
                                                    it != networkReconnectionsLocked->end();
                                                    ++it) {
                                                   if (it->second == tempIdentifier) {
                                                       ip   = it->first.ip;
                                                       port = it->first.port;
                                                       break;
                                                   }
                                               }

                                               eLog("[VPN] Response client 1 1 1");
                                               m_node->vpnConfigStorage.vpnUuidToVPNWorkers
                                                   ->emplace(inputMsg.uuid,
                                                             VPNConfigStorage::VPNWorkers {
                                                                 .uuid       = inputMsg.uuid,
                                                                 .chainIndex = inputMsg.resultChainIndex,
                                                                 .nextNodeID = senderID.to_string(),
                                                                 .nextNodeIP = inputMsg.publicIP,
                                                                 .nextNodeNetworkIdentifier = identifier,
                                                                 .lastUpdateNextTS =
                                                                     QDateTime::currentMSecsSinceEpoch(),
                                                                 .lastSendedNextTS =
                                                                     QDateTime::currentMSecsSinceEpoch() });
                                               m_node->vpnConfigStorage.vpnConnectedType = NetworkVPNType::CLIENT;
                                               // node->network()->reconnection();

                                               eLog("[VPN] Connected to vpn. Receiving public ip...");
                                               auto publicIpAndCountry =
                                                   m_node->network()->getPublicIPAndCountry();

                                               if (inputVPNType == NetworkVPNType::PROXY) {
                                                   QString proxyIp = QString::fromStdString(inputMsg.publicIP);
                                                   auto    publicIpAndCountryProxy =
                                                       m_node->network()->getPublicIPAndCountry(proxyIp);
                                                   emit m_node->vpnConnected(std::move(publicIpAndCountryProxy),
                                                                             true);
                                               }

                                               emit m_node->vpnConnected(std::move(publicIpAndCountry), false);
                                               /// TODO: log
                                           }
                                       }
                                       eLog("[VPN] Response client end");
                                   });
            } else {
                eLog("[VPN] Response proxy 1");
                eLog("[VPN] MUTEX 9");
                auto vpnHandhakeCacheInProccessLocked = *m_node->vpnConfigStorage.vpnHandhakeCacheInProccess;
                for (auto it = vpnHandhakeCacheInProccessLocked->begin();
                     it != vpnHandhakeCacheInProccessLocked->end();
                     ++it) {
                    if (it->chainIndex == inputMsg.resultChainIndex && it->uuid == inputMsg.uuid) {
                        eLog("[VPN] Response proxy 2");
                        it->timestamp     = QDateTime::currentDateTime();
                        it->nextPublicKey = inputMsg.publicKey;

                        raccoon::vpn::VPNManager::ConfigSingBox configSing;
                        raccoon::vpn::VPNManager::VPNType       vpnType =
                            it->is_wireguard ? raccoon::vpn::VPNManager::VPNType::WIREGUARD
                                                   : raccoon::vpn::VPNManager::VPNType::SINGBOX;
                        std::string publicKey;
                        if (!it->is_wireguard) {
                            configSing = vpnManagerSing->createSignBoxConfig().value();
                            publicKey =
                                vpnManagerSing
                                    ->getPublicKeys()[m_node->vpnConfigStorage.vpnUuidToVPNWorkers->size()];
                        } else
                            publicKey =
                                vpnManagerWg
                                    ->getPublicKeys()[m_node->vpnConfigStorage.vpnUuidToVPNWorkers->size()];

                        eLog("[VPN] Response proxy 3, public key index: {}",
                             m_node->vpnConfigStorage.vpnUuidToVPNWorkers->size());
                        std::cout << "[VPN] Response proxy 3" << std::endl;
                        VPNMessage outputMsg;
                        outputMsg.initialSender =
                            m_node->accountController()->currentProfile().system().id().to_string();
                        outputMsg.vpnCommand       = static_cast<int>(NetworkVPNCommand::CONNECTION);
                        outputMsg.publicKey        = publicKey;
                        outputMsg.vpnType          = static_cast<int>(NetworkVPNType::PROXY);
                        outputMsg.resultChainIndex = inputMsg.resultChainIndex;
                        outputMsg.uuid             = inputMsg.uuid;
                        outputMsg.publicIP         = m_node->getInitPublicIPAndCountry().first.toStdString();
                        outputMsg.lookingForNodeID = it->requesterNodeID;
                        outputMsg.is_wireguard     = it->is_wireguard;

                        if (vpnType == raccoon::vpn::VPNManager::VPNType::SINGBOX) {
                            outputMsg.sing_uuid = configSing.uuid;
                            outputMsg.short_ids = configSing.short_ids;
                        }

                        CustomMessage custom_message;
                        custom_message.data = MessagePack::serialize(outputMsg);

                        // QString identifierToSend;
                        // {
                        //     auto networkConnections = *m_node->network()->connections();
                        //     for (auto itNetwork = networkConnections->begin();
                        //          itNetwork != networkConnections->end();
                        //          ++itNetwork) {
                        //         if ((*itNetwork)->ip().toStdString() == it->requesterIP &&
                        //         (*itNetwork)->identifier() == it->requesterNetworkIdentifier) {
                        //             identifierToSend = (*itNetwork)->identifier();
                        //             break;
                        //         }
                        //     }
                        // }

                        if (!it->requesterNetworkIdentifier.empty()) {
                            setConstantSocketByIdentifier(it->requesterNetworkIdentifier, true, true);

                            Responder responder(m_node->network());
                            responder.add_identifier(it->requesterNetworkIdentifier);
                            auto sended_message_id = m_node->network()->send_message(custom_message,
                                                                                     MessageType::Custom,
                                                                                     SendMode::Focused,
                                                                                     MessageStatus::Response,
                                                                                     responder);

                            eLog("[VPN] Response proxy SEND connection response {} {}",
                                 m_node->accountController()->system_actor().id().to_string(),
                                 sended_message_id);
                            std::cout << "[VPN] Response proxy SEND connection response" << std::endl;

                            // if (it->is_wireguard)
                            // {
                            QTimer::singleShot(
                                200,
                                this,
                                [this,
                                 inputMsg,
                                 outputMsg,
                                 // requesterIP     = it->requesterIP,
                                 nextNodeIP                = it->nextNodeIP,
                                 nextNodeNetworkIdentifier = it->nextNodeNetworkIdentifier,
                                 sender_id                 = packageData.msg_body.sender_id,
                                 identifier                = packageData.prev_identifier,
                                 requesterNodeID           = it->requesterNodeID,
                                 requesterPublicKey        = it->requesterPublicKey,
                                 nextPublicKey             = it->nextPublicKey,
                                 nextNodeID                = it->nextNodeID,
                                 vpnType,
                                 configSing]() mutable {
                                    if (setProxy(inputMsg, sender_id, vpnType, configSing)) {
                                        QString requesterIdentifier = QString::fromStdString(requesterNodeID);
                                        QString nextIdentifier      = QString::fromStdString(nextNodeID);
                                        eLog("Identifiers req&next {} {}", requesterNodeID, nextNodeID);
                                        int i = 0;
                                        m_node->vpnConfigStorage.vpnUuidToVPNWorkers
                                            ->emplace(inputMsg.uuid,
                                                      VPNConfigStorage::VPNWorkers {
                                                          .uuid                      = inputMsg.uuid,
                                                          .chainIndex                = inputMsg.resultChainIndex,
                                                          .requesterNodeID           = requesterNodeID,
                                                          .requesterPublicKey        = requesterPublicKey,
                                                          .nextPublicKey             = nextPublicKey,
                                                          .nextNodeID                = nextNodeID,
                                                          .nextNodeIP                = nextNodeIP,
                                                          .nextNodeNetworkIdentifier = identifier,
                                                          .lastUpdateRequsterTS =
                                                              QDateTime::currentMSecsSinceEpoch(),
                                                          .lastUpdateNextTS = QDateTime::currentMSecsSinceEpoch(),
                                                          .lastSendedNextTS =
                                                              QDateTime::currentMSecsSinceEpoch() });
                                        m_node->vpnConfigStorage.vpnConnectedType = NetworkVPNType::PROXY;

                                        {
                                            auto m_indexes_handshake_can_be_blocked_locked =
                                                *m_indexes_handshake_can_be_blocked;
                                            for (auto it = m_indexes_handshake_can_be_blocked_locked->begin();
                                                 it != m_indexes_handshake_can_be_blocked_locked->end();) {
                                                QDateTime currentTime = QDateTime::currentDateTime();
                                                if (it->second.secsTo(currentTime) >= 10) {
                                                    it = m_indexes_handshake_can_be_blocked_locked->erase(it);
                                                } else
                                                    ++it;
                                            }
                                        }
                                    } else {
                                        eLog("Init proxy failed, delete all next...");
                                        sendDisconnect(inputMsg.uuid, nextNodeID, nextNodeNetworkIdentifier);
                                    }
                                });
                            // }
                        } else {
                            eCritical("[VPN] Response proxy SEND connection failed: no identifier. ");
                            // {
                            //     auto        networkConnections = *m_node->network()->connections();
                            //     std::string temp;
                            //     for (auto itNetwork = networkConnections->begin();
                            //          itNetwork != networkConnections->end();
                            //          ++itNetwork) {
                            //         temp = (*itNetwork)->ip().toStdString() + "; ";
                            //     }
                            //     eCritical("[VPN] existing IPs: {}", temp);
                            // }
                        }
                        break;
                    }
                }
                eLog("[VPN] Response proxy end");
                std::cout << "[VPN] Response proxy end" << std::endl;
            }
        }

    } else if (packageData.msg_body.status == MessageStatus::Request) {
        eLog("[VPN] Achieved VPNConnection(Request)");
        if (inputVPNType == NetworkVPNType::SERVER) {
            eLog("[VPN] Request server 1");
            bool                              canProccess = false;
            raccoon::vpn::VPNManager::VPNType vpnType;
            {
                eLog("[VPN] MUTEX 11 {} {} {}",
                     inputMsg.resultChainIndex,
                     inputMsg.uuid,
                     packageData.prev_identifier);
                auto vpnHandhakeCacheInProccessLocked = *m_node->vpnConfigStorage.vpnHandhakeCacheInProccess;
                for (auto& it : *vpnHandhakeCacheInProccessLocked) {
                    eLog("[VPN] vpnHandhakeCacheInProccess {} {} {}", it.chainIndex, it.uuid, it.requesterNodeID);
                    if (it.chainIndex == inputMsg.resultChainIndex && it.uuid == inputMsg.uuid
                        && it.requesterNodeID == packageData.msg_body.sender_id.to_string()) {
                        eLog("[VPN] vpnHandhakeCacheInProccess inside");
                        canProccess  = true;
                        vpnType      = it.is_wireguard ? raccoon::vpn::VPNManager::VPNType::WIREGUARD
                                                       : raccoon::vpn::VPNManager::VPNType::SINGBOX;
                        it.timestamp = QDateTime::currentDateTime();
                        break;
                    }
                }
            }

            if (canProccess) {
                eLog("[VPN] Request server 2 1");

                // open VPN server
                raccoon::vpn::VPNManager::ConfigSingBox configSing;
                if (setServer(inputMsg, packageData.msg_body.sender_id, vpnType, configSing)) {
                    eLog("[VPN] Request server 2 1 1");
                    VPNMessage outputMsg;
                    outputMsg.initialSender =
                        m_node->accountController()->currentProfile().system().id().to_string();
                    outputMsg.vpnCommand       = static_cast<int>(NetworkVPNCommand::CONNECTION);
                    outputMsg.publicKey        = vpnManagerMain->getPublicKeys()[0];
                    outputMsg.vpnType          = static_cast<int>(NetworkVPNType::SERVER);
                    outputMsg.resultChainIndex = inputMsg.resultChainIndex;
                    outputMsg.uuid             = inputMsg.uuid;
                    outputMsg.lookingForNodeID = packageData.msg_body.sender_id.to_string();

                    if (vpnType == raccoon::vpn::VPNManager::VPNType::SINGBOX) {
                        outputMsg.sing_uuid = configSing.uuid;
                        outputMsg.short_ids = configSing.short_ids;
                    }

                    bool ipCountrySuccess = false;
                    auto ipCountry        = m_node->network()->getPublicIPAndCountry();
                    if (!ipCountry.first.isEmpty()) {
                        outputMsg.publicIP = ipCountry.first.toStdString();
                        ipCountrySuccess   = true;
                    }

                    if (!ipCountrySuccess) {
                        eCritical(
                            "[VPN] Achieved VPNConnection(Request) SERVER command but cannot "
                            "get Public IP");
                        return;
                    }

                    {
                        m_node->vpnConfigStorage.vpnUuidToVPNWorkers
                            ->emplace(inputMsg.uuid,
                                      VPNConfigStorage::VPNWorkers {
                                          .uuid                 = inputMsg.uuid,
                                          .chainIndex           = inputMsg.resultChainIndex,
                                          .requesterNodeID      = packageData.msg_body.sender_id.to_string(),
                                          .requesterPublicKey   = inputMsg.publicKey,
                                          .lastUpdateRequsterTS = QDateTime::currentMSecsSinceEpoch() });
                        m_node->vpnConfigStorage.vpnConnectedType = NetworkVPNType::SERVER;
                    }

                    setConstantSocketByIdentifier(packageData.prev_identifier, true, true);

                    CustomMessage customMessage;
                    customMessage.data = MessagePack::serialize(outputMsg);

                    Responder responder(m_node->network());
                    responder.set_message_id(packageData.msg_body.message_id);
                    auto sendedMessageID = m_node->network()->send_message(customMessage,
                                                                           MessageType::Custom,
                                                                           SendMode::Focused,
                                                                           MessageStatus::Response,
                                                                           responder);

                    eLog("[VPN] Request server SEND connection response {} {}",
                         m_node->accountController()->system_actor().id().to_string(),
                         sendedMessageID);

                    {
                        auto vpnHandhakeCacheInProccessLocked =
                            *m_node->vpnConfigStorage.vpnHandhakeCacheInProccess;
                        for (auto it = vpnHandhakeCacheInProccessLocked->begin();
                             it != vpnHandhakeCacheInProccessLocked->end();) {
                            if (it->chainIndex == inputMsg.resultChainIndex && it->uuid == inputMsg.uuid) {
                                eLog("[VPN] DELETED vpnHandhakeCacheInProccess {}", it->uuid);
                                it = vpnHandhakeCacheInProccessLocked->erase(it);
                            } else
                                ++it;
                        }
                    }
                }
            }
            eLog("[VPN] Request server end");
        } else if (inputVPNType == NetworkVPNType::PROXY) {
            eLog("[VPN] Request proxy 1 {} {} {}",
                 inputMsg.resultChainIndex,
                 inputMsg.uuid,
                 packageData.prev_identifier);
            eLog("[VPN] MUTEX 13");
            auto vpnHandhakeCacheInProccessLocked = *m_node->vpnConfigStorage.vpnHandhakeCacheInProccess;
            for (auto& it : *vpnHandhakeCacheInProccessLocked) {
                eLog("[VPN] inside check {} {} {}", it.chainIndex, it.uuid, it.requesterNodeID);
                if (it.chainIndex == inputMsg.resultChainIndex && it.uuid == inputMsg.uuid
                    && it.requesterNodeID == packageData.msg_body.sender_id.to_string()) {
                    it.timestamp              = QDateTime::currentDateTime();
                    std::string chainIndexStr = inputMsg.resultChainIndex < 10
                                                    ? "0" + std::to_string(inputMsg.resultChainIndex)
                                                    : std::to_string(inputMsg.resultChainIndex);

                    it.localIPForSetup = "101." + std::to_string(inputMsg.proxyCounter) + chainIndexStr + ".0.1";
                    it.proxyCounter    = inputMsg.proxyCounter;
                    it.allIPsToSet     = inputMsg.allIPsToSet;
                    it.requesterPublicKey         = inputMsg.publicKey;
                    it.requesterNetworkIdentifier = packageData.prev_identifier;

                    VPNMessage outputMsg;
                    outputMsg.initialSender =
                        m_node->accountController()->currentProfile().system().id().to_string();
                    outputMsg.vpnCommand  = static_cast<int>(NetworkVPNCommand::CONNECTION);
                    outputMsg.vpnType     = static_cast<int>(it.nextNodeIDType);
                    outputMsg.allIPsToSet = inputMsg.allIPsToSet;
                    outputMsg.allIPsToSet.emplace_back(it.localIPForSetup);
                    outputMsg.publicKey =
                        vpnManagerWg->getPublicKeys()[m_node->vpnConfigStorage.vpnUuidToVPNWorkers->size()];
                    outputMsg.proxyCounter     = inputMsg.proxyCounter + 1;
                    outputMsg.uuid             = inputMsg.uuid;
                    outputMsg.resultChainIndex = inputMsg.resultChainIndex;
                    outputMsg.lookingForNodeID = it.nextNodeID;

                    CustomMessage custom_message;
                    custom_message.data = MessagePack::serialize(outputMsg);

                    QString identifierToSend;
                    {
                        auto networkConnections = *m_node->network()->connections();
                        for (auto itNetwork = networkConnections->begin(); itNetwork != networkConnections->end();
                             ++itNetwork) {
                            if ((*itNetwork)->ip().toStdString() == it.nextNodeIP
                                && (*itNetwork)->identifier() == it.nextNodeNetworkIdentifier) {
                                identifierToSend = (*itNetwork)->identifier();
                                break;
                            }
                        }
                    }

                    if (!identifierToSend.isEmpty()) {
                        setConstantSocketByIdentifier(identifierToSend.toStdString(), true, true);

                        Responder responder(m_node->network());
                        responder.add_identifier(identifierToSend.toStdString());
                        auto sended_message_id = m_node->network()->send_message(custom_message,
                                                                                 MessageType::Custom,
                                                                                 SendMode::Focused,
                                                                                 MessageStatus::Request,
                                                                                 responder);

                        eLog("[VPN] Request proxy SEND connection request {}", sended_message_id);
                    } else {
                        bool canProceed = true;
                        if (m_node->network()->active_connections_count() >= Network::maxConnections) {
                            canProceed = m_node->network()->removeOneConnection();
                        }
                        if (canProceed) {
                            eLog("[VPN] processConnection, Creating NEW connection {}",
                                 QString::fromStdString(inputMsg.publicIP));

                            m_node->network()->connectToNode(QString::fromStdString(inputMsg.publicIP),
                                                             Network::Protocol::WebSocket,
                                                             false,
                                                             true);

                            m_waitNewSocketCommandStorage
                                ->emplace(inputMsg.publicIP,
                                          [custom_message, publicIP = inputMsg.publicIP, this](
                                              const std::string& identifierToSend) {
                                              setConstantSocketByIdentifier(identifierToSend, true, true);

                                              Responder responder(m_node->network());
                                              responder.add_identifier(identifierToSend);
                                              auto sended_message_id =
                                                  m_node->network()->send_message(custom_message,
                                                                                  MessageType::Custom,
                                                                                  SendMode::Focused,
                                                                                  MessageStatus::Request,
                                                                                  responder);

                                              eLog(
                                                  "[VPN] Request proxy SEND connection request FROM wait socket "
                                                  "storage {}, {}",
                                                  publicIP,
                                                  sended_message_id);
                                          });
                        } else
                            eLog("[VPN] Request proxy SEND fail: no identifier");
                    }
                    break;
                }
            }
            eLog("[VPN] Request server end");
        }
    }
#endif
}

void VPNConnectorManager::processDisconnect(const VPNMessage&            networkInput,
                                            const NetworkPackageStorage& packageData) {
    auto inputMsg = networkInput;
    eLog("[VPN] Achieved VPNDisconnect(Request)");
    if (m_node->vpnConfigStorage.vpnConnectedType.has_value()
        && m_node->vpnConfigStorage.vpnConnectedType.value() != NetworkVPNType::SERVER) {
        eLog("[VPN] MUTEX 14");
        auto res = m_node->vpnConfigStorage.vpnUuidToVPNWorkers->find(inputMsg.uuid);
        if (res != m_node->vpnConfigStorage.vpnUuidToVPNWorkers->end()) {
            VPNMessage outputMsg       = inputMsg;
            outputMsg.initialSender    = m_node->accountController()->currentProfile().system().id().to_string();
            outputMsg.lookingForNodeID = res->second.nextNodeID;

            // QString identifierToSend;
            // {
            //     auto networkConnections = *m_node->network()->connections();
            //     for (auto itNetwork = networkConnections->begin(); itNetwork != networkConnections->end();
            //          ++itNetwork) {
            //         if ((*itNetwork)->ip().toStdString() == res->second.nextNodeIP) {
            //             identifierToSend = (*itNetwork)->identifier();
            //             break;
            //         }
            //     }
            // }
            if (!res->second.nextNodeNetworkIdentifier.empty()) {
                CustomMessage custom_message;
                custom_message.data = MessagePack::serialize(outputMsg);

                Responder responder(m_node->network());
                responder.add_identifier(res->second.nextNodeNetworkIdentifier);
                auto sended_message_id = m_node->network()->send_message(custom_message,
                                                                         MessageType::Custom,
                                                                         SendMode::Focused,
                                                                         MessageStatus::Request,
                                                                         responder);

                eLog("[VPN] VPNDisconnect send VPNDisconnect {}", sended_message_id);
            } else
                eLog("[VPN] VPNDisconnect send VPNDisconnect fail: empty identifier.");
        }
    }

    QTimer::singleShot(200, this, [this, uuid = inputMsg.uuid]() mutable {
        disconnectVPN(uuid);
    });
}

void VPNConnectorManager::networkCallbackSlot(const NetworkPackageStorage packageData,
                                              const CustomMessage         customPackage) {
    try {
        if (m_node->isRaccoon) {
            auto vpnPackageExp = MessagePack::deserialize<VPNMessage>(customPackage.data);

            if (!vpnPackageExp.has_value()) {
                auto msg_vpn_servers         = MessagePack::deserialize<VpnServers>(customPackage.data);
                auto msg_vpn_servers_request = MessagePack::deserialize<bool>(customPackage.data);

                if (msg_vpn_servers.has_value()) {
                    for (const auto& [country, actors] : vpn_servers) {
                        for (const auto& [actor, status] : actors) {
                            vpn_servers[country][actor] = status;
                            emit country_update(country, actor, status.status, status.type);
                        }
                    }
                    return;
                }

                auto msg_country = MessagePack::deserialize<VpnCountryMessage>(customPackage.data);
                if (msg_country.has_value()) {
                    if (msg_country->actor.is_zero() || msg_country->country.empty()) {
                        eCritical(
                            "Invalid VpnCountryMessage: actor is zero or country is empty. Actor: '{}', country: "
                            "'{}'",
                            msg_country->actor,
                            msg_country->country);
                        return;
                        throw("Invalid VpnCountryMessage: actor is zero or country is empty");
                    }

#ifdef Q_OS_WINDOWS
                    // eLog("[Vpn] {}", msg_country.value());
#endif

                    m_node->network()->sendBrodcastMessageFurther(packageData);
                    // vpn_servers[msg_country->country][msg_country->actor] = msg_country->status;
                    // if changed -> emit

                    if (msg_country->actor.is_zero() || msg_country->country.empty()) {
                        eCritical("Invalid VpnCountryMessage: actor is zero or country is empty");
                        throw std::invalid_argument(
                            "Invalid VpnCountryMessage: actor is zero or country is empty");
                    }

                    auto country_it = vpn_servers.lower_bound(msg_country->country);
                    if (country_it == vpn_servers.end() || country_it->first != msg_country->country) {
                        country_it = vpn_servers.insert(country_it, { msg_country->country, {} });
                    }

                    auto& actor_map      = country_it->second;
                    auto  actor_it       = actor_map.find(msg_country->actor);
                    bool  status_changed = actor_it == actor_map.end()
                                          || actor_it->second.status != msg_country->status
                                          || actor_it->second.type != msg_country->type;

                    if (status_changed) {
                        actor_map[msg_country->actor] =
                            VPNStatus { .status = msg_country->status, .type = msg_country->type };
                        emit country_update(msg_country->country,
                                            msg_country->actor,
                                            msg_country->status,
                                            msg_country->type);
                    }

                    // emit country_update(msg_country->country, msg_country->actor, msg_country->status);
                    return;
                }

#ifdef RACCOON_DISABLE_VPN
                return;
#endif

                if (msg_vpn_servers_request.has_value()) {
                    if (current_status) {
                        raccoon::vpn::VPNManager::VPNType type;
                        if (vpnManagerMain) {
                            if (vpnManagerMain->canBeServer()) {
                                type = vpnManagerMain->getVPNType();
                                send_vpn_status(current_status, type);
                            }
                        } else {
                            auto canBeServerWG   = vpnManagerWg->canBeServer();
                            auto canBeServerSing = vpnManagerSing->canBeServer();
                            if (canBeServerWG && canBeServerSing)
                                type = raccoon::vpn::VPNManager::VPNType::BOTH;
                            else if (canBeServerWG)
                                type = raccoon::vpn::VPNManager::VPNType::WIREGUARD;
                            else if (canBeServerSing)
                                type = raccoon::vpn::VPNManager::VPNType::SINGBOX;

                            if (canBeServerWG || canBeServerSing)
                                send_vpn_status(current_status, type);
                        }
                    }
                    // CustomMessage msg;
                    // msg.data = MessagePack::serialize(vpn_servers);
                    // m_node->network()->send_message(msg,
                    //                                 MessageType::Custom,
                    //                                 SendMode::Focused,
                    //                                 MessageStatus::Response,
                    //                                 packageData.msg_body.message_id);
                    return;
                }

                eCritical("[VPN] VPNMessage deserialize error");
                // throw("[VPN] VPNMessage deserialize error");
                return;
            }

            auto              vpnPackage     = vpnPackageExp.value();
            NetworkVPNCommand networkCommand = static_cast<NetworkVPNCommand>(vpnPackage.vpnCommand);
            NetworkVPNType    vpnType        = static_cast<NetworkVPNType>(vpnPackage.vpnType);
            eLog("{}",
                 "[VPN] Achieved " + std::string(magic_enum::enum_name(networkCommand)) + "("
                     + std::string(magic_enum::enum_name(packageData.msg_body.status))
                     + "), VPN type: " + std::string(magic_enum::enum_name(vpnType))
                     + ", messageID: " + packageData.msg_body.message_id
                     + ", init senderID: " + packageData.msg_body.init_sender_id.to_string()
                     + ", senderID: " + packageData.msg_body.sender_id.to_string()
                     + " , identifier: " + packageData.prev_identifier);

            if (packageData.msg_body.status == MessageStatus::Request
                && vpnPackage.initialSender
                       == m_node->accountController()->currentProfile().system().id().to_string()) {
                eLog("[VPN] VPN Package ignored completly!");
                return;
            }

            if (!vpnPackage.lookingForNodeID.empty()
                && vpnPackage.lookingForNodeID != m_node->accountController()->system_actor().id().to_string()) {
                eLog("[VPN] VPN Package ignored: ActorID not contains in lookingForNodeID {} {}",
                     m_node->accountController()->system_actor().id().to_string(),
                     packageData.msg_body.message_id);
                m_node->network()->sendBrodcastMessageFurther(packageData);

                return;
            }
            if (vpnPackage.networkIdentifiersToIgnore.contains(
                    m_node->accountController()->system_actor().id().to_string())) {
                eLog("[VPN] VPN Package ignored: ActorID contains in networkIdentifiersToIgnore {} {}",
                     m_node->accountController()->system_actor().id().to_string(),
                     packageData.msg_body.message_id);
                m_node->network()->sendBrodcastMessageFurther(packageData);
                return;
            }

            switch (networkCommand) {
            case NetworkVPNCommand::HANDSHAKE: {
                if (packageData.msg_body.status == MessageStatus::Request) {
                    // eLog("[VPN] VPN Package send further before processing: {}",
                    // packageData.msg_body.message_id);
                    m_node->network()->sendBrodcastMessageFurther(packageData);
                }
                processHandshake(customPackage, vpnPackage, packageData);
                break;
            }
            case NetworkVPNCommand::CONNECTION: {
                processConnection(vpnPackage, packageData);
                break;
            }
            case NetworkVPNCommand::DISCONNECT: {
                processDisconnect(vpnPackage, packageData);
                break;
            }
            default:
                break;
            }
        }
    } catch (const std::exception& err) {
        eCritical("[VPN] Exception VPNWorkerThread::networkCallbackSlot:  {}", err.what());
        throw err;
    }
}

void VPNConnectorManager::disconnectVPN(const std::string& uuid) {
#ifndef RACCOON_DISABLE_VPN
    if (vpnManagerMain) {
        // bool canBeServerBeforeDelete   = vpnManagerMain->canBeServer();
        auto vpnUuidToVPNWorkersLocked = *m_node->vpnConfigStorage.vpnUuidToVPNWorkers;
        auto res                       = vpnUuidToVPNWorkersLocked->find(uuid);
        if (res != vpnUuidToVPNWorkersLocked->end()) {
            vpnManagerMain->disconnect(res->second.chainIndex);
            vpnUuidToVPNWorkersLocked->erase(res);
            if (!vpnManagerMain->isConnected())
                vpnManagerMain = nullptr;
        }

    #ifdef Q_OS_ANDROID
        auto result = m_singBoxController->stopVpn();
        eLog("VPNConnectorManager::disconnectVPN, VPN stopped result: {}", result);
        if (vpnManagerMain)
            vpnManagerMain->setClientConnected(false);
    #endif

        if (m_node->vpnConfigStorage.vpnUuidToVPNWorkers->empty())
            m_node->vpnConfigStorage.vpnConnectedType = {};

        auto canBeServerWG   = vpnManagerWg->canBeServer();
        auto canBeServerSing = vpnManagerSing->canBeServer();
        if (canBeServerWG || canBeServerSing) {
            eLog("[VPN] Trying to return DFS localization file");

            // TODOCUSTOM: Send country
            raccoon::vpn::VPNManager::VPNType type;
            if (canBeServerWG && canBeServerSing)
                type = raccoon::vpn::VPNManager::VPNType::BOTH;
            else if (canBeServerWG)
                type = raccoon::vpn::VPNManager::VPNType::WIREGUARD;
            else if (canBeServerSing)
                type = raccoon::vpn::VPNManager::VPNType::SINGBOX;

            send_vpn_status(true, type);

            // m_node->vpnConfigStorage.vpnLocalizationFileId =
            //     m_node->dfs()
            //         ->store_file(m_node->accountController()->mainActor().id(),
            //                      m_node->accountController()->mainActor().id(),
            //                      vpnLocalizationFilePath,
            //                      "",
            //                      QFileLog(QString::fromStdString(vpnLocalizationFilePath)).fileName().toStdString(),
            //                      Dfs::DataSecurity::Public)
            //         ->file_id;
        }
    }
#endif
}

bool VPNConnectorManager::checkVPNAvailability(const NetworkVPNType&                   type,
                                               const raccoon::vpn::VPNManager::VPNType vpnType) {
#ifndef RACCOON_DISABLE_VPN

    auto checker = [&](std::shared_ptr<raccoon::vpn::VPNManager> manager) -> bool {
        if (type == NetworkVPNType::PROXY)
            return manager->canBeProxy();
        else if (type == NetworkVPNType::SERVER)
            return manager->canBeServer();
        else if (type == NetworkVPNType::CLIENT)
            return m_node->vpnConfigStorage.vpnIsClient;
        return false;
    };

    if (vpnManagerMain) {
        if (vpnManagerMain->isConnected() && vpnManagerMain->getVPNType() != vpnType)
            return false;

        return checker(vpnManagerMain);
    }

    return checker(vpnType == raccoon::vpn::VPNManager::VPNType::SINGBOX ? vpnManagerSing : vpnManagerWg);
#else
    return false;
#endif
}

bool VPNConnectorManager::checkHandshakeAccess(const std::string& handshakeIdentifier,
                                               const int          handshakeCounter) {
    return CheckVPNHandshakeAccess(handshakeIdentifier, handshakeCounter);
}

bool VPNConnectorManager::setClient(const VPNMessage&                        networkInput,
                                    const ActorId&                           senderId,
                                    const raccoon::vpn::VPNManager::VPNType& vpnType) {
#ifndef RACCOON_DISABLE_VPN
    try {
        eLog("[VPN] SET_CLIENT:  {} {}", networkInput.publicIP, senderId.to_string());

        // QString peerPublicKey = readFile(m_node, senderId, networkInput.publicKeyFile);
        // if (peerPublicKey.isEmpty()) {
        //     eLog("[VPN] PublicKey file is Empty");
        //     return false;
        // }
        eLog("[VPN] VPN PublicKey for client: {}", networkInput.publicKey);
        std::string chainIndexStr = networkInput.resultChainIndex < 10
                                        ? "0" + std::to_string(networkInput.resultChainIndex)
                                        : std::to_string(networkInput.resultChainIndex);

        auto allowedIPsQT = getAllowIPs({ QString::fromStdString(networkInput.publicIP + "/32") });

        if (vpnType == raccoon::vpn::VPNManager::VPNType::WIREGUARD) {
            vpnManagerMain = vpnManagerWg;

    #if !defined(__APPLE__) || (defined(__APPLE__) && !defined(USE_SWIFT))
            // std::list<std::string> allowedIPs;

            // #ifdef __APPLE__
            // bool isApplePlatform = false;
            // for (const QString& qstr : allowedIPsQT) {
            //     allowedIPs.emplace_back(qstr.toStdString());
            // }
            // #else
            // bool isApplePlatform = false;
            // #endif

            raccoon::vpn::VPNManager::Config configuration {
                .interfaceName    = "RACCOON_VPN_" + std::to_string(networkInput.resultChainIndex),
                .interfaceLocalIP = raccoon::IPLocalInterface("100.1" + chainIndexStr + ".0.1"),
                .interfaceDNS     = "1.1.1.1",
                // .postUp           = { "ip rule add sport 22 table main", "ip rule add sport 17593 table main" },
                // .postDown         = { "ip rule del sport 22 table main", "ip rule del sport 17593 table main" },

                // .peerAllowedIPs          = isApplePlatform ? allowedIPs : std::list<std::string>{ "0.0.0.0/0",
                // "::/0" },
                .peer = { { .peerPublicKey           = networkInput.publicKey,
                            .peerAllowedIPs          = { "0.0.0.0/0", "::/0" },
                            .peerEndpoint            = networkInput.publicIP + ":518" + chainIndexStr,
                            .peerPersistentKeepalive = 21 } }
            };

            vpnManagerMain->connectAsClient(configuration);

    #else
            std::string allowedIPs = "AllowedIPs = " + allowedIPsQT.join(", ").toStdString() + "\n";

            std::string config = "[Interface]\n";
            config += "PrivateKey = " + vpnManagerMain->getClientPrivateKey() + "\n";
            config +=
                "Address = " + raccoon::IPLocalInterface("100.1" + chainIndexStr + ".0.1").ToStdString() + "/24\n";
            config += "DNS = 1.1.1.1\n\n";
            config += "[Peer]\n";
            config += "PublicKey = " + networkInput.publicKey + "\n";
            config += allowedIPs;
            config += "Endpoint = " + networkInput.publicIP + ":518" + chainIndexStr + "\n";
            config += "PersistentKeepalive = 21";

            std::string server_address = networkInput.publicIP;

            bool result = false;
            startVPN(config.c_str(), server_address.c_str(), &result);

            eLog("[VPN] Achieved result from start VPN: {}", result);
            vpnManagerMain->setClientConnected(result);

    #endif
        } else {
            vpnManagerMain = vpnManagerSing;
    #ifdef Q_OS_ANDROID
            // std::string interfaceName    = "RACCOON_VPN_" + std::to_string(networkInput.resultChainIndex);
            std::string interfaceLocalIP =
                raccoon::IPLocalInterface("100.1" + chainIndexStr + ".0.1").ToStdString();
            std::string peerPublicKey  = networkInput.publicKey;
            std::string peerShortID    = *networkInput.short_ids.begin();
            std::string peerPublicIP   = networkInput.publicIP;
            int         peerPublicPort = 51800 + networkInput.resultChainIndex;
            std::string uuid           = networkInput.sing_uuid;

            bool success = m_singBoxController->startVpn(interfaceLocalIP,
                                                         peerPublicKey,
                                                         peerShortID,
                                                         peerPublicIP,
                                                         peerPublicPort,
                                                         uuid);
            eLog("[VPN] Achieved result from start VPN: {}", success);
            vpnManagerMain->setClientConnected(success);
    #else
            raccoon::vpn::VPNManager::Config configuration {
                .interfaceName    = "RACCOON_VPN_" + std::to_string(networkInput.resultChainIndex),
                .interfaceLocalIP = raccoon::IPLocalInterface("100.1" + chainIndexStr + ".0.1"),
                .configSingBox    = { .peer { .publicKey = networkInput.publicKey,
                                              .shortIDs  = networkInput.short_ids,
                                              .ip        = networkInput.publicIP,
                                              .port      = 51800 + networkInput.resultChainIndex,
                                              .uuid      = networkInput.sing_uuid } }
            };

            vpnManagerMain->connectAsClient(configuration);

    #endif
        }

        QThread::sleep(2);

        bool is_connected = vpnManagerMain->isConnected();
        if (is_connected)
            eInfo("[VPN] Client is connected.");
        else {
            eCritical("[VPN] VPNConnectorManager::setClient connection failed");
            vpnManagerMain = nullptr;
        }

        return is_connected;
    } catch (const std::exception& err) {
        eCritical("[VPN] VPNConnectorManager::setClient exception: {}", err.what());
        vpnManagerMain = nullptr;
        return false;
    }
#else
    return false;
#endif
}

QString VPNConnectorManager::readFile(const ExtraChainNode* node,
                                      const ActorId&        senderId,
                                      const std::string&    publicKeyFile) {
    auto filePath = node->dfs()->getFileFromStorage(senderId, publicKeyFile);
    eLog("[VPN] file path for key: {}", filePath);

    QFile file(QString::fromStdString(filePath));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        eLog("[VPN] Could not open publicKey file storage: {}", file.errorString());
        return "";
    }

    QTextStream in(&file);
    QString     output = in.readAll();
    file.close();

    return output;
}

std::string VPNConnectorManager::convertIPv4ToIPv6(const QString& ipv4) {
    QHostAddress ipv4Addr(ipv4);
    if (ipv4Addr.protocol() != QAbstractSocket::IPv4Protocol) {
        eWarning("[VPN] Invalid IPv4 address");
        return std::string();
    }

    quint32 ipv4Int    = ipv4Addr.toIPv4Address();
    QString ipv6Mapped = QString("0:0:0:0:0:ffff:%1:%2")
                             .arg((ipv4Int >> 16) & 0xffff, 4, 16, QLatin1Char('0'))
                             .arg(ipv4Int & 0xffff, 4, 16, QLatin1Char('0'));

    return ipv6Mapped.toStdString();
}

bool VPNConnectorManager::setServer(const VPNMessage&                        networkInput,
                                    const ActorId&                           senderId,
                                    const raccoon::vpn::VPNManager::VPNType& vpnType,
                                    raccoon::vpn::VPNManager::ConfigSingBox& configSingOutput) {
#ifndef RACCOON_DISABLE_VPN
    try {
        eLog("[VPN] SET_SERVER:  {} {} {}", networkInput.vpnType, networkInput.localIP, senderId.to_string());

        // QString peerPublicKey = readFile(m_node, senderId, networkInput.publicKeyFile);
        // if (peerPublicKey.isEmpty()) {
        //     eLog("[VPN] VPN PublicKey file is Empty");
        //     return false;
        // }
        eLog("[VPN] VPN PublicKey for server: {}", networkInput.publicKey);

        if (vpnType == raccoon::vpn::VPNManager::VPNType::WIREGUARD)
            vpnManagerMain = vpnManagerWg;
        else
            vpnManagerMain = vpnManagerSing;

        if (static_cast<NetworkVPNType>(networkInput.vpnType) == NetworkVPNType::SERVER) {
            auto mainNetworkInterface = vpnManagerMain->getMainNetworkInterface().toStdString();

            std::list<std::string> tempPeerAllowedIPs;
            for (const auto& it : networkInput.allIPsToSet) {
                tempPeerAllowedIPs.emplace_back(it + "/32");
                auto ipv6 = convertIPv4ToIPv6(QString::fromStdString(it));
                if (!ipv6.empty())
                    tempPeerAllowedIPs.emplace_back(ipv6 + "/128");
            }

            raccoon::vpn::VPNManager::Config configuration {
                .chainIndex          = networkInput.resultChainIndex,
                .interfaceName       = "RACCOON_SERVER",
                .interfaceLocalIP    = raccoon::serverIP,
                .interfaceListenPort = "51900",
                .preUp               = { "sysctl -w net.ipv4.ip_forward=1",
                                         "sysctl -w net.ipv6.conf.all.forwarding=1",
                                         "sysctl -w net.ipv6.conf.all.disable_ipv6=0",
                                         "sysctl -w net.ipv6.conf.default.disable_ipv6=0",
                                         "sysctl -w net.ipv6.conf.lo.disable_ipv6=0" },
                .postUp              = { "ufw route allow in on RACCOON_SERVER out on " + mainNetworkInterface,
                                         "iptables -A FORWARD -i RACCOON_SERVER -o RACCOON_SERVER -m conntrack --ctstate "
                                                      "RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -o "
                                             + mainNetworkInterface + " -j MASQUERADE",
                                         "ip rule show | grep \"sport 22 lookup main\" || sudo ip rule add sport 22 table main"/*,
                                         "ip rule show | grep \"sport 17593 lookup main\" || sudo ip rule add sport 17593 table main"*/ },
                .postDown = { "iptables -D FORWARD -i RACCOON_SERVER -o RACCOON_SERVER -m conntrack --ctstate "
                              "RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -D POSTROUTING -o "
                                  + mainNetworkInterface + " -j MASQUERADE",
                              "ufw route delete allow in on RACCOON_SERVER out on " + mainNetworkInterface/*,
                              "ip rule del sport 22 table main",
                              "ip rule del sport 17593 table main"*/ },
                .peer     = { { .peerPublicKey = networkInput.publicKey, .peerAllowedIPs = tempPeerAllowedIPs } }
            };

            vpnManagerMain->connectAsServer(configuration);

            if (vpnManagerMain->isConnected()) {
                if (vpnType == raccoon::vpn::VPNManager::VPNType::SINGBOX) {
                    auto configSing = vpnManagerMain->getSignBoxConfig(networkInput.resultChainIndex);
                    if (configSing.has_value())
                        configSingOutput = configSing.value();
                    else {
                        eCritical("[VPN] VPNConnectorManager::setServer can't find a config after setup.");
                        vpnManagerMain->disconnect(networkInput.resultChainIndex);
                        vpnManagerMain = nullptr;
                        return false;
                    }
                }

                send_vpn_status(true, vpnManagerMain->getVPNType());

                m_node->dataMiningManager()->set_koef_to_koef(BigNumberFloat("1.75", NumeralBase::Dec));
                eInfo("Exit Point connected: earning higher rewards");
                return true;
            }
        }
        eLog("[VPN] VPN SERVER not connected");
        vpnManagerMain = nullptr;
        return false;
    } catch (const std::exception& err) {
        eCritical("[VPN] VPNConnectorManager::setServer exception: {}", err.what());
        vpnManagerMain = nullptr;
        return false;
    }
#else
    return false;
#endif
}

bool VPNConnectorManager::setProxy(const VPNMessage&                        networkInput,
                                   const ActorId&                           senderId,
                                   const raccoon::vpn::VPNManager::VPNType& vpnType,
                                   raccoon::vpn::VPNManager::ConfigSingBox& configSingOutput) {
#ifndef RACCOON_DISABLE_VPN
    try {
        eLog("[VPN] SET_PROXY:  {} {} {}", networkInput.vpnType, networkInput.localIP, senderId.to_string());

        std::string localIp;
        // QString                nextPublicKey;
        // QString                requesterPublicKey;
        std::string            nextPublicIP;
        std::list<std::string> requesterAllowedIPs;
        bool                   nextServer     = false;
        auto vpnHandhakeCacheInProccessLocked = *m_node->vpnConfigStorage.vpnHandhakeCacheInProccess;
        auto savedIt                          = vpnHandhakeCacheInProccessLocked->begin();
        for (; savedIt != vpnHandhakeCacheInProccessLocked->end(); ++savedIt) {
            if (savedIt->chainIndex == networkInput.resultChainIndex && savedIt->uuid == networkInput.uuid) {
                localIp = savedIt->localIPForSetup;

                // requesterPublicKey =
                //     readFile(m_node, ActorId(savedIt->requesterNodeID), savedIt->requesterPublicKeyFile);
                // if (requesterPublicKey.isEmpty()) {
                //     eLog("[VPN] VPN PublicKey file requester is Empty");
                //     break;
                // }
                eLog("[VPN] VPN PublicKey requester for proxy: {}", savedIt->requesterPublicKey);

                // nextPublicKey = readFile(m_node, senderId, savedIt->nextPublicKeyFile);
                // if (nextPublicKey.isEmpty()) {
                //     eLog("[VPN] VPN PublicKey file next is Empty");
                //     break;
                // }
                eLog("[VPN] VPN PublicKey next for proxy: {}", savedIt->nextPublicKey);

                nextPublicIP = savedIt->nextNodeIP;

                for (const auto& it : savedIt->allIPsToSet) {
                    requesterAllowedIPs.emplace_back(it + "/32");
                    auto ipv6 = convertIPv4ToIPv6(QString::fromStdString(it));
                    if (!ipv6.empty())
                        requesterAllowedIPs.emplace_back(ipv6 + "/128");
                }

                if (savedIt->nextNodeIDType == NetworkVPNType::SERVER)
                    nextServer = true;
                break;
            }
        }

        if (localIp.empty() || savedIt->nextPublicKey.empty() || savedIt->requesterPublicKey.empty()
            || nextPublicIP.empty() || requesterAllowedIPs.empty()) {
            eLog("[VPN] VPN PROXY setup error, some crucial value is EMPTY!");
            return false;
        }

        if (vpnType == raccoon::vpn::VPNManager::VPNType::WIREGUARD)
            vpnManagerMain = vpnManagerWg;
        else
            vpnManagerMain = vpnManagerSing;

        auto        mainNetworkInterface = vpnManagerMain->getMainNetworkInterface().toStdString();
        std::string portPostfix          = networkInput.resultChainIndex < 10
                                               ? "0" + std::to_string(networkInput.resultChainIndex)
                                               : std::to_string(networkInput.resultChainIndex);
        std::string interfaceName        = "RACCOON_PROXY_" + std::to_string(networkInput.resultChainIndex);

        if (vpnType == raccoon::vpn::VPNManager::VPNType::SINGBOX) {
            configSingOutput.peer.ip        = nextPublicIP;
            configSingOutput.peer.port      = (nextServer ? 51900 : 51800 + networkInput.resultChainIndex);
            configSingOutput.peer.uuid      = networkInput.sing_uuid;
            configSingOutput.peer.publicKey = networkInput.publicKey;
            configSingOutput.peer.shortIDs  = networkInput.short_ids;
        }

        raccoon::vpn::VPNManager::Config configuration {
            .chainIndex          = networkInput.resultChainIndex,
            .interfaceName       = interfaceName,
            .interfaceLocalIP    = raccoon::IPLocalInterface(localIp),
            .interfaceListenPort = "518" + portPostfix,
            .interfaceTable      = "518" + portPostfix,
            .preUp               = { "sysctl -w net.ipv4.ip_forward=1",
                                     "sysctl -w net.ipv6.conf.all.forwarding=1",
                                     "sysctl -w net.ipv6.conf.all.disable_ipv6=0",
                                     "sysctl -w net.ipv6.conf.default.disable_ipv6=0",
                                     "sysctl -w net.ipv6.conf.lo.disable_ipv6=0",
                                     "ip rule add iif " + interfaceName + " table 518" + portPostfix + " priority 456" },
            .postUp              = { "ip rule show | grep \"sport 22 lookup main\" || sudo ip rule add sport 22 table main"/*,
                                     "ip rule show | grep \"sport 17593 lookup main\" || sudo ip rule add sport 17593 table main"*/ },
            .postDown = { "ip rule del iif " + interfaceName + " table 518" + portPostfix + " priority 456"/*,
                          "ip rule del sport 22 table main",
                          "ip rule del sport 17593 table main"*/ },
            .peer     = { { .peerPublicKey = savedIt->requesterPublicKey, .peerAllowedIPs = requesterAllowedIPs },
                          { .peerPublicKey           = savedIt->nextPublicKey,
                            .peerAllowedIPs          = { "0.0.0.0/0", "::/0" },
                            .peerEndpoint            = nextPublicIP + (nextServer ? ":51900" : ":518" + portPostfix),
                            .peerPersistentKeepalive = 21 } },
            .configSingBox = configSingOutput
        };

        bool                              canBeServerBeforeInit = false;
        raccoon::vpn::VPNManager::VPNType typeBeforeInit;
        auto                              canBeServerWG   = vpnManagerWg->canBeServer();
        auto                              canBeServerSing = vpnManagerSing->canBeServer();
        if (canBeServerWG && canBeServerSing) {
            typeBeforeInit        = raccoon::vpn::VPNManager::VPNType::BOTH;
            canBeServerBeforeInit = true;
        } else if (canBeServerWG) {
            typeBeforeInit        = raccoon::vpn::VPNManager::VPNType::WIREGUARD;
            canBeServerBeforeInit = true;
        } else if (canBeServerSing) {
            typeBeforeInit        = raccoon::vpn::VPNManager::VPNType::SINGBOX;
            canBeServerBeforeInit = true;
        }
        vpnManagerMain->connectAsProxy(configuration);

        if (vpnManagerMain->isConnected()) {
            if (vpnType == raccoon::vpn::VPNManager::VPNType::SINGBOX) {
                auto configSing = vpnManagerMain->getSignBoxConfig(networkInput.resultChainIndex);
                if (configSing.has_value())
                    configSingOutput = configSing.value();
                else {
                    eCritical("[VPN] VPNConnectorManager::setServer can't find a config after setup.");
                    vpnManagerMain->disconnect(networkInput.resultChainIndex);
                    vpnManagerMain = nullptr;
                    return false;
                }
            }

            m_node->dataMiningManager()->set_koef_to_koef(BigNumberFloat("1.25", NumeralBase::Dec));
            eInfo("Proxy connected: earning rewards");
            vpnHandhakeCacheInProccessLocked->erase(savedIt);
            if (canBeServerBeforeInit) {
                // delete VPN localization file
                send_vpn_status(false, typeBeforeInit);
                if (!m_node->vpnConfigStorage.vpnLocalizationFileId.empty()) {
                    // if (m_node->dfs()->remove_stored_file(m_node->accountController()->mainActor().id(),
                    // m_node->vpnConfigStorage.vpnLocalizationFileId)) {
                    // TODOCUSTOM: Send Remove
                    eLog("[VPN] DFS localization VPN file deleted");
                    m_node->vpnConfigStorage.vpnLocalizationFileId.clear();
                    // }
                }
            }
            return true;
        } else
            eLog("[VPN] VPN PROXY not connected");
        vpnManagerMain = nullptr;
        return false;
    } catch (const std::exception& err) {
        eCritical("[VPN] VPNConnectorManager::setProxy exception: {}", err.what());
        vpnManagerMain = nullptr;
        return false;
    }
#else
    return false;
#endif
}

void VPNConnectorManager::shutdownAllSlot() {
#ifndef RACCOON_DISABLE_VPN
    #ifdef Q_OS_ANDROID
    bool result = m_singBoxController->stopVpn();
    qDebug() << "VPN disconnection result:" << result;
    if (vpnManagerMain)
        vpnManagerMain->setClientConnected(false);
    #elif !defined(__APPLE__) || (defined(__APPLE__) && !defined(USE_SWIFT))
    if (vpnManagerMain)
        vpnManagerMain->disconnect();
    #else
    stopVPN();
    if (vpnManagerMain)
        vpnManagerMain->setClientConnected(false);
    #endif

    if (m_shutdownAllSlotCallback) {
        m_shutdownAllSlotCallback(false);
    }
    vpnManagerMain = nullptr;
#endif
}

void VPNConnectorManager::setVPNServerPermission(raccoon::vpn::VPNManager::VPNPermission vpn_permission) {
    vpnManagerWg->setVPNServerPermission(vpn_permission);
    vpnManagerSing->setVPNServerPermission(vpn_permission);
}

void VPNConnectorManager::sendDisconnect(const std::string& uuid,
                                         const std::string& nextNodeID,
                                         const std::string& nextNodeNetworkIdentifier) {
    VPNMessage outputMsg;
    outputMsg.initialSender    = m_node->accountController()->currentProfile().system().id().to_string();
    outputMsg.vpnCommand       = static_cast<int>(NetworkVPNCommand::DISCONNECT);
    outputMsg.uuid             = uuid;
    outputMsg.lookingForNodeID = nextNodeID;

    // QString identifierToSend;
    // {
    //     auto networkConnections = *m_node->network()->connections();
    //     for (auto itNetwork = networkConnections->begin(); itNetwork != networkConnections->end(); ++itNetwork)
    //     {
    //         if ((*itNetwork)->ip().toStdString() == nextNodeIP) {
    //             identifierToSend = (*itNetwork)->identifier();
    //             break;
    //         }
    //     }
    // }
    if (!nextNodeNetworkIdentifier.empty()) {
        CustomMessage customMessage;
        customMessage.data = MessagePack::serialize(outputMsg);

        Responder responder(m_node->network());
        responder.add_identifier(nextNodeNetworkIdentifier);
        auto sendedMessageID = m_node->network()->send_message(customMessage,
                                                               MessageType::Custom,
                                                               SendMode::Focused,
                                                               MessageStatus::Request,
                                                               responder);

        eLog("[VPN] VPNDisconnect sended, messageID: {}", sendedMessageID);
        m_node->dataMiningManager()->set_koef_to_koef(BigNumberFloat(1));
        eInfo("VPN disconnected: standard rewards only");
    } else
        eLog("[VPN] VPNDisconnect send fail: empty identifier.");
}

void VPNConnectorManager::setConstantSocketByIdentifier(const std::string& identifier,
                                                        const bool         isConstant,
                                                        const bool         isVPN) {
    auto networkConnections = *m_node->network()->connections();
    for (auto itNetwork = networkConnections->begin(); itNetwork != networkConnections->end(); ++itNetwork) {
        if ((*itNetwork)->identifier().toStdString() == identifier) {
            (*itNetwork)->set_constant(isConstant);
            (*itNetwork)->set_vpn(isVPN);
            break;
        }
    }
}

QList<QString> VPNConnectorManager::calcIPRange(const QList<IPNetwork>& allowed_networking,
                                                const QList<IPNetwork>& disallowed_networking) {
    QList<IPNetwork> addr;
    // Проходим по всем разрешённым сетям
    for (const IPNetwork& i : allowed_networking) {
        int count = 0;
        for (const IPNetwork& j : disallowed_networking) {
            // Если disallowed входит в allowed
            if (i.contains(j)) {
                QList<IPNetwork> excluded = i.addressExclude(j);
                for (const IPNetwork& allowedip : excluded)
                    addr.append(allowedip);
                count++;
            }
        }
        if (count == 0)
            addr.append(i);
    }
    // Удаляем те сети, в которых присутствует какой-либо disallowed
    QList<IPNetwork> filtered;
    for (const IPNetwork& res : addr) {
        bool skip = false;
        for (const IPNetwork& dis : disallowed_networking) {
            if (res.contains(dis)) {
                skip = true;
                break;
            }
        }
        if (!skip)
            filtered.append(res);
    }
    QList<QString> output;
    for (const IPNetwork& net : filtered)
        output.append(net.toString());
    return output;
}

QList<QString> VPNConnectorManager::getAllowIPs(QStringList disallowIPRaw) {
    static const QStringList allowIPRaw = { "0.0.0.0/0", "::/0" };

    QList<IPNetwork> allowedIPv4;
    QList<IPNetwork> allowedIPv6;
    QList<IPNetwork> disallowedIPv4;
    QList<IPNetwork> disallowedIPv6;

    for (const QString& ipa : allowIPRaw) {
        int       type = IPNetwork::checkIPNetworkType(ipa);
        IPNetwork net  = IPNetwork::fromString(ipa);
        if (type == 4)
            allowedIPv4.append(net);
        else if (type == 6)
            allowedIPv6.append(net);
    }
    for (const QString& ipd : disallowIPRaw) {
        int       type = IPNetwork::checkIPNetworkType(ipd);
        IPNetwork net  = IPNetwork::fromString(ipd);
        if (type == 4)
            disallowedIPv4.append(net);
        else if (type == 6)
            disallowedIPv6.append(net);
    }

    QList<QString> result = calcIPRange(allowedIPv4, disallowedIPv4) + calcIPRange(allowedIPv6, disallowedIPv6);

    QList<QString> output;
    for (const QString& s : result) {
        if (!output.contains(s)) {
            if (s == "0000:0000:0000:0000:0000:0000:0000:0000/0") {
                if (!output.contains("::/0"))
                    output.append("::/0");
            } else
                output.append(s);
        }
    }
    return output;
}
