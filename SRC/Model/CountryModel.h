#pragma once
#include <QAbstractListModel>
#include "vpnmanager.h"

#include <set>

struct CountryDetail {
    QString                           nameCountry;
    int                               count = 1;
    std::set<std::string>             actorIDs;
    raccoon::vpn::VPNManager::VPNType type;

    CountryDetail() {
    }
    CountryDetail(const QString &nameCountry)
        : nameCountry(nameCountry) {};
};
Q_DECLARE_METATYPE(CountryDetail)

class CountryModel : public QAbstractListModel {
    Q_OBJECT

public:
    enum CountryRoles {
        NameCountryRole,
        CountRole,
        TypeRole
    };

    explicit CountryModel(QObject *parent = nullptr)
        : QAbstractListModel(parent) {
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override {
        Q_UNUSED(parent);
        return static_cast<int>(m_countries.size());
    }

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override {
        if (index.row() < 0 || index.row() >= static_cast<int>(m_countries.size()))
            return QVariant();

        const CountryDetail &country = m_countries[index.row()];

        if (role == NameCountryRole)
            return country.nameCountry;
        else if (role == CountRole)
            return country.count + 1;
        else if (role == TypeRole)
            return country.type == raccoon::vpn::VPNManager::VPNType::WIREGUARD ? 0
                   : country.type == raccoon::vpn::VPNManager::VPNType::BOTH    ? 1
                                                                                : 2;

        return QVariant();
    }

    Q_INVOKABLE QVariantMap get(int index) const {
        QVariantMap result;

        if (index < 0 || index >= static_cast<int>(m_countries.size())) {
            return result;
        }

        const CountryDetail &country = m_countries[index];

        result["nameCountry"] = country.nameCountry;
        result["count"]       = country.count + 1;
        result["type"]        = country.type == raccoon::vpn::VPNManager::VPNType::WIREGUARD ? 0
                                : country.type == raccoon::vpn::VPNManager::VPNType::BOTH    ? 1
                                                                                             : 2;

        return result;
    }

    QHash<int, QByteArray> roleNames() const override {
        QHash<int, QByteArray> roles;
        roles[NameCountryRole] = "nameCountry";
        roles[CountRole]       = "count";
        roles[TypeRole]        = "type";
        return roles;
    }

    void addCountry(const QString                          &nameCountry,
                    const std::string                       actorID,
                    const raccoon::vpn::VPNManager::VPNType vpnType) {
        bool isChanged = false;
        for (int i = 0; i < m_countries.size(); ++i) {
            auto &countryObj = m_countries[i];
            if (countryObj.nameCountry == nameCountry) {
                if (!countryObj.actorIDs.contains(actorID)) {
                    countryObj.count += 1;
                    countryObj.actorIDs.emplace(actorID);
                    countryObj.type     = vpnType;
                    QModelIndex topLeft = index(i, 0);
                    emit        dataChanged(topLeft, topLeft);
                }
                isChanged = true;
                break;
            }
        }

        if (!isChanged) {
            CountryDetail detail(nameCountry);
            detail.type = vpnType;
            detail.actorIDs.emplace(actorID);

#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
            if (vpnType != raccoon::vpn::VPNManager::VPNType::SINGBOX) {
                beginInsertRows(QModelIndex(), rowCount(), rowCount());
                m_countries.push_back(detail);
                endInsertRows();
            }
#else
            if (vpnType != raccoon::vpn::VPNManager::VPNType::WIREGUARD) {
                beginInsertRows(QModelIndex(), rowCount(), rowCount());
                m_countries.push_back(detail);
                endInsertRows();
            }
#endif
        }
    }

    void removeCountry(const QString &countryName, const std::string actorID) {
        for (int i = 0; i < m_countries.size(); ++i) {
            auto &countryObj = m_countries[i];
            if (countryObj.nameCountry == countryName) {
                if (countryObj.actorIDs.contains(actorID)) {
                    if (countryObj.count > 1) {
                        countryObj.count--;
                        countryObj.actorIDs.erase(actorID);
                        QModelIndex topLeft = index(i, 0);
                        emit        dataChanged(topLeft, topLeft);
                    } else {
                        beginRemoveRows(QModelIndex(), i, i);
                        m_countries.erase(m_countries.begin() + i);
                        endRemoveRows();
                    }
                }
                return;
            }
        }
    }

    std::vector<CountryDetail> getCountries() const {
        return m_countries;
    }

    void clear() {
        beginResetModel();
        m_countries.clear();
        endResetModel();
    }

    bool empty() const {
        return m_countries.empty();
    }

    bool contain(const QString &countryName) {
        auto it = std::find_if(m_countries.begin(),
                               m_countries.end(),
                               [&countryName](const CountryDetail &countryDetail) {
                                   return countryDetail.nameCountry == countryName;
                               });
        return (it != m_countries.end());
    }

private:
    std::vector<CountryDetail> m_countries;
};
