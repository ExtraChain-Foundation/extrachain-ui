#include "VpnConnectionChainList.h"

VpnConnectionChainList::VpnConnectionChainList(QObject *parent)
    : QAbstractItemModel(parent) {
    _roles[Ip]          = "ip";
    _roles[CountryName] = "countryName";
}

QModelIndex VpnConnectionChainList::index(int row, int column, const QModelIndex &parent) const {
    return hasIndex(row, column, parent) ? createIndex(row, column) : QModelIndex();
}

QModelIndex VpnConnectionChainList::parent(const QModelIndex &child) const {
    Q_UNUSED(child)
    return QModelIndex();
}

int VpnConnectionChainList::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : _chains.size();
}

int VpnConnectionChainList::columnCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : 1;
}

QVariant VpnConnectionChainList::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.column() != 0 || index.row() < 0 || index.row() >= _chains.size())
        return QVariant();

    const auto chainItem = _chains[index.row()];
    switch (role) {
    case Ip:
        return chainItem.ip;
    case CountryName:
        return chainItem.countryName;
    }
    return QVariant();
}

QHash<int, QByteArray> VpnConnectionChainList::roleNames() const {
    return _roles;
}

void VpnConnectionChainList::addChainItem(const QString &country, const QString &ip) {
    beginInsertRows(QModelIndex(), _chains.size(), _chains.size());
    _chains.push_back(ChainItem(country, ip));
    endInsertRows();
}

void VpnConnectionChainList::updateChainItem(const int index, const QString &country, const QString &ip) {
    auto chainItem             = ChainItem(country, ip);
    _chains[index].countryName = country;
    _chains[index].ip          = ip;
    auto l                     = createIndex(index, 0);
    emit dataChanged(l, l);
}

void VpnConnectionChainList::removeLastChainItem() {
    beginRemoveRows(QModelIndex(), _chains.size() - 1, _chains.size() - 1);
    _chains.removeLast();
    endRemoveRows();
}

void VpnConnectionChainList::removeToOne() {
    while (_chains.size() != 1) {
        removeLastChainItem();
    }
}
