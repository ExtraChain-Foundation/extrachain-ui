#pragma once

/*
#include <QAbstractItemModel>
#include <managers/extrachain_node.h>
#include "WalletListView.h"

class TransactionModel : public QAbstractItemModel {
    Q_OBJECT

    QString                                     _currentWallet;
    std::list<BalanceDataInfo::BalanceDataItem> listOfTrx;
    QHash<int, QByteArray>                      _roles;
    enum TxRoles {
        Wallet,
        Date,
        Amount,
        Participant,
        IsDeposit,
        Token
    };
    QMap<QString, QString> tokensMap;

public:
    explicit TransactionModel(QObject *parent = nullptr);

    virtual QModelIndex            index(int row, int column, const QModelIndex &parent) const override;
    virtual QModelIndex            parent(const QModelIndex &child) const override;
    virtual int                    rowCount(const QModelIndex &parent) const override;
    virtual int                    columnCount(const QModelIndex &parent) const override;
    virtual QVariant               data(const QModelIndex &index, int role) const override;
    virtual QHash<int, QByteArray> roleNames() const override;

    void setCurrentWallet(const QString &currentWallet);
    void fillModel(const BalanceDataInfo &bdi);
    void update();
    void appendTx(const Transaction &tx, const std::uint64_t &date);

public slots:
    bool isEmpty() const;
};
*/
