#pragma once
#include "SRC/etutils.h"
#include "chain/transaction.h"
#include "utils/variant_model.h"
#include "utils/db_connector.h"

struct RaccoonNotification {
    Notification::NotifyType type;
    std::string              sender, receiver, date, time, amount;
    int                      timestamp;
    bool                     is_today;
};

// TO DO
//  1. Show notification is read
//  2. Remove notification
//  3. Clear notification

class NotificationController : public VariantModel {
    Q_OBJECT

    std::unique_ptr<DbConnector>     dbConnector;
    std::vector<RaccoonNotification> notifications;
    std::set<std::string>            _hashesNotification;
    bool                             isShowMiningRewardNotifications = false;

public:
    NotificationController(VariantModel* parent = nullptr)
        : VariantModel(parent) {
        QDir().mkdir(QString::fromStdString(ChainConst::TMP_FOLDER));

        dbConnector = std::make_unique<DbConnector>(Utils::NOTIFIACATION_CACHE);
        if (dbConnector->open()) {
            // Create table if it doesn't exist

            bool success = dbConnector->query(Config::DataStorage::notificationTableCreate);

            if (!success) {
                eLog("[DagCache] Failed to create cache notification table");
            }
            setModelRoles({ "type", "sender", "receiver", "date", "time", "amount", "is_today", "time_date" });

            load();
        }
    }

    void load() {
        if (!dbConnector->is_open()) {
            return;
        }
        std::vector<DbRow> rows = dbConnector->select_all(Config::DataStorage::notificationTable);
        for (auto& row : rows) {
            RaccoonNotification rn;
            rn.type = Notification::fromInt(std::stoi(row["type"]));
            if (rn.type != Notification::NotifyType::Message) {
                rn.receiver        = row["receiver"];
                rn.amount          = row["amount"];
                rn.sender          = row["sender"];
                rn.timestamp       = std::stoi(row["timestamp"]);
                auto time          = QDateTime::fromSecsSinceEpoch(rn.timestamp).toString("hh:mm");
                auto date          = QDateTime::fromSecsSinceEpoch(rn.timestamp).toString("dd MMMM yyyy");
                auto time_date     = QDateTime::fromSecsSinceEpoch(rn.timestamp).toString("hh:mm:ss dd/MM/yy");
                rn.time            = time.toLocal8Bit().toStdString();
                rn.date            = date.toLocal8Bit().toStdString();
                const bool isToday = (QDateTime::fromSecsSinceEpoch(rn.timestamp).date() == QDate::currentDate());

                auto map = QVariantMap { { "type", rn.type },
                                         { "sender", QString::fromStdString(rn.sender) },
                                         { "receiver", QString::fromStdString(rn.receiver) },
                                         { "time", QString::fromStdString(rn.time) },
                                         { "date", QString::fromStdString(rn.date) },
                                         { "amount", QString::fromStdString(rn.amount) },
                                         { "is_today", isToday },
                                         { "time_date", time_date.toLocal8Bit() } };
                insert(0, map);
                notifications.push_back(rn);
            }
        }
    }

    void addNotification(const Notification::NotifyType& type,
                         const QString&                  amount,
                         const QString&                  sender,
                         const QString&                  receiver,
                         const int&                      timestamp) {

        RaccoonNotification rn;
        rn.type            = type;
        rn.amount          = amount.toStdString();
        rn.receiver        = receiver.toStdString();
        rn.sender          = sender.toStdString();
        auto time          = QDateTime::fromSecsSinceEpoch(timestamp).toString("hh:mm");
        auto date          = QDateTime::fromSecsSinceEpoch(timestamp).toString("dd MMMM yyyy");
        auto time_date     = QDateTime::fromSecsSinceEpoch(timestamp).toString("hh:mm:ss dd/MM/yy");
        rn.time            = time.toLocal8Bit().toStdString();
        rn.date            = date.toLocal8Bit().toStdString();
        const bool isToday = (QDateTime::fromSecsSinceEpoch(timestamp).date() == QDate::currentDate());

        auto map = QVariantMap { { "type", rn.type },
                                 { "sender", QString::fromStdString(rn.sender) },
                                 { "receiver", QString::fromStdString(rn.receiver) },
                                 { "time", QString::fromStdString(rn.time) },
                                 { "date", QString::fromStdString(rn.date) },
                                 { "amount", QString::fromStdString(rn.amount) },
                                 { "is_today", isToday },
                                 { "time_date", time_date.toLocal8Bit() } };

        insert(0, map);
        notifications.push_back(rn);
    }

public slots:
    void newTransactionForNotification(const Transaction& tx, const int& notificationType) {
        if (_hashesNotification.contains(tx.hash()))
            return;

        if (isShowMiningRewardNotifications && notificationType == Notification::NotifyType::Reward) {
            return;
        }

        _hashesNotification.insert(tx.hash());

        QString  amount   = tx.amount().to_string(NumeralBase::Dec).c_str();
        QString  sender   = tx.sender().toQString();
        QString  receiver = tx.receiver().toQString();
        uint64_t dateTime = tx.timestamp();

        DbRow dbRow;
        dbRow["type"]                        = std::to_string(notificationType);
        const std::string serializedTx       = MessagePack::serialize(tx);
        auto              transaction_result = MessagePack::deserialize<Transaction>(serializedTx);
        dbRow["amount"]                      = tx.amount().to_string(NumeralBase::Dec);
        dbRow["sender"]                      = tx.sender().to_string();
        dbRow["receiver"]                    = tx.receiver().to_string();
        int timestamp                        = static_cast<int>(dateTime / 1000);
        dbRow["timestamp"]                   = std::to_string(timestamp);
        dbRow["hash"]                        = tx.hash();
        dbRow["message"]                     = "";

        bool inserted = dbConnector->insert(Config::DataStorage::notificationTable, dbRow);
        addNotification(Notification::fromInt(notificationType), amount, sender, receiver, timestamp);
    }

    void showMiningRewardNotifications(const bool& isShowRewardMiningNotifications) {
        qDebug() << "Show mining notifications changed" << isShowRewardMiningNotifications;
        isShowMiningRewardNotifications = isShowRewardMiningNotifications;
    }
};
