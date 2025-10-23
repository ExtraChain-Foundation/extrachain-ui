#include "VoiceController.h"
#include <QMediaFormat>
#include <QFileInfo>
#include <QDir>
#include <QEventLoop>
#include <QUrl>
#include <QDebug>

// -
static inline QString mimeFromContainer(VoiceController::Container c) 
{
    return (c == VoiceController::Container::OggOpus)
           ? QStringLiteral("audio/ogg")
           : QStringLiteral("audio/wav");
}

QString VoiceController::ensureExt(const QString& path, const QString& wantedExtNoDot) 
{
    QFileInfo fi(path);
    if (fi.suffix().compare(wantedExtNoDot, Qt::CaseInsensitive) != 0) 
    {
        return fi.dir().absoluteFilePath(fi.completeBaseName() + "." + wantedExtNoDot);
    }

    return path;
}

VoiceController::VoiceController(QObject* parent)
    : QObject(parent),
      m_audioIn(new QAudioInput(this)),
      m_recorder(new QMediaRecorder(this)),
      m_player(new QMediaPlayer(this)),
      m_audioOut(new QAudioOutput(this))
{
    m_session.setAudioInput(m_audioIn.data());
    m_session.setRecorder(m_recorder.data());

    QObject::connect(m_recorder.data(), &QMediaRecorder::durationChanged, this, [this](qint64 ms){ m_lastDurationMs = ms; });

    m_player->setAudioOutput(m_audioOut.data());
}

VoiceController::~VoiceController() 
{
    if (m_recorder && m_recorder->recorderState() == QMediaRecorder::RecordingState)
        m_recorder->stop();
}

bool VoiceController::tryConfigureOggOpus() 
{
    QMediaFormat fmt;
    fmt.setFileFormat(QMediaFormat::Ogg);
    fmt.setAudioCodec(QMediaFormat::AudioCodec::Opus);

    if (!fmt.isSupported(QMediaFormat::Encode))
    {
        return false;
    }

    m_recorder->setMediaFormat(fmt);
    m_container = Container::OggOpus;

    return true;
}

bool VoiceController::tryConfigureWav() 
{
    QMediaFormat fmt;
    fmt.setFileFormat(QMediaFormat::Wave);
    fmt.setAudioCodec(QMediaFormat::AudioCodec::Wave);

    if (!fmt.isSupported(QMediaFormat::Encode))
    {
        return false;
    }
        
    m_recorder->setMediaFormat(fmt);
    m_container = Container::WavPcm;

    return true;
}

void VoiceController::finalizeOutputPathForContainer() 
{
    m_finalPath = (m_container == Container::OggOpus)
                ? ensureExt(m_requestedPath, "ogg")
                : ensureExt(m_requestedPath, "wav");
}

bool VoiceController::startRecording(const QString& suggestedPath) 
{
    // Очистка/сброс
    if (m_recorder->recorderState() == QMediaRecorder::RecordingState)
        m_recorder->stop();

    m_requestedPath   = suggestedPath;
    m_finalPath.clear();
    m_lastDurationMs  = 0;

    // 1) try OGG/Opus 
    // 2) or WAV/PCM
    if (!tryConfigureOggOpus() && !tryConfigureWav()) 
    {
        qWarning() << "[Voice] No supported audio encoding (OGG/Opus & WAV/PCM unavailable)";
        return false;
    }

    finalizeOutputPathForContainer();

    m_recorder->setAudioSampleRate(m_sampleRate);
    m_recorder->setAudioChannelCount(m_channels);
    if (m_container == Container::OggOpus)
        m_recorder->setAudioBitRate(m_bitrateBps);

    m_recorder->setOutputLocation(QUrl::fromLocalFile(m_finalPath));
    m_recorder->record();

    return true;
}

VoiceController::SaveResult VoiceController::stopAndSave(qint64 minDurationMs, qint64 maxDurationMs, qint64 maxFileBytes)
{
    SaveResult res;
    res.container = m_container;

    auto doValidate = [&]() 
    {
        QString err;
        if (!validate(&err, minDurationMs, maxDurationMs, maxFileBytes)) 
        {
            res.ok = false;
            res.error = err;
            return;
        }

        QFileInfo fi(m_finalPath);
        res.ok         = true;
        res.filePath   = m_finalPath;
        res.durationMs = (m_lastDurationMs > 0) ? m_lastDurationMs : m_recorder->duration();
        res.fileBytes  = fi.size();
    };

    if (m_recorder->recorderState() != QMediaRecorder::RecordingState) 
    {
        doValidate();
        return res;
    }

    QEventLoop loop;
    QMetaObject::Connection conn = QObject::connect(
        m_recorder.data(), &QMediaRecorder::recorderStateChanged,
        &loop, [&](QMediaRecorder::RecorderState st){
            if (st == QMediaRecorder::StoppedState)
                loop.quit();
        }
    );

    m_recorder->stop();
    loop.exec();
    QObject::disconnect(conn);

    doValidate();

    return res;
}

bool VoiceController::validate(QString* outError,
                                        qint64 minDurationMs,
                                        qint64 maxDurationMs,
                                        qint64 maxFileBytes) const
{
    QFileInfo fi(m_finalPath);
    if (!fi.exists() || fi.size() == 0) 
    {
        if (outError) *outError = QStringLiteral("Recorded file is missing or empty: %1").arg(m_finalPath);
        return false;
    }

    const qint64 dur = (m_lastDurationMs > 0) ? m_lastDurationMs : m_recorder->duration();
    if (dur < minDurationMs) 
    {
        if (outError) *outError = QStringLiteral("Voice too short: %1 ms < %2 ms").arg(dur).arg(minDurationMs);
        return false;
    }

    if (dur > maxDurationMs) 
    {
        if (outError) *outError = QStringLiteral("Voice too long: %1 ms > %2 ms").arg(dur).arg(maxDurationMs);
        return false;
    }

    if (fi.size() > maxFileBytes) 
    {
        if (outError) *outError = QStringLiteral("File too large: %1 bytes > %2 bytes").arg(fi.size()).arg(maxFileBytes);
        return false;
    }

    if (m_container == Container::OggOpus && !m_finalPath.endsWith(".ogg", Qt::CaseInsensitive)) 
    {
        if (outError) *outError = QStringLiteral("Expected .ogg, got: %1").arg(m_finalPath);
        return false;
    }

    if (m_container == Container::WavPcm && !m_finalPath.endsWith(".wav", Qt::CaseInsensitive)) 
    {
        if (outError) *outError = QStringLiteral("Expected .wav, got: %1").arg(m_finalPath);
        return false;
    }

    return true;
}

bool VoiceController::play(const QString& path, QString* errorOut) 
{
    m_player->setSource(QUrl::fromLocalFile(path));
    m_player->play();
    if (m_player->error() != QMediaPlayer::NoError) 
    {
        if (errorOut) *errorOut = m_player->errorString();
        return false;
    }

    return true;
}

bool VoiceController::playLast(QString* errorOut) 
{
    if (m_finalPath.isEmpty()) 
    {
        if (errorOut) *errorOut = QStringLiteral("No file to play");
        return false;
    }

    return play(m_finalPath, errorOut);
}

bool VoiceController::isRecording() const 
{
    return m_recorder->recorderState() == QMediaRecorder::RecordingState;
}
