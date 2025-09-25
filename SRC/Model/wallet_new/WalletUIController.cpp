#include "WalletUIController.h"
#include "managers/token_manager.h"

#include <QJsonObject>
#include <QRandomGenerator>
#include <QtConcurrent>
#include <QGuiApplication>

#include "chain/actor_index.h"
#include "SRC/etutils.h"
#include "utils/db_connector.h"

#include <format>

QString normalizeAmount(const QString &originalString) {
    int     dotPos = originalString.indexOf('.');
    QString result = originalString;
    if (dotPos != -1) {
        result = originalString.left(dotPos + 4);
        return result;
    }

    return originalString;
}

WalletUIController::WalletUIController(ExtraChainNode *nde, QObject *parent)
    : QObject(parent)
    , node(nde) {
    // connect(Subscription::instance(node.dfs()).get(),
    //         &Subscription::subscribtionActive,
    //         this,
    //         &WalletUIController::subscribtionActive);

    _updateTimer = new QTimer(this);
    _updateTimer->setSingleShot(true);
    _updateTimer->setInterval(500);
    connect(_updateTimer, &QTimer::timeout, this, [=, this] {
        this->updateBalances();
    });

    // connect(walletListView, &WalletListView::cacheTransaction, this, &WalletUIController::cacheTx);
    // connect(node.tokenManager(), &TokenManager::newToken, transactionModel, &TransactionModel::update);
    // connect(node.blockchain(), &Blockchain::updateSelf, this, [=, this](BigNumber blockId) {
    //     auto block = node.blockchain()->read_block_by_id(blockId);
    //     if (block.has_value()) {
    //         walletListView->updateBlock(block.value().getBlock().value());
    //         if (_needUpdateWallets) {
    //             _updateTimer->start(1000);
    //         }

    //         // TODO: watch this
    //         this->updateBalances();
    //     }
    // });
    // connect(node.blockchain(), &Blockchain::zeroBlock, this, &WalletUIController::balanceFromZeroBlock);
    setSubscribed(false);
    // connect(node.blockchain(),
    //         &Blockchain::resultTransactions,
    //         this,
    //         &WalletUIController::fillin_wallets_by_transactions);
    // connect(node.blockchain(), &Blockchain::statusChanged, this, [&](BlockchainStatus status) {
    //     if (status == BlockchainStatus::Ready) {
    //         qDebug() << "Begin fill wallets";
    //         fillWallets();
    //     }
    // });

    connect(node, &ExtraChainNode::selfTxAdded, this, &WalletUIController::newTx);
    connect(&node->dag()->transaction_cache(),
            &TransactionCache::response,
            this,
            &WalletUIController::response,
            Qt::QueuedConnection);

    connect(node, &ExtraChainNode::dagSyncStart, this, &WalletUIController::syncStarted);
    connect(node, &ExtraChainNode::dagSyncProgress, this, &WalletUIController::syncProgress);
    connect(node, &ExtraChainNode::dagControlProgress, this, &WalletUIController::syncProgress);

    connect(node->actor_index(), &ActorIndex::firstSyncStarted, [this] {
        this->m_syncing = true;
        emit syncingChanged();
    });

    // connect(node.blockchain(), &Blockchain::syncEnd, this, &WalletUIController::syncEnded);
    connect(node, &ExtraChainNode::dagStatus, this, &WalletUIController::syncStatus);
    connect(node->account_controller(), &AccountController::dogenerated, this, &WalletUIController::startControl);
    connect(node, &ExtraChainNode::dagTxSended, this, [=, this](SectionId section_id, std::string hash) {
        if (!node->dag()->sended_transactions().contains(hash)) {
            eTemp("[Ttt] No tx {} {}", section_id, hash);
            return;
        }

        auto transaction = node->dag()->sended_transactions()[hash];
        if (!transaction.is_empty() && transaction.type() != TransactionType::Reward) {
            newTx(transaction, StatusTrx::StatusTrxType::Processing);
        }
    });
    connect(node, &ExtraChainNode::dagTxApproved, this, [=, this](SectionId section_id, std::string hash) {
        for (int i = 0; i < m_txs->list().size(); i++) {
            auto item = m_txs->list().at(i);
            if (item["hash"].toString().toStdString() == hash && item["statusTx"] == "Processing") {
                eTemp("[Ttt] remove");
                // m_txs->set(i, "statusTx", QString::fromStdString(StatusTrx::toString(0)));
                m_txs->remove(i, 1);

                auto formated = QString("UPDATE CacheStatusTransactions SET status = 0  WHERE hash = '%1'")
                                    .arg(QString::fromStdString(hash));
                dbConnector->update(formated.toStdString());
            }
        }
    });
    connect(node, &ExtraChainNode::dagTxNotApproved, this, [=, this](SectionId section_id, std::string hash) {
        if (!node->dag()->failed_transactions().contains(hash)) {
            return;
        }

        auto transaction = node->dag()->failed_transactions()[hash];
        // bool containTx   = std::any_of(m_txs->list().cbegin(), m_txs->list().cend(), [&](const QVariantMap
        // &item) {
        //     return item["hash"].toString().toStdString() == hash;
        // });

        // if (!containTx) {

        for (int i = 0; i < m_txs->list().size(); i++) {
            auto item = m_txs->list().at(i);
            if (item["hash"].toString().toStdString() == hash && item["statusTx"] == "Processing") {
                eTemp("[Ttt] change to error, {}", hash);
                m_txs->set(i, "statusTx", QString::fromStdString(StatusTrx::toString(2)));

                auto formated = QString("UPDATE CacheStatusTransactions SET status = 2  WHERE hash = '%1'")
                                    .arg(QString::fromStdString(hash));
                dbConnector->update(formated.toStdString());
                return;
            }
        }

        eLog("[Wallet] Add fail {}", hash);
        newTx(transaction, StatusTrx::Failed);
        // }
    });

    dbConnector = std::make_unique<DbConnector>(Utils::TRANSACTION_STATUS_CACHE);
    if (dbConnector->open()) {
        bool success = dbConnector->query(Config::DataStorage::cacheStatusTransactionTableCreate);
    }

    connect(&processing_timer, &QTimer::timeout, [this] {
        qint64 currentTime = QDateTime::currentMSecsSinceEpoch();

        for (int i = m_txs->list().size() - 1; i >= 0; i--) {
            auto item = m_txs->list().at(i);
            if (item["statusTx"] == "Processing") {
                auto timestamp = item["dateTx"].toLongLong();

                if (currentTime - timestamp > 10000) {
                    eLog("[Wallet] Clear");
                    m_txs->remove(i, 1);
                    // m_txs->set(i, "statusTx", QString::fromStdString(StatusTrx::toString(2)));
                    // dbConnector->update(
                    // std::format("UPDATE CacheStatusTransactions SET status = 0  WHERE hash = '{}'", hash));
                }
            }
        }
    });
    processing_timer.start(15000);

    // void syncStart(BigNumber, BigNumber);
    // void syncEnd();
    // void syncProgress(BigNumber);
    // void statusChanged(BlockchainStatus status);
    // void syncStatusChanged(BlockchainSyncStatus);
    // connect(walletListView, &WalletListView::requestUpdateBalance, this, &WalletUIController::updateBalances);
}

