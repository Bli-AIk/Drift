#pragma once

#include "playback/preview/ClipPreviewPlayer.h"

#include <QElapsedTimer>
#include <QObject>
#include <QSize>
#include <QTimer>

class AppController;

// Media-bin preview session, reached from QML as EditorState.assetPreview. Drives the phone's
// preview-and-edit page. The asset is auditioned through its own single-clip player rather than
// QtMultimedia: a VideoOutput in a secondary window paints black on Android, and this decodes
// through the same FFmpeg the timeline uses, so whatever the editor plays the preview plays.
class AssetPreviewController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool active READ active NOTIFY sessionChanged)
    Q_PROPERTY(int revision READ revision NOTIFY frameChanged)
    Q_PROPERTY(QSize frameSize READ frameSize NOTIFY frameChanged)
    Q_PROPERTY(double duration READ duration NOTIFY sessionChanged)
    Q_PROPERTY(double position READ position NOTIFY positionChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(double fps READ fps NOTIFY sessionChanged)
    Q_PROPERTY(double frameDuration READ frameDuration NOTIFY sessionChanged)
    Q_PROPERTY(int positionFrame READ positionFrame NOTIFY positionChanged)
    // JKL shuttle rate: 0 stopped, ±1/2/4/8. Plain play() and pause() report 0.
    Q_PROPERTY(int shuttleRate READ shuttleRate NOTIFY shuttleRateChanged)
    // Set by MediaPreviewWindow.qml/AndroidMediaPreview.qml while open, so the bin grid can defer
    // rebuilding its delegate array (and the scroll-position flicker that causes) until the
    // window closes rather than on every metadata change (rotate, trim, a probe landing) it emits.
    Q_PROPERTY(bool windowOpen READ windowOpen WRITE setWindowOpen NOTIFY windowOpenChanged)

public:
    explicit AssetPreviewController(AppController *app, QObject *parent = nullptr);

    bool active() const { return m_active; }
    int revision() const { return m_revision; }
    QSize frameSize() const { return m_player.frameSize(); }
    double duration() const;
    double position() const;
    bool playing() const { return m_player.isPlaying(); }
    // The asset's frame rate, or 30 where it is unknown.
    double fps() const { return m_fps; }
    double frameDuration() const { return 1.0 / m_fps; }
    int positionFrame() const;
    int shuttleRate() const { return m_shuttleRate; }
    bool windowOpen() const { return m_windowOpen; }
    void setWindowOpen(bool open);

    // begin auditions the bin row; the page owns the trim and crop values and hands them to
    // saveEdit itself.
    Q_INVOKABLE void begin(int index);
    // A timeline clip's whole source, for the crop window.
    Q_INVOKABLE void beginClip(int track, int index);
    Q_INVOKABLE void end();
    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void seek(double seconds);


    // Nearest frame boundary in seconds. Snaps to the constant-rate grid at fps(), including for
    // variable-frame-rate sources: the player does not know the decoded pts without decoding.
    Q_INVOKABLE double snapToFrame(double seconds) const;
    // Pause and land on the frame whose pts <= its start time < the next pts.
    Q_INVOKABLE void seekFrame(int frame);
    Q_INVOKABLE void stepFrames(int delta);
    // rate is one of -8, -4, -2, -1, 0, 1, 2, 4, 8; anything else is ignored. Reverse is stepped
    // backward in real time and both it and fast forward are silent.
    Q_INVOKABLE void shuttle(int rate);
    Q_INVOKABLE void shuttleForward();
    Q_INVOKABLE void shuttleReverse();
    Q_INVOKABLE void shuttleStop();
    // Live preview of a recipe: playback speed (0.25 to 4, pitch-preserved) and output gain.
    Q_INVOKABLE void setPreviewRate(double speed);
    Q_INVOKABLE void setPreviewGain(double db);

    // C++ only. AppController routes the chosen output device here.
    void setAudioDeviceId(const QByteArray &id);

signals:
    void sessionChanged();
    void frameChanged();
    void positionChanged();
    void playingChanged();
    void windowOpenChanged();
    void shuttleRateChanged();

private:
    void clearShuttle();
    void setShuttleRate(int rate);
    void startReverse(int rate);
    void onReverseTick();

    AppController *m_app = nullptr;
    // The synthetic whole-source clip the bin row is auditioned as.
    ClipPreviewPlayer m_player;
    QTimer m_reverseTimer;
    QElapsedTimer m_reverseElapsed;
    drift::TimeUs m_reverseOriginUs = 0;
    double m_fps = 30.0;
    int m_shuttleRate = 0;
    int m_index = -1;
    int m_revision = 0;
    bool m_active = false;
    bool m_windowOpen = false;
};
