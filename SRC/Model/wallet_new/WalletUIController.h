#pragma once

#include <QObject>
#include "managers/extrachain_node.h"
#include "managers/account_controller.h"
#include "chain/dag.h"
#include "utils/variant_model.h"
#include "utils/db_connector.h"

class WalletUIController : public QObject {
    Q_OBJECT

    // WalletListView                    *walletListView;
    // TransactionModel                  *transactionModel;
    ExtraChainNode *node;
    // std::map<ActorId, BalanceDataInfo> cachedData;
    // int                                currentIndexWallet = 0;

public:
    Q_PROPERTY(
        bool transactionState READ transactionState WRITE setTransactionState NOTIFY transactionStateChanged)
    Q_PROPERTY(bool subscribed READ subscribed WRITE setSubscribed NOTIFY subscribedChanged)

    Q_PROPERTY(QString estimatedBalance READ estimatedBalance NOTIFY estimatedBalanceChanged)
    Q_PROPERTY(bool txLoading READ txLoading NOTIFY txLoadingChanged)

    Q_PROPERTY(bool syncing READ syncing NOTIFY syncingChanged)
    Q_PROPERTY(QString syncFrom READ syncFrom NOTIFY syncFromChanged)
    Q_PROPERTY(QString syncTo READ syncTo NOTIFY syncToChanged)
    Q_PROPERTY(QString progress READ progress NOTIFY progressChanged)

    WalletUIController(ExtraChainNode *nde, QObject *parent = nullptr);
    WalletUIController() {
        dbConnector = std::make_unique<DbConnector>(Utils::TRANSACTION_STATUS_CACHE);
    }
    bool transactionState() const {
        return _transactionState;
    }

    bool subscribed() const;
    void setSubscribed(bool newSubscribed);

    bool    syncing() const;
    QString syncTo() const;
    QString syncFrom() const;
    QString progress() const;

    QString estimatedBalance() const;

    Q_INVOKABLE VariantModel *wallets() const;
    Q_INVOKABLE VariantModel *txs() const;

    bool txLoading() const;

public slots:
    void newTx(const Transaction &tx, StatusTrx::StatusTrxType status);

    void sendSubscribe();
    void setTransactionState(bool newTransactionState);
    void showWalletTransactions(const QString &actor_id, bool hidden_reward);
    void loadTransactions(std::uint64_t from_time);

    void response(ActorId actor_id, TokenId token, int offset, std::vector<TransactionInfo> txs);

    void renameWallet(const QString &walletId, const QString &nameWallet, int index);
    void renamedWallet(const ActorId &actorId, const std::string &name);
    void renamesLoad();
    // void fillin_wallets_by_transactions(std::unordered_map<ActorId, std::vector<Transaction>> result);

    // TODO: in progress
    void syncStarted(BigNumber from, BigNumber to);

    void syncEnded() {
    }

    void syncProgress(BigNumber progress);

    void syncStatus(DagStatus status);
    void startControl();

    void copyWalletAddress(const QString &text);

    void updateBalances();

    void addWallet(const ActorId &actorId, const QString &name);

signals:
    void transactionStateChanged();
    void totalBalanceChanged();
    void subscribedChanged();
    void subscribtionActive();
    void syncingChanged();
    void syncToChanged();
    void syncFromChanged();
    void progressChanged();
    void message(const QString &message);
    void estimatedBalanceChanged();
    void txLoadingChanged();
    void notificationTx(const Transaction &tx, int notificationType);

public:
    Q_INVOKABLE QVariantMap calcBalance();

private:
    bool _transactionState;
    // bool                   _needUpdateWallets = true;
    // QString                _totalBalance;`
    bool _subscribed;
    bool hidden_reward_ = false;
    // QMap<QString, QString> cachedWalletNames;
    QTimer *_updateTimer;
    bool    m_syncing = false;
    QString m_syncFrom;
    QString m_syncTo;
    QString m_progress;
    // QVariantMap            _mapBalances;

    QTimer processing_timer;

    QString       m_estimatedBalance = "~";
    VariantModel *m_wallets          = new VariantModel(nullptr, { "wallet_id", "balance", "name", "status" });

    ActorId       current;
    VariantModel *m_txs = new VariantModel(nullptr,
                                           { "wallet",
                                             "dateTx",
                                             "participant",
                                             "amount",
                                             "is_deposit",
                                             "token",
                                             "typeTx"
                                             "hash",
                                             "section",
                                             "statusTx" });

    std::map<ActorId, int>       m_walletsIndexes;
    bool                         m_txLoading = false;
    std::unique_ptr<DbConnector> dbConnector;
};
