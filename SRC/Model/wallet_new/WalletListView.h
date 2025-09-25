#pragma once

/*
#include <QAbstractItemModel>
#include "managers/extrachain_node.h"
#include <QClipboard>
#include <QGuiApplication>

constexpr float raccoon_coin_price = 0.48;

struct BalanceDataInfo {
    struct BalanceDataItem {
        long long              date;
        BigNumberFloat         balanceChange;
        ActorId                participant;
        ActorId                token;
        QMap<QString, QString> tokensMap;
        QString                rocc_token_id;
        bool                   forRoccEnv = false;

        BalanceDataItem();
        BalanceDataItem(const ActorId& actorId, const Transaction& tx, const long long& dateTx);
        void fromTx(const ActorId& actorId, const Transaction& tx, const long long& dateTx);
    };

    BalanceDataInfo() = default;
    BalanceDataInfo(const ActorId& actor, const std::string& wn);

    ActorId                    actor;
    std::string                walletName   = actor.to_string();
    BigNumberFloat             totalBalance = BigNumberFloat(0);
    std::list<BalanceDataItem> listBalanceDataItem;
    void                       add(const BalanceDataItem& balanceDataItem);
    int                        size() const;
    float                      price = raccoon_coin_price;
};

class WalletListView : public QAbstractItemModel {
    Q_OBJECT
    QVector<BalanceDataInfo> balanceDataInfoList;
    QHash<int, QByteArray>   _roles;
    BigNumberFloat           _walletTotalBalance;
    BigNumberFloat           _balanceFromZeroBlock;
    std::set<std::string>    trxHashes;
    enum WalletRoles {
        WalletId,
        WalletName,
        Balance,
        Price,
        DailyBalanceChange,
        Value
    };

    Q_PROPERTY(QString totalBalance READ totalBalance WRITE setTotalBalance NOTIFY totalBalanceChanged)

public:
    explicit WalletListView(QObject* parent = nullptr);
    virtual QModelIndex            index(int row, int column, const QModelIndex& parent) const override;
    virtual QModelIndex            parent(const QModelIndex& child) const override;
    virtual int                    rowCount(const QModelIndex& parent) const override;
    virtual int                    columnCount(const QModelIndex& parent) const override;
    virtual QVariant               data(const QModelIndex& index, int role) const override;
    virtual QHash<int, QByteArray> roleNames() const override;

    void            setBalanceData(const QVector<BalanceDataInfo>& list, QVariantMap balances);
    BalanceDataInfo getBalanceDataByIndex(const int& index);
    void            renameWallet(const int index, const QString& newWalletName);
    void            addWallet(const BalanceDataInfo& bdi);
    QString         totalBalance() const;
    void            setTotalBalance(const QString& newTotalBalance);
    void            updateBlock(const Block& block);
    void            updateWallet(const ActorId& wallet);
    void            addStateFromZeroBlock(const ActorId& id, const BigNumberFloat& state);
    void            updateBalances(QVariantMap map);
    void            updateWallets(QVariantList list);

public slots:
    void         copyWalletAddress(const QString& text);
    QVariantList wallets();
    void         updateTotalBalance();

signals:
    void totalBalanceChanged();
    void cacheTransaction(const Transaction& tx, std::uint64_t& date);
    void showMessage(const QString& message);
    void requestUpdateBalance();

protected:
    QString calcValue(const BigNumberFloat& balance, const float& price = raccoon_coin_price) const;

private:
    QString      _totalBalance;
    QVariantList _wallets;
    QVariantMap  _mapBalances;
};
*/
