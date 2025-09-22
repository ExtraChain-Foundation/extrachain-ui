#include "TransactionListView.h"

/*
#include "SRC/etutils.h"
#include "managers/token_manager.h"

TransactionModel::TransactionModel(QObject *parent)
    : QAbstractItemModel(parent) {
    _roles[Wallet]      = "wallet";
    _roles[Date]        = "dateTx";
    _roles[Participant] = "participant";
    _roles[Amount]      = "amount";
    _roles[IsDeposit]   = "is_deposit";
    _roles[Token]       = "token";
    tokensMap           = TokenManager::mapTokensByTokenId();
}

QModelIndex TransactionModel::index(int row, int column, const QModelIndex &parent) const {
    return hasIndex(row, column, parent) ? createIndex(row, column) : QModelIndex();
}

QModelIndex TransactionModel::parent(const QModelIndex &child) const {
    Q_UNUSED(child)
    return QModelIndex();
}

int TransactionModel::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : listOfTrx.size();
}

int TransactionModel::columnCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : 1;
}

QVariant TransactionModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.column() != 0 || index.row() < 0 || index.row() >= listOfTrx.size())
        return QVariant();

    auto       it          = std::next(listOfTrx.begin(), index.row());
    const auto balanceItem = *it;
    switch (role) {
    case Wallet:
        return _currentWallet;
    case Date:
        return QDateTime::fromMSecsSinceEpoch(balanceItem.date).toString("hh:mm:ss\ndd.MM.yyyy");
    case Amount:
        return EtUtils::formatterNumber(balanceItem.balanceChange);
    case Participant:
        return balanceItem.participant.toQString();
    case IsDeposit:
        return (balanceItem.balanceChange > 0);
    case Token: {
        auto it = tokensMap.find(balanceItem.token.toQString());
        if (it != tokensMap.end())
            return it.value();

        // eWarning("Can not find token by id {}", balanceItem.token.toQString());
        return "ROCC"; // ?
    };
    }
    return QVariant();
}

QHash<int, QByteArray> TransactionModel::roleNames() const {
    return _roles;
}

void TransactionModel::setCurrentWallet(const QString &currentWallet) {
    _currentWallet = currentWallet;
}

void TransactionModel::fillModel(const BalanceDataInfo &bdi) {
    setCurrentWallet(bdi.actor.toQString());
    beginResetModel();
    listOfTrx = bdi.listBalanceDataItem;
    endResetModel();
}

void TransactionModel::update() {
    tokensMap = TokenManager::mapTokens();
    emit layoutChanged();
}

void TransactionModel::appendTx(const Transaction &tx, const std::uint64_t &date) {
    if (tx.isRewardTransaction()) {
        return;
    }

    if (tx.receiver().toQString() == _currentWallet || tx.sender().toQString() == _currentWallet) {
        beginInsertRows(QModelIndex(), listOfTrx.size(), listOfTrx.size());
        listOfTrx.push_front(BalanceDataInfo::BalanceDataItem(tx.sender(), tx, date));
        endInsertRows();
    }
}

bool TransactionModel::isEmpty() const {
    return listOfTrx.empty();
}
*/