void WalletUIController::sendSubscribe() {
    // Subscription::instance()->sendSubscribe(Subscription::SubscriptionType::Basic, true);
}

void WalletUIController::setTransactionState(bool newTransactionState) {
    if (_transactionState == newTransactionState)
        return;
    _transactionState = newTransactionState;
    emit transactionStateChanged();
}

void WalletUIController::showWalletTransactions(const QString &actor_id, bool hidden_reward) {
    m_txs->clear();
    setTransactionState(true);
    // qApp->processEvents();

    if (!actor_id.isEmpty()) {
        current = ActorId(actor_id.toStdString());
    }

    hidden_reward_ = hidden_reward;
    emit node->dag()->transaction_cache().request(current,
                                                  TokenId("468faf2f1be6504a9a26f7f027f7e43380b0d77d"),
                                                  hidden_reward_,
                                                  0);
}

void WalletUIController::loadTransactions(std::uint64_t from_time) {
    if (m_txLoading) {
        return;
    }

    eLog("loadTransactions {}", from_time);
    m_txLoading = true;
    emit txLoadingChanged();

    emit node->dag()->transaction_cache().request(current,
                                                  TokenId("468faf2f1be6504a9a26f7f027f7e43380b0d77d"),
                                                  hidden_reward_,
                                                  from_time);
}

