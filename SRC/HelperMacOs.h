#pragma once

#ifdef TARGET_OS_MAC
    #include <unistd.h>
    #include <QString>
    #include <QCoreApplication>
    #include <QProcess>

    #include "utils/exc_logs.h"

static QString getMacUser() {
    QString username = qgetenv("SUDO_USER");
    if (username.isEmpty()) {
        username = qgetenv("USER");
    }

    return username;
}
#endif
