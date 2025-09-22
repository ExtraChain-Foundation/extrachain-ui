#include "SRC/helper_linux.h"

#ifndef Q_OS_IOS
    #include <QProcess>
    #include <QRegularExpression>
    #include <QFile>
    #include <QTextStream>

    #include "utils/exc_logs.h"
#endif

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    #include <unistd.h>
    #include <sys/stat.h>

    #include <QDir>

    #include "utils/exc_utils.h"
#endif

int RaccoonLinux::processInterface() {
#ifndef Q_OS_IOS
    QProcess ifconfig;
    ifconfig.start("ifconfig");
    ifconfig.waitForFinished();
    QString raccoonIface = QRegularExpression("RACCOON_[^:]*").match(ifconfig.readAllStandardOutput()).captured(0);

    if (raccoonIface.isEmpty()) {
        eLog("No RACCOON interface found");
        eLog("Checking for leftover configuration files...");
        QProcess::execute("sudo", QStringList() << "bash" << "-c" << "rm -f /etc/wireguard/RACCOON_*.conf");
        return 0;
    }

    eLog("Processing interface: {}", raccoonIface);
    QString confFile = QString("/etc/wireguard/%1.conf").arg(raccoonIface);

    if (QFile::exists(confFile)) {
        eLog("Found configuration file: {}", confFile);
    } else {
        eLog("Configuration file not found. Creating: {}", confFile);

        ifconfig.start("ifconfig", QStringList() << raccoonIface);
        ifconfig.waitForFinished();
        QString currentIP = QRegularExpression("inet (\\d+\\.\\d+\\.\\d+\\.\\d+)")
                                .match(ifconfig.readAllStandardOutput())
                                .captured(1);

        if (currentIP.isEmpty()) {
            eLog("Failed to get current IP address for {}", raccoonIface);
            return 1;
        }

        QStringList octets = currentIP.split('.');
        octets[2]          = "101";
        QString newIP      = octets.join('.');

        QFile file(confFile);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            eLog("Failed to create configuration file");
            return 1;
        }
        QTextStream(&file) << "[Interface]\nAddress = " << newIP << "/24\n";
        file.close();

        eLog("Created configuration file with address: {}", newIP);
    }

    QProcess::execute("sudo", QStringList() << "wg-quick" << "down" << raccoonIface);
    eLog("Removing all RACCOON configuration files...");
    QProcess::execute("sudo", QStringList() << "bash" << "-c" << "rm -f /etc/wireguard/RACCOON_*.conf");

    return 0;
#else
    return 0;
#endif
}

bool RaccoonLinux::isRunningAsRoot() {
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    return getuid() == 0;
#endif
    return true;
}

void RaccoonLinux::folderWriteUser() {
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    // TIMER_START(sudopath)
    QString realUser = qgetenv("SUDO_USER");
    QString sudoUid  = qgetenv("SUDO_UID");
    QString sudoGid  = qgetenv("SUDO_GID");

    if (!realUser.isEmpty()) {
        umask(0002);

        if (!sudoGid.isEmpty()) {
            setegid(sudoGid.toInt());
        }

        QProcess::execute("chown", { "-R", QString("%1:%2").arg(sudoUid, sudoGid), QDir::currentPath() });
        QProcess::execute("chmod", { "-R", "2775", QDir::currentPath() });

        QProcess::execute("find", { QDir::currentPath(), "-type", "d", "-exec", "chmod", "g+s", "{}", "+" });
    }
    // TIMER_END(sudopath)
#endif
}