void WalletUIController::response(ActorId actor_id, TokenId token, int offset, std::vector<TransactionInfo> txs) {
    QVariantList list;

    for (const auto &tx : txs) {
        bool received = tx.transaction.receiver() == actor_id;

        QVariantMap map;
        map["wallet"] = actor_id.toQString();
        map["token"]  = token.toQString();
        map["dateTx"] = QVariant::fromValue(static_cast<qulonglong>(tx.transaction.timestamp()));
        map["participant"] =
            received ? tx.transaction.sender().toQString() : tx.transaction.receiver().toQString();
        map["amount"]     = tx.transaction.amount().to_string(NumeralBase::Dec).c_str();
        map["is_deposit"] = tx.operation == TransactionAmountOperation::Plus;
        map["typeTx"]     = std::to_underlying(tx.transaction.type());
        map["hash"]       = QString::fromStdString(tx.hash);
        map["section"]    = QString::fromStdString(tx.transaction.section().to_string());
        auto rows         = dbConnector->select("SELECT status FROM CacheStatusTransactions WHERE hash=\'"
                                        + tx.transaction.hash() + "\'");
        auto transaction  = node->dag()->failed_transactions()[tx.transaction.hash()];
        StatusTrx::StatusTrxType statusTrx =
            !transaction.is_empty() ? StatusTrx::StatusTrxType::Approved : StatusTrx::StatusTrxType::Failed;
        QString status = QString::fromStdString(StatusTrx::toString(statusTrx));
        if (rows.size() > 0 && tx.transaction.type() != TransactionType::Reward) {
            std::string loadedStatus = StatusTrx::toString(std::stoi(rows.at(0)["status"]));
            status                   = QString::fromStdString(loadedStatus);
        }
        map["statusTx"] = status;
        list.push_back(map);

        if (tx.transaction.type() != TransactionType::Reward) {
            DbRow dbRow;
            dbRow["status"] = std::to_string(StatusTrx::toInt(statusTrx));
            dbRow["hash"]   = tx.transaction.hash();
            dbConnector->insert(Config::DataStorage::cacheStatusTransactionTable, dbRow);
        }
    }

    m_txs->appends(list);

    if (m_txLoading) {
        m_txLoading = false;
        emit txLoadingChanged();
    }
}

void WalletUIController::renameWallet(const QString &walletId, const QString &nameWallet, int index) {
    eLog("{} {}", walletId, nameWallet);
    auto isRenamed = node->write_actor_rename(ActorId(walletId.toStdString()), nameWallet.toStdString());

    if (isRenamed) {
        m_wallets->set(index, "name", nameWallet);
    }
}

void WalletUIController::renamedWallet(const ActorId &actorId, const std::string &name) {
    for (int i = 0; i != m_wallets->count(); i++) {
        auto wallet = m_wallets->get(i);
        if (wallet["wallet_id"] == actorId.toQString()) {
            m_wallets->set(i, "name", QString::fromStdString(name));
            break;
        }
    }
}

void WalletUIController::renamesLoad() {
    auto renamed = node->read_actor_renames();

    for (const auto &[actorId, name] : renamed) {
        renamedWallet(actorId, name);
    }
}

bool WalletUIController::subscribed() const {
    return _subscribed;
}

