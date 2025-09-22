#include <iostream>
#include <fstream>
#include <string>
#include <cstring>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <net/if.h>
#include <linux/sockios.h>
#include <linux/if_link.h>
#include <expected>

enum class InterfaceError {
    SocketCreationFailed,
    GetFlagsFailed,
    GetMtuFailed,
    StatsReadFailed,
    InterfaceNotFound
};

struct InterfaceStats {
    std::string name;
    bool        isUp;
    bool        isPointToPoint;
    bool        hasArp;
    bool        isRunning;
    int         mtu;

    uint64_t rxBytes;
    uint64_t rxPackets;
    uint64_t rxErrors;
    uint64_t rxDropped;
    uint64_t rxMissed;
    uint64_t rxMulticast;

    uint64_t txBytes;
    uint64_t txPackets;
    uint64_t txErrors;
    uint64_t txDropped;
    uint64_t txCarrier;
    uint64_t txCollisions;
};

std::expected<InterfaceStats, InterfaceError> getInterfaceStats(const std::string& ifname) {
    InterfaceStats stats { .name           = ifname,
                           .isUp           = false,
                           .isPointToPoint = false,
                           .hasArp         = true,
                           .isRunning      = false,
                           .mtu            = 0,
                           .rxBytes        = 0,
                           .rxPackets      = 0,
                           .rxErrors       = 0,
                           .rxDropped      = 0,
                           .rxMissed       = 0,
                           .rxMulticast    = 0,
                           .txBytes        = 0,
                           .txPackets      = 0,
                           .txErrors       = 0,
                           .txDropped      = 0,
                           .txCarrier      = 0,
                           .txCollisions   = 0 };

    std::string ifpath = "/sys/class/net/" + ifname;
    if (!std::ifstream(ifpath)) {
        return std::unexpected(InterfaceError::InterfaceNotFound);
    }

    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        return std::unexpected(InterfaceError::SocketCreationFailed);
    }

    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, ifname.c_str(), IFNAMSIZ - 1);

    if (ioctl(sock, SIOCGIFFLAGS, &ifr) < 0) {
        close(sock);
        return std::unexpected(InterfaceError::GetFlagsFailed);
    }

    stats.isUp           = (ifr.ifr_flags & IFF_UP);
    stats.isPointToPoint = (ifr.ifr_flags & IFF_POINTOPOINT);
    stats.hasArp         = !(ifr.ifr_flags & IFF_NOARP);
    stats.isRunning      = (ifr.ifr_flags & IFF_RUNNING);

    if (ioctl(sock, SIOCGIFMTU, &ifr) < 0) {
        close(sock);
        return std::unexpected(InterfaceError::GetMtuFailed);
    }

    stats.mtu = ifr.ifr_mtu;
    close(sock);

    std::string path = "/sys/class/net/" + ifname + "/statistics/";

    auto readStatFile = [&path](const std::string& filename, uint64_t& value) {
        std::ifstream file(path + filename);
        if (file) {
            file >> value;
            return true;
        }
        return false;
    };

    bool readSuccess = true;
    readSuccess &= readStatFile("rx_bytes", stats.rxBytes);
    readSuccess &= readStatFile("tx_bytes", stats.txBytes);
    readSuccess &= readStatFile("rx_packets", stats.rxPackets);
    readSuccess &= readStatFile("tx_packets", stats.txPackets);
    readSuccess &= readStatFile("rx_errors", stats.rxErrors);
    readSuccess &= readStatFile("tx_errors", stats.txErrors);
    readSuccess &= readStatFile("rx_dropped", stats.rxDropped);
    readSuccess &= readStatFile("tx_dropped", stats.txDropped);
    readSuccess &= readStatFile("multicast", stats.rxMulticast);
    readSuccess &= readStatFile("collisions", stats.txCollisions);

    if (!readSuccess) {
        return std::unexpected(InterfaceError::StatsReadFailed);
    }

    return stats;
}
