#include "WalletListView.h"

/*
#include "SRC/etutils.h"
#include "managers/token_manager.h"
#ifdef Q_OS_MAC
    #include "SRC/MacOs/MacosUtils.h"
#endif

WalletListView::WalletListView(QObject *parent)
    : QAbstractItemModel(parent) {
    _roles[WalletId]           = "wallet_id";
    _roles[WalletName]         = "wallet_name";
    _roles[Balance]            = "wallet_balance";
    _roles[Price]              = "price_coin";
    _roles[DailyBalanceChange] = "daily_balance_change";
    _roles[Value]              = "value";
}

QModelIndex WalletListView::index(int row, int column, const QModelIndex &parent) const {
    return hasIndex(row, column, parent) ? createIndex(row, column) : QModelIndex();
}

QModelIndex WalletListView::parent(const QModelIndex &child) const {
    Q_UNUSED(child)
    return QModelIndex();
}

int WalletListView::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : balanceDataInfoList.size();
}

int WalletListView::columnCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : 1;
}

QVariant WalletListView::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.column() != 0 || index.row() < 0 || index.row() >= balanceDataInfoList.size())
        return QVariant();
    const auto balanceDataInfoItem = balanceDataInfoList[index.row()];
    switch (role) {
    case WalletId:
        return balanceDataInfoItem.actor.toQString();
    case WalletName:
        return QString::fromStdString(balanceDataInfoItem.walletName);
    case Balance:
        return QString("%1 ROCC").arg(EtUtils::formatterNumber(balanceDataInfoItem.totalBalance));
        return EtUtils::formatterNumber(
                   BigNumberFloat(_mapBalances[balanceDataInfoItem.actor.toQString()].toString().toStdString(),
                                  NumeralBase::Dec))
               + " ROCC";
    case Price:
        return QString::number(balanceDataInfoItem.price) + "$";
    case Value:
        return calcValue(balanceDataInfoItem.totalBalance);
    case DailyBalanceChange:
        return "+12.4%";
    }
    return QVariant();
}

QHash<int, QByteArray> WalletListView::roleNames() const {
    return _roles;
}

void WalletListView::setBalanceData(const QVector<BalanceDataInfo> &list, QVariantMap balances) {
    _mapBalances = balances;
    balanceDataInfoList.clear();
    beginResetModel();
    balanceDataInfoList = list;
    _walletTotalBalance = BigNumberFloat("0", NumeralBase::Dec);
    endResetModel();
}

BalanceDataInfo WalletListView::getBalanceDataByIndex(const int &index) {
    return balanceDataInfoList.at(index);
}

void WalletListView::renameWallet(const int index, const QString &newWalletName) {
    balanceDataInfoList[index].walletName = newWalletName.toStdString();
    auto l                                = createIndex(index, 0);
    emit dataChanged(l, l);
}

void WalletListView::addWallet(const BalanceDataInfo &bdi) {
    beginInsertRows(QModelIndex(), balanceDataInfoList.size(), balanceDataInfoList.size());
    balanceDataInfoList.push_back(bdi);
    endInsertRows();
}

BalanceDataInfo::BalanceDataItem::BalanceDataItem() {
    tokensMap     = TokenManager::mapTokens();
    rocc_token_id = tokensMap["ROCC"];
    forRoccEnv    = false;
}

BalanceDataInfo::BalanceDataItem::BalanceDataItem(const ActorId     &actorId,
                                                  const Transaction &tx,
                                                  const long long   &dateTx) {
    tokensMap     = TokenManager::mapTokens();
    rocc_token_id = tokensMap["ROCC"];
    fromTx(actorId, tx, dateTx);
}

void BalanceDataInfo::BalanceDataItem::fromTx(const ActorId     &actorId,
                                              const Transaction &tx,
                                              const long long   &dateTx) {
    date              = dateTx;
    token             = tx.token();
    ActorId raccoonId = ActorId(rocc_token_id.toStdString());
    auto    amount    = tx.amount();

    if (tx.token() != raccoonId) {
        return;
    }

    if (tx.type() == TransactionType::Conversion) {
        participant = tx.sender();
        balanceChange += amount;
        forRoccEnv = true;
        return;
    }

    if (tx.type() != TransactionType::Regular) {
        return;
    }

    if (tx.sender() == actorId) {
        balanceChange -= amount;
        forRoccEnv  = true;
        participant = tx.receiver();
    }

    if (tx.receiver() == actorId) {
        balanceChange += amount;
        forRoccEnv  = true;
        participant = tx.sender();
    }
}

BalanceDataInfo::BalanceDataInfo(const ActorId &actor, const std::string &wn)
    : actor(actor) {
    if (!wn.empty()) {
        walletName = wn;
    }
}

void BalanceDataInfo::add(const BalanceDataItem &balanceDataItem) {
    if (std::none_of(listBalanceDataItem.begin(), listBalanceDataItem.end(), [=](const BalanceDataItem &bdi) {
            return bdi.date == balanceDataItem.date && bdi.participant == balanceDataItem.participant
                   && bdi.token == ActorId();
        })) {
        listBalanceDataItem.push_front(balanceDataItem);
        totalBalance += balanceDataItem.balanceChange;
    }
}

int BalanceDataInfo::size() const {
    return listBalanceDataItem.size();
}

QString WalletListView::totalBalance() const {
    return _totalBalance;
}

void WalletListView::setTotalBalance(const QString &newTotalBalance) {
    if (_totalBalance == newTotalBalance)
        return;
    _totalBalance = newTotalBalance;
    emit totalBalanceChanged();
}

void WalletListView::updateTotalBalance() {
    _wallets.clear();
    _walletTotalBalance = BigNumberFloat(0);
    _walletTotalBalance += _balanceFromZeroBlock;

    for (auto &bdi : balanceDataInfoList) {
        _walletTotalBalance += bdi.totalBalance;
        _wallets.push_back(bdi.actor.toQString());
    }

    auto formattedNumber = EtUtils::formatterNumber(_walletTotalBalance);
    setTotalBalance(QString("%1").arg(QString::fromStdString(_walletTotalBalance.to_string(NumeralBase::Dec))));
}

QString WalletListView::calcValue(const BigNumberFloat &balance, const float &price) const {
    float  balance_f = std::stof(balance.to_string(NumeralBase::Dec));
    double result    = balance_f * price;
    return QString::number(result, 'f', 2);
}

/ **
 * @brief Add the received transaction to the appropriate wallet and cache it in the database.
 * /
void WalletListView::updateBlock(const Block &block) {
    auto transactions = block.transactions();

    for (const auto &tx : transactions) {
        if (tx.token() == ActorId()) {
            continue;
        }

        if (std::find(trxHashes.begin(), trxHashes.end(), tx.hash()) == trxHashes.end()) {
            auto date = block.getDate();
            emit cacheTransaction(tx, date);
            trxHashes.insert(tx.hash());

            for (auto &bdi : balanceDataInfoList) {
                auto wallet = bdi.actor;
                if (wallet != tx.sender() && wallet != tx.receiver()) {
                    continue;
                }

                BalanceDataInfo::BalanceDataItem item(wallet, tx, block.getDate());
                if (wallet == tx.sender() && wallet == tx.receiver()) {
                    auto it = std::find_if(balanceDataInfoList.begin(),
                                           balanceDataInfoList.end(),
                                           [&](BalanceDataInfo &bdiR) {
                                               return bdiR.actor == tx.receiver() && bdiR.actor == tx.sender();
                                           });
                    if (it != balanceDataInfoList.end()) {
                        it->add(item);
                    }
                } else if (wallet == tx.sender()) {
                    auto it = std::find_if(balanceDataInfoList.begin(),
                                           balanceDataInfoList.end(),
                                           [&](BalanceDataInfo &bdiR) {
                                               return bdiR.actor == tx.receiver();
                                           });

                    if (it != balanceDataInfoList.end()) {
                        it->add(item);
                    }
                } else if (wallet == tx.receiver()) {
                    auto it = std::find_if(balanceDataInfoList.begin(),
                                           balanceDataInfoList.end(),
                                           [&](BalanceDataInfo &bdiR) {
                                               return bdiR.actor == tx.receiver();
                                           });

                    if (it != balanceDataInfoList.end()) {
                        it->add(item);
                    }
                }

                QString message   = "";
                QString amountStr = EtUtils::formatterNumber(tx.amount());
                QString sender    = tx.sender().toQString();
                QString receiver  = tx.receiver().toQString();

                if (wallet == tx.receiver()) {
                    message = QString("You have received %1 coins from user %2.").arg(amountStr).arg(sender);
                    if (tx.receiver() == ActorId()) {
                        message = QString("You have received %1 coins.").arg(amountStr);
                    }
                    if (tx.type() == TransactionType::Conversion) {
                        message = QString("You have received %1 mining reward coins.").arg(amountStr);
                    }
                } else {
                    message = QString("You have sent %1 coins to user %2.").arg(amountStr).arg(receiver);
                }

                emit showMessage(message);
            }
        }
    }
    for (auto &bdi : balanceDataInfoList) {
        auto wallet = bdi.actor;
        updateWallet(wallet);
    }
}

QVariantList WalletListView::wallets() {
    return _wallets;
}

void WalletListView::updateWallet(const ActorId &wallet) {
    for (int i = 0; i < balanceDataInfoList.size(); i++) {
        if (balanceDataInfoList[i].actor == wallet) {
            auto l = createIndex(i, 0);
            emit dataChanged(l, l);
        }
    }
}

void WalletListView::addStateFromZeroBlock(const ActorId &id, const BigNumberFloat &state) {

    const auto find =
        std::find_if(balanceDataInfoList.begin(), balanceDataInfoList.end(), [id](const BalanceDataInfo &bdi) {
            return bdi.actor == id;
        });

    if (find != balanceDataInfoList.end()) {
        find->totalBalance += state;
    }
}

void WalletListView::updateBalances(QVariantMap map) {
    _mapBalances = map;
    for (int i = 0; i < balanceDataInfoList.size(); i++) {
        auto l = createIndex(i, 0);
        emit dataChanged(l, l);
    }
}

void WalletListView::updateWallets(QVariantList list) {
    _wallets = list;
}

void WalletListView::copyWalletAddress(const QString &text) {
#ifdef Q_OS_MAC
    MacosUtils mu;
    mu.clipboard(text);
#else
    QGuiApplication::clipboard()->setText(text);
#endif
}
*/
