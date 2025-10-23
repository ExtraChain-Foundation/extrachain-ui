#pragma once

#include <QObject>
#include <QString>
#include <QMediaCaptureSession>
#include <QAudioInput>
#include <QMediaRecorder>
#include <QMediaPlayer>
#include <QAudioOutput>

class VoiceController : public QObject 
{
public:
    enum class Container { OggOpus, WavPcm };

    struct SaveResult 
    {
        bool     ok = false;
        QString  filePath;
        QString  error;
        qint64   durationMs = 0;
        qint64   fileBytes  = 0;
        Container container = Container::OggOpus;
    };

    explicit VoiceController(QObject* parent = nullptr);
    ~VoiceController() override;

    // return false, if backand cant play OGG/Opus or WAV/PCM.
    bool startRecording(const QString& suggestedPath);

    // By default: >= 300 ms, <= 5 min, <= 5 MB.
    SaveResult stopAndSave(qint64 minDurationMs = 300,
                           qint64 maxDurationMs = 5*60*1000,
                           qint64 maxFileBytes  = 5ll*1024*1024);

    bool play(const QString& path, QString* errorOut = nullptr);
    bool playLast(QString* errorOut = nullptr);

    // record settings
    void setSampleRate(int hz)   { m_sampleRate = hz; }
    void setChannels(int ch)     { m_channels   = ch; }
    void setOpusBitrate(int bps) { m_bitrateBps = bps; } // for OGG/Opus

    // States
    bool       isRecording()   const;
    QString    lastFilePath()  const { return m_finalPath; }
    qint64     lastDurationMs() const { return m_lastDurationMs; }
    Container  containerUsed() const { return m_container; }

private:
    // Format configuring
    bool tryConfigureOggOpus();
    bool tryConfigureWav();
    void finalizeOutputPathForContainer();
    static QString ensureExt(const QString& path, const QString& wantedExtNoDot);

    // validate after recording
    bool validate(QString* outError,
                  qint64 minDurationMs,
                  qint64 maxDurationMs,
                  qint64 maxFileBytes) const;

private:
    QMediaCaptureSession          m_session;
    QScopedPointer<QAudioInput>   m_audioIn;
    QScopedPointer<QMediaRecorder> m_recorder;

    QScopedPointer<QMediaPlayer>  m_player;
    QScopedPointer<QAudioOutput>  m_audioOut;

    // recording settings
    int m_sampleRate = 48000;
    int m_channels   = 1;
    int m_bitrateBps = 20000; // ~20 kbps (only for OGG/Opus)

    // current state
    QString   m_requestedPath;
    QString   m_finalPath;
    qint64    m_lastDurationMs = 0;
    Container m_container      = Container::OggOpus;
};
