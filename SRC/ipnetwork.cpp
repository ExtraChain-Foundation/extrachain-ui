#include "ipnetwork.h"

IPNetwork IPNetwork::fromString(const QString &str) {
    IPNetwork   net;
    QStringList parts = str.split("/");
    if (parts.size() != 2) {
        net.prefix = -1;
        return net;
    }
    QString addrStr = parts[0].trimmed();
    bool    ok;
    int     pref = parts[1].toInt(&ok);
    if (!ok) {
        net.prefix = -1;
        return net;
    }
    net.prefix = pref;
    QHostAddress addr(addrStr);
    if (addr.protocol() == QAbstractSocket::IPv4Protocol) {
        net.isIPv4 = true;
        net.ipv4   = addr.toIPv4Address();
    } else if (addr.protocol() == QAbstractSocket::IPv6Protocol) {
        net.isIPv4 = false;
        net.ipv6   = ipv6ToInt(addrStr);
    }
    return net;
}

int IPNetwork::checkIPNetworkType(const QString &address) {
    IPNetwork net = IPNetwork::fromString(address);
    if (net.prefix == -1)
        return 10;
    return net.isIPv4 ? 4 : 6;
}

uint128_t IPNetwork::start() const {
    if (isIPv4) {
        int     bits = 32;
        quint32 mask = (prefix == 0 ? 0 : 0xFFFFFFFF << (bits - prefix));
        return static_cast<uint128_t>(ipv4 & mask);
    } else {
        int       bits = 128;
        uint128_t mask = (prefix == 0 ? 0 : ~(((uint128_t)1 << (bits - prefix)) - 1));
        return ipv6 & mask;
    }
}

uint128_t IPNetwork::end() const {
    if (isIPv4) {
        int     bits      = 32;
        quint32 mask      = (prefix == 0 ? 0 : 0xFFFFFFFF << (bits - prefix));
        quint32 startAddr = ipv4 & mask;
        quint32 endAddr   = startAddr | (~mask);
        return static_cast<uint128_t>(endAddr);
    } else {
        int       bits      = 128;
        uint128_t mask      = (prefix == 0 ? 0 : ~(((uint128_t)1 << (bits - prefix)) - 1));
        uint128_t startAddr = ipv6 & mask;
        uint128_t endAddr   = startAddr | (~mask);
        return endAddr;
    }
}

bool IPNetwork::contains(const IPNetwork &other) const {
    if (isIPv4 != other.isIPv4)
        return false;
    uint128_t s1 = start();
    uint128_t e1 = end();
    uint128_t s2 = other.start();
    uint128_t e2 = other.end();
    return (s2 >= s1 && e2 <= e1);
}

bool IPNetwork::operator==(const IPNetwork &other) const {
    return (isIPv4 == other.isIPv4 && prefix == other.prefix
            && (isIPv4 ? (ipv4 == other.ipv4) : (ipv6 == other.ipv6)));
}

QList<IPNetwork> IPNetwork::addressExclude(const IPNetwork &other) const {
    QList<IPNetwork> result;
    if (other.isIPv4 != isIPv4 || !this->contains(other))
        return QList<IPNetwork>() << *this;
    if (this->start() == other.start() && this->end() == other.end())
        return result;
    uint128_t s  = start();
    uint128_t e  = end();
    uint128_t os = other.start();
    uint128_t oe = other.end();
    if (os > s) {
        QList<IPNetwork> left = cidrFromRange(s, os - 1, isIPv4);
        for (const IPNetwork &n : left)
            result.append(n);
    }
    if (oe < e) {
        QList<IPNetwork> right = cidrFromRange(oe + 1, e, isIPv4);
        for (const IPNetwork &n : right)
            result.append(n);
    }
    return result;
}

QString IPNetwork::toString() const {
    if (isIPv4) {
        QHostAddress addr(ipv4);
        return QString("%1/%2").arg(addr.toString()).arg(prefix);
    } else {
        return QString("%1/%2").arg(intToIPv6(ipv6)).arg(prefix);
    }
}

QString IPNetwork::intToIPv6(uint128_t addr) const {
    QStringList groups;
    for (int i = 0; i < 8; i++) {
        int     shift = (7 - i) * 16;
        quint16 group = (quint16)((addr >> shift) & 0xFFFF);
        groups << QString("%1").arg(group, 4, 16, QChar('0'));
    }
    return groups.join(":");
}

uint128_t IPNetwork::ipv6ToInt(const QString &address) {
    QString     addr  = address;
    QStringList parts = addr.split("::");
    QStringList hextets;
    if (parts.size() == 1) {
        hextets = parts[0].split(":");
    } else {
        QStringList left    = parts[0].isEmpty() ? QStringList() : parts[0].split(":");
        QStringList right   = parts[1].isEmpty() ? QStringList() : parts[1].split(":");
        int         missing = 8 - (left.size() + right.size());
        hextets             = left;
        for (int i = 0; i < missing; i++) {
            hextets << "0";
        }
        hextets.append(right);
    }
    assert(hextets.size() == 8);
    uint128_t result = 0;
    for (const QString &part : hextets) {
        bool    ok;
        quint16 value = part.toUShort(&ok, 16);
        result        = (result << 16) | value;
    }
    return result;
}

int IPNetwork::trailingZeros(uint128_t x, int bits) const {
    int count = 0;
    for (int i = 0; i < bits; i++) {
        if ((x >> i) & 1)
            break;
        count++;
    }
    return count;
}

QList<IPNetwork> IPNetwork::cidrFromRange(uint128_t start, uint128_t end, bool isIPv4) const {
    QList<IPNetwork> result;
    int              totalBits = isIPv4 ? 32 : 128;
    while (start <= end) {
        int tz = trailingZeros(start, totalBits);

        uint128_t maxBlock = ((uint128_t)1 << tz);

        uint128_t remaining = end - start + 1;
        int       p         = 0;
        while (((uint128_t)1 << (p + 1)) <= remaining && (p + 1) <= totalBits)
            p++;

        int       shift     = std::min(tz, p);
        uint128_t blockSize = ((uint128_t)1 << shift);
        int       prefix    = totalBits - shift;
        IPNetwork net;
        net.isIPv4 = isIPv4;
        net.prefix = prefix;
        if (isIPv4) {
            net.ipv4 = static_cast<quint32>(start);
        } else {
            net.ipv6 = start;
        }
        result.append(net);
        start += blockSize;
    }
    return result;
}
