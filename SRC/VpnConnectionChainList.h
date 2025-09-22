#pragma once

#include <QObject>
#include <QAbstractItemModel>

class ChainItem;
struct ChainItem {
    QString countryName, ip;
    ChainItem() {
    }
    ChainItem(QString countryName, QString ip)
        : countryName(countryName)
        , ip(ip) {
    }
};

class VpnConnectionChainList : public QAbstractItemModel {
    Q_OBJECT

public:
    explicit VpnConnectionChainList(QObject *parent = nullptr);

    virtual QModelIndex            index(int row, int column, const QModelIndex &parent) const override;
    virtual QModelIndex            parent(const QModelIndex &child) const override;
    virtual int                    rowCount(const QModelIndex &parent) const override;
    virtual int                    columnCount(const QModelIndex &parent) const override;
    virtual QVariant               data(const QModelIndex &index, int role) const override;
    virtual QHash<int, QByteArray> roleNames() const override;
    void                           addChainItem(const QString &country, const QString &ip);
    void                           updateChainItem(const int index, const QString &country, const QString &ip);
    void                           removeLastChainItem();
    void                           removeToOne();

private:
    enum PostRoles {
        Ip,
        CountryName
    };
    QVector<ChainItem>     _chains;
    QHash<int, QByteArray> _roles;
};
