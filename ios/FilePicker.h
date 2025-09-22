#pragma once
#include <QObject>

class RaccoonFilePicker : public QObject {
    Q_OBJECT
public:
    explicit RaccoonFilePicker(QObject *parent = nullptr);

public slots:
    void pickFolderAndSaveFile(const QString &fileName, const QString &content);
    void pickProfileFile();
    void pickAnyFile();
    void exportFile(const QString &filePath);

signals:
    void filePicked(const QString pathFile, const QString &dataFile);
    void selectedFile(const QString pathFile);
    void copied();
    void error(const QString &message);
    void profileExported();
};
