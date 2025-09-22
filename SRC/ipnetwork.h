#ifndef IPNETWORK_H
#define IPNETWORK_H

#include <QCoreApplication>
#include <QString>
#include <QStringList>
#include <QList>
#include <QDebug>
#include <QHostAddress>
#include <QtGlobal>
#include <cassert>

#include <boost/multiprecision/cpp_int.hpp>

using uint128_t = boost::multiprecision::uint128_t;

class IPNetwork {
public:
    bool      isIPv4;
    quint32   ipv4;
    uint128_t ipv6;
    int       prefix;

    IPNetwork()
        : isIPv4(true)
        , ipv4(0)
        , ipv6(0)
        , prefix(0) {
    }

    static IPNetwork fromString(const QString &str);
    static int       checkIPNetworkType(const QString &address);

    bool contains(const IPNetwork &other) const;
    bool operator==(const IPNetwork &other) const;

    QList<IPNetwork> addressExclude(const IPNetwork &other) const;
    QString          toString() const;

private:
    uint128_t start() const;
    uint128_t end() const;

    QString          intToIPv6(uint128_t addr) const;
    static uint128_t ipv6ToInt(const QString &address);
    int              trailingZeros(uint128_t x, int bits) const;

    QList<IPNetwork> cidrFromRange(uint128_t start, uint128_t end, bool isIPv4) const;
};

#endif // IPNETWORK_H
