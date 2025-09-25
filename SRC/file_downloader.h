#include <QObject>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QFile>

class FileDownloader : public QObject {
    Q_OBJECT

public:
    explicit FileDownloader(QObject *parent = nullptr)
        : QObject(parent) {
        connect(&manager, &QNetworkAccessManager::finished, this, &FileDownloader::downloadFinished);
    }

    void downloadFile(const QString &url, const QString &saveFilePath) {
        QUrl            fileUrl(url);
        QNetworkRequest request(fileUrl);

        outputFile = new QFile(saveFilePath);
        if (!outputFile->open(QIODevice::WriteOnly)) {
            emit error(tr("Can't create file"));
            delete outputFile;
            outputFile = nullptr;
            return;
        }

        QNetworkReply *reply = manager.get(request);

        connect(reply, &QNetworkReply::downloadProgress, this, &FileDownloader::downloadProgress);
        connect(reply, &QNetworkReply::errorOccurred, this, &FileDownloader::handleError);
        connect(reply, &QNetworkReply::readyRead, this, &FileDownloader::handleReadyRead);
    }

signals:
    void downloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void downloadComplete();
    void error(const QString &errorString);

private slots:
    void downloadFinished(QNetworkReply *reply) {
        if (reply->error() == QNetworkReply::NoError) {
            if (reply->bytesAvailable() > 0) {
                outputFile->write(reply->readAll());
            }

            outputFile->close();
            emit downloadComplete();
        }

        delete outputFile;
        outputFile = nullptr;
        reply->deleteLater();
    }

    void handleReadyRead() {
        QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
        if (reply && outputFile) {
            outputFile->write(reply->readAll());
        }
    }

    void handleError(QNetworkReply::NetworkError code) {
        QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
        if (reply) {
            emit error(reply->errorString());
        }
    }

private:
    QNetworkAccessManager manager;
    QFile                *outputFile = nullptr;
};