void WalletUIController::setSubscribed(bool newSubscribed) {
    if (_subscribed == newSubscribed)
        return;
    _subscribed = newSubscribed;
    emit subscribedChanged();
}

bool WalletUIController::syncing() const {
    return m_syncing;
}

QString WalletUIController::syncFrom() const {
    return m_syncFrom;
}

QString WalletUIController::syncTo() const {
    return m_syncTo;
}

QString WalletUIController::progress() const {
    return m_progress;
}

QVariantMap WalletUIController::calcBalance() {
    QVariantMap    map;
    BigNumberFloat allBalance;
    const auto     actors = node->account_controller()->accounts_ids();

    auto balances = node->dag()->calculate_actors_balance(actors);

    for (const auto &[pair, balance] : balances) {
        if (pair.second != TokenId("468faf2f1be6504a9a26f7f027f7e43380b0d77d")) {
            continue;
        }

        map[pair.first.toQString()] = QString::fromStdString(balance.to_string(NumeralBase::Dec));
        allBalance += balance;
    }

    for (const auto &actor : actors) {
        auto qstr = actor.toQString();
        if (!map.contains(qstr)) {
            map[qstr] = "0";
        }
    }

    map["all"] = QString::fromStdString(allBalance.to_string(NumeralBase::Dec));

    return map;
}

void WalletUIController::startControl() {
    auto &profile  = node->account_controller()->current_profile();
    auto  names    = profile.wallet_names();
    auto  balances = calcBalance();

    const auto &actors = profile.actors();
    m_wallets->clear();

    int i = 0;
    for (const auto &actor : actors) {
        QVariantMap wallet;
        wallet["wallet_id"] = actor.id().toQString();
        wallet["name"]      = QString::fromStdString(names[actor.id()]);
        wallet["balance"] =
            node->dag()->mode() == DagMode::Light ? "~" : balances[actor.id().toQString()].toString();

        int status = 0;
        if (actor.id() == profile.system_id()) {
            status = 1;
        }
        if (actor.id() == profile.main_id()) {
            status = 2;
        }
        if (actor.type() == ActorType::Service) {
            status = 3;
        }
        if (actor.type() == ActorType::DAppMaster) {
            status = 4;
        }
        wallet["status"] = status;

        m_wallets->append(wallet);
        m_walletsIndexes.insert({ actor.id(), i });
        i += 1;
    }

    m_estimatedBalance = node->dag()->mode() == DagMode::Light ? "~" : balances["all"].toString();
    emit estimatedBalanceChanged();
}

