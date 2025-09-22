#ifndef VPN_CONNECTOR_MANAGER_H
#define VPN_CONNECTOR_MANAGER_H

#include <atomic>

#include <QObject>
#include <QThread>
#include <QTimer>

#include "network/message_body.h"
#ifndef RACCOON_DISABLE_VPN
    #include "vpnmanager.h"
#endif
#include "utils/vpn_types.h"

#include "ipnetwork.h"

#ifdef Q_OS_ANDROID
    #include "SRC/platforms/android/singboxcontroller.h"
#endif

class VPNMessage;
class ActorId;
class ExtraChainNode;

class VPNWorkerThread;
class VPNConnectorManager;

enum class NetworkVPNCommand {
    HANDSHAKE,
    CONNECTION,
    DISCONNECT
};

enum class NetworkVPNType {
    CLIENT,
    SERVER,
    PROXY
};

struct VpnCountryMessage {
    ActorId                           actor;
    std::string                       country;
    bool                              status;
    raccoon::vpn::VPNManager::VPNType type;
};
BOOST_DESCRIBE_STRUCT(VpnCountryMessage, (), (actor, country, status, type))

struct VpnCountry {
    ActorId actor;
    bool    status;
};
BOOST_DESCRIBE_STRUCT(VpnCountry, (), (actor, status))

struct VPNStatus {
    bool status;
    raccoon::vpn::VPNManager::VPNType type;
};
BOOST_DESCRIBE_STRUCT(VPNStatus, (), (status, type))

using VpnServers = std::map<std::string, std::map<ActorId, VPNStatus>>;

static VPNConnectorManager* g_vpnConnectorManagerInstance = nullptr;

class EXTRACHAIN_EXPORT VPNConnectorManagerWrapper : public QObject {
    Q_OBJECT

public:
    VPNConnectorManagerWrapper(ExtraChainNode* node, QObject* parent);

    ~VPNConnectorManagerWrapper();

    VPNConnectorManager* vpnConnectorManager;

private:
    QThread* m_thread = nullptr;
};

class VPNConnectorManager : public QObject {
    Q_OBJECT

public:
    ~VPNConnectorManager();

    bool CheckVPNHandshakeAccess(const std::string& requesterIdentifier, const int counter);

    void networkCallback(VPNMessage& networkInput, MessageType& type);

    void setVPNServerPermission(raccoon::vpn::VPNManager::VPNPermission vpn_permission);

    void sendDisconnect(const std::string& uuid,
                        const std::string& nextNodeID,
                        const std::string& nextNodeNetworkIdentifier);

    void ClearSavedCacheBeforeNextHandshake();

    void send_vpn_status(bool status, raccoon::vpn::VPNManager::VPNType type, const std::string& identifier = "");

    void setShutdownAllSlotCallback(std::function<void(bool)> callback);

    std::string vpnLocalizationFilePath;
    // QString     vpnFileLocalPath;

#ifndef RACCOON_DISABLE_VPN
    std::shared_ptr<raccoon::vpn::VPNManager> vpnManagerMain;
    std::shared_ptr<raccoon::vpn::VPNManager> vpnManagerWg;
    std::shared_ptr<raccoon::vpn::VPNManager> vpnManagerSing;
#endif

    ExtraChainNode* node() {
        return this->m_node;
    }

    SafePtr<std::set<std::string>> tryingConnectionAllSenders;

signals:
    void shutdownAll();
    void country_update(
        std::string                             country,
        ActorId                                 vpn_actor,
        bool                                    status,
        const raccoon::vpn::VPNManager::VPNType type = raccoon::vpn::VPNManager::VPNType::WIREGUARD);
    void disconnectVpn();
    void closeApp();

public slots:
    void send_vpns_request();

private slots:
    void networkCallbackSlot(const NetworkPackageStorage packageData, const CustomMessage customPackage);
    void shutdownAllSlot();

private:
    explicit VPNConnectorManager(ExtraChainNode* node);
    void Init();
    void disconnectVPN(const std::string& uuid);
    bool checkVPNAvailability(const NetworkVPNType& type, const raccoon::vpn::VPNManager::VPNType vpnType);
    bool checkHandshakeAccess(const std::string& handshakeIdentifier, const int handshakeCounter);
    bool setClient(const VPNMessage&                        networkInput,
                   const ActorId&                           senderId,
                   const raccoon::vpn::VPNManager::VPNType& vpnType);
    bool setServer(const VPNMessage&                        networkInput,
                   const ActorId&                           senderId,
                   const raccoon::vpn::VPNManager::VPNType& vpnType,
                   raccoon::vpn::VPNManager::ConfigSingBox& configSingOutput);
    bool setProxy(const VPNMessage&                        networkInput,
                  const ActorId&                           senderId,
                  const raccoon::vpn::VPNManager::VPNType& vpnType,
                  raccoon::vpn::VPNManager::ConfigSingBox& configSingOutput);
    void setConstantSocketByIdentifier(const std::string& identifier, const bool isConstant, const bool isVPN);
    void clearSockets();

    void processHandshake(const CustomMessage&         customPackage,
                          const VPNMessage&            networkInput,
                          const NetworkPackageStorage& packageData);
    void processConnection(const VPNMessage& networkInput, const NetworkPackageStorage& packageData);
    void processDisconnect(const VPNMessage& networkInput, const NetworkPackageStorage& packageData);

    QString     readFile(const ExtraChainNode* node, const ActorId& senderId, const std::string& publicKeyFile);
    std::string convertIPv4ToIPv6(const QString& ipv4);

    QList<QString> calcIPRange(const QList<IPNetwork>& allowed_networking,
                               const QList<IPNetwork>& disallowed_networking);
    QList<QString> getAllowIPs(QStringList disallowIPRaw);

    std::unique_ptr<VPNWorkerThread> m_workerThread;
    QThread*                         m_thread;
    ExtraChainNode*                  m_node;
    SafePtr<std::unordered_map<std::string, std::function<void(const std::string& identifierToSend)>>>
                                      m_waitNewSocketCommandStorage;
    QTimer*                           m_clearSocketsTimer;
    std::atomic_bool                  m_tryingConnection;
    SafePtr<std::map<int, QDateTime>> m_indexes_handshake_can_be_blocked;

    std::function<void(bool)> m_shutdownAllSlotCallback = nullptr;

    // Country, vector(ActorId, is_active)
    VpnServers vpn_servers;
    bool       current_status = false;
    raccoon::vpn::VPNManager::VPNType       current_type;


#ifdef Q_OS_ANDROID
    SingBoxController* m_singBoxController;
#endif

    friend VPNWorkerThread;
    friend class VPNConnectorManagerWrapper;
};

class VPNWorkerThread : public QThread {
    Q_OBJECT

public:
    VPNWorkerThread(VPNConnectorManager* vpnConnectorManager, ExtraChainNode* node, QObject* parent = nullptr);

    void run() override;
    void stop();

private:
    VPNConnectorManager* m_vpnConnectorManager;
    ExtraChainNode*      m_node;
    std::atomic_bool     m_running;
};

#endif // VPN_CONNECTOR_MANAGER_H