void WalletUIController::newTx(const Transaction &transaction, StatusTrx::StatusTrxType status) {
    if (node->dag()->status() != DagStatus::Ready) {
        return;
    }

    // balance
    // updateBalances();
    _updateTimer->start();

    // notification
    for (const auto &[actor_id, index] : m_walletsIndexes) {
        QString msg;
        auto    amount = normalizeAmount(QString::fromStdString(transaction.amount().to_string(NumeralBase::Dec)));

        if (transaction.type() == TransactionType::Repeatable) {
            msg = tr("Subscription activated!");
        } else if (transaction.type() == TransactionType::Reward
                   || transaction.type() == TransactionType::Conversion) {
            msg = tr("You have received %1 mining reward coins").arg(amount);
            emit notificationTx(transaction, Notification::NotifyType::Reward);
        } else if (actor_id == transaction.receiver()) {
            msg = tr("You have received %1 coins from user %2").arg(amount).arg(transaction.sender().toQString());
            emit notificationTx(transaction, Notification::NotifyType::Deposit);
        } else if (actor_id == transaction.sender()) {
            msg = tr("You have sent %1 coins to user %2").arg(amount).arg(transaction.receiver().toQString());
            emit notificationTx(transaction, Notification::NotifyType::Withdrawal);
        } else if (transaction.receiver() == ActorId()) {
            msg = tr("You have received %1 coins").arg(amount);
            emit notificationTx(transaction, Notification::NotifyType::Deposit);
        }

        if (!msg.isEmpty()) {
            emit message(msg);
        }
    }

    // tx go gui
    if (hidden_reward_
        && (transaction.type() == TransactionType::Reward || transaction.type() == TransactionType::Conversion)) {
        return;
    }

    if (!_transactionState && transaction.token() != TokenId("468faf2f1be6504a9a26f7f027f7e43380b0d77d")) {
        return;
    }

    if (transaction.sender() == current || transaction.receiver() == current) {
        TransactionAmountOperation operation = TransactionAmountOperation::Plus;
        if (current == transaction.sender()
            && (transaction.type() == TransactionType::Regular
                || transaction.type() == TransactionType::Repeatable)) {
            operation = TransactionAmountOperation::Minus;
        }

        QVariantMap map;
        map["wallet"]      = transaction.sender().toQString();
        map["token"]       = transaction.token().toQString();
        map["dateTx"]      = QVariant::fromValue(static_cast<qulonglong>(transaction.timestamp()));
        map["participant"] = transaction.receiver().toQString();
        map["amount"]      = transaction.amount().to_string(NumeralBase::Dec).c_str();
        map["is_deposit"]  = operation == TransactionAmountOperation::Plus;
        map["typeTx"]      = std::to_underlying(transaction.type());
        map["hash"]        = QString::fromStdString(transaction.hash());
        map["section"]     = QString::fromStdString(transaction.section().to_string());
        auto rows          = dbConnector->select("SELECT status FROM CacheStatusTransactions WHERE hash=\'"
                                        + transaction.hash() + "\'");
        map["statusTx"]    = QString::fromStdString(StatusTrx::toString(StatusTrx::toInt(status)));
        if (!hidden_reward_)
            m_txs->insert(0, map);

        if (transaction.type() != TransactionType::Reward) {
            DbRow dbRow;
            dbRow["status"] = std::to_string(StatusTrx::toInt(status));
            dbRow["hash"]   = transaction.hash();
            dbConnector->insert(Config::DataStorage::cacheStatusTransactionTable, dbRow);
        }
    }
}

void WalletUIController::copyWalletAddress(const QString &text) {
    QGuiApplication::clipboard()->setText(text);
}

void WalletUIController::updateBalances() {
    auto balances = calcBalance();

    for (const auto &[actor_id, index] : m_walletsIndexes) {
        m_wallets->set(index, "balance", balances[actor_id.toQString()]);
    }

    m_estimatedBalance = balances["all"].toString();
    emit estimatedBalanceChanged();
}

void WalletUIController::addWallet(const ActorId &actorId, const QString &name) {
    QVariantMap wallet;
    wallet["wallet_id"] = actorId.toQString();
    wallet["name"]      = name;
    wallet["balance"]   = "0";
    m_walletsIndexes.insert({ actorId, m_wallets->count() });
    m_wallets->append(wallet);
}

void WalletUIController::syncStarted(BigNumber from, BigNumber to) {
    m_syncFrom = QString::fromStdString(from.to_string(NumeralBase::Dec));
    emit syncFromChanged();

    m_progress = QString::fromStdString(from.to_string(NumeralBase::Dec));
    emit progressChanged();

    m_syncTo = QString::fromStdString(to.to_string(NumeralBase::Dec));
    emit syncToChanged();
}

void WalletUIController::syncProgress(BigNumber progress) {
    m_progress = QString::fromStdString(progress.to_string(NumeralBase::Dec));
    emit progressChanged();
}

void WalletUIController::syncStatus(DagStatus status) {
    bool newSyncing = status != DagStatus::Ready;
    if (newSyncing == m_syncing) {
        return;
    }

    m_syncing = newSyncing;
    emit syncingChanged();

    if (!m_syncing) {
        updateBalances();
    }
}

QString WalletUIController::estimatedBalance() const {
    return m_estimatedBalance;
}

VariantModel *WalletUIController::wallets() const {
    return m_wallets;
}

VariantModel *WalletUIController::txs() const {
    return m_txs;
}

bool WalletUIController::txLoading() const {
    return m_txLoading;
}
