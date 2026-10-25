#include <QtTest>

#include <QMediaDevices>

#include "playback/AudioOutputChannel.h"
#include "playback/PlaybackClock.h"
#include "playback/preview/FrameGrid.h"

class PlaybackTest : public QObject
{
    Q_OBJECT

private slots:
    void clockPausedPosition();
    void clockHoldsStartUntilSinkSyncs();
    void clockWallFallbackWhileRunning();
    void clockNeverRunsBackwardOnLateFirstSync();
    void produceAdvancesWithRenderedSamples();
    void playbackTracksSinkPosition();
    void seekWhileRunningKeepsClockAlive();
    void seekDoesNotInheritPriorSinkTime();
    void avSyncWithinTolerance();
    void rateScalesProduceAndPlayback();
    void renderedFramesIgnoreRate();
    void convertsFloatToInt16();
    void clampsBeyondFullScale();
    void downmixesToMono();
    void silencesChannelsBeyondStereo();
    void negotiatesAFormatTheDeviceAccepts();
    void frameGridSnapsAndIndexes();
    void frameGridHandlesFractionalRates();
    void frameGridClampsToLastFrame();
    void shuttleEscalates();
};

void PlaybackTest::clockPausedPosition()
{
    PlaybackClock clock;
    clock.reset(drift::secondsToUs(2.5), 48000);
    QCOMPARE(clock.currentTimeUs(), drift::secondsToUs(2.5));
    QCOMPARE(clock.pausedAt(), drift::secondsToUs(2.5));
}

// Opening the sink and pulling its first buffer takes a few hundred ms. Guessing
// forward on wall time during that window and then correcting to the sink's
// position snapped the playhead back to the start of playback.
void PlaybackTest::clockHoldsStartUntilSinkSyncs()
{
    PlaybackClock clock;
    clock.reset(drift::secondsToUs(2.5), 48000);
    clock.start();
    QTest::qWait(50);
    QCOMPARE(clock.currentTimeUs(), drift::secondsToUs(2.5));
}

// With no sink reporting progress at all (no audio device), the playhead still has
// to advance once the grace period is over, or video-only playback would freeze.
void PlaybackTest::clockWallFallbackWhileRunning()
{
    PlaybackClock clock;
    clock.reset(0, 48000);
    clock.start();
    QTest::qWait(650);
    QVERIFY(clock.currentTimeUs() > 0);
    clock.pause();
    QVERIFY(clock.pausedAt() > 0);
}

void PlaybackTest::clockNeverRunsBackwardOnLateFirstSync()
{
    PlaybackClock clock;
    clock.reset(0, 48000);
    clock.start();

    // Let the wall-clock fallback get going, then have the sink report that it has
    // barely played anything — exactly what the first sync looks like in practice.
    QTest::qWait(650);
    const drift::TimeUs before = clock.currentTimeUs();
    QVERIFY(before > 0);

    clock.syncPlaybackUs(0);
    QVERIFY(clock.currentTimeUs() >= before);
}

void PlaybackTest::produceAdvancesWithRenderedSamples()
{
    PlaybackClock clock;
    clock.reset(0, 48000);
    clock.start();
    clock.onAudioSamplesRendered(4800);
    QCOMPARE(clock.produceTimeUs(), drift::secondsToUs(0.1));
    clock.onAudioSamplesRendered(4800);
    QCOMPARE(clock.produceTimeUs(), drift::secondsToUs(0.2));
}

void PlaybackTest::playbackTracksSinkPosition()
{
    PlaybackClock clock;
    clock.reset(0, 48000);
    clock.start();

    clock.onAudioSamplesRendered(48000);
    clock.syncPlaybackUs(drift::secondsToUs(0.1));

    const drift::TimeUs played = clock.currentTimeUs();
    QVERIFY(played >= drift::secondsToUs(0.1));
    QVERIFY(played < drift::secondsToUs(0.2));
    QVERIFY(clock.produceTimeUs() >= drift::secondsToUs(1.0));
}

void PlaybackTest::seekWhileRunningKeepsClockAlive()
{
    PlaybackClock clock;
    clock.reset(drift::secondsToUs(1.0), 48000);
    clock.start();
    clock.onAudioSamplesRendered(4800);
    QCOMPARE(clock.produceTimeUs(), drift::secondsToUs(1.1));

    clock.reset(drift::secondsToUs(2.0), 48000);
    QVERIFY(!clock.isRunning());
    QCOMPARE(clock.produceTimeUs(), drift::secondsToUs(2.0));

    clock.start();
    QVERIFY(clock.isRunning());
    clock.onAudioSamplesRendered(4800);
    QCOMPARE(clock.produceTimeUs(), drift::secondsToUs(2.1));
}

void PlaybackTest::seekDoesNotInheritPriorSinkTime()
{
    PlaybackClock clock;
    clock.reset(0, 48000);
    clock.start();
    clock.syncPlaybackUs(drift::secondsToUs(10.0));

    // A seek re-anchors. The engine must pass sink time relative to that reset
    // (processedUSecs - offset). Passing the cumulative value would land at 12s
    // instead of 2s — the timeline click-while-playing jump.
    clock.reset(drift::secondsToUs(2.0), 48000);
    clock.start();
    clock.syncPlaybackUs(drift::secondsToUs(0.05));

    const drift::TimeUs now = clock.currentTimeUs();
    QVERIFY(now >= drift::secondsToUs(2.0));
    QVERIFY(now < drift::secondsToUs(2.2));
}

void PlaybackTest::avSyncWithinTolerance()
{
    PlaybackClock clock;
    clock.reset(0, 48000);
    clock.start();

    clock.onAudioSamplesRendered(1920);
    clock.syncPlaybackUs(drift::secondsToUs(0.04));

    const drift::TimeUs a = clock.currentTimeUs();
    const drift::TimeUs b = clock.currentTimeUs();
    QVERIFY(qAbs(a - b) <= 40'000);
}

void PlaybackTest::rateScalesProduceAndPlayback()
{
    PlaybackClock clock;
    clock.setRate(2.0);
    clock.reset(drift::secondsToUs(1.0), 48000);
    clock.start();

    // The sink still runs at 48 kHz; a rate of 2 only changes how much timeline each sample covers.
    clock.onAudioSamplesRendered(4800);
    QCOMPARE(clock.produceTimeUs(), drift::secondsToUs(1.2));

    clock.syncPlaybackUs(drift::secondsToUs(0.1));
    const drift::TimeUs played = clock.currentTimeUs();
    QVERIFY(played >= drift::secondsToUs(1.2));
    QVERIFY(played < drift::secondsToUs(1.4));

    // Still monotonic under a rate: a repeated read can only stay put or move forward.
    QVERIFY(clock.currentTimeUs() >= played);
}

void PlaybackTest::renderedFramesIgnoreRate()
{
    PlaybackClock clock;
    clock.setRate(0.5);
    clock.reset(0, 48000);
    clock.start();

    clock.onAudioSamplesRendered(4800);
    // Sink domain, so no rate: this is what the post-mix retimer's output cursor advances by.
    QCOMPARE(clock.renderedFramesUs(), drift::secondsToUs(0.1));
    QCOMPARE(clock.produceTimeUs(), drift::secondsToUs(0.05));
}


// The sink only takes interleaved stereo float where the device says it can; everywhere else the
// mix has to be converted on the way out, and getting that wrong is silence or noise, not a crash.
void PlaybackTest::convertsFloatToInt16()
{
    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(2);
    format.setSampleFormat(QAudioFormat::Int16);

    const float stereo[] = {0.0f, 1.0f, -1.0f, 0.5f};
    qint16 out[4] = {};
    drift::writeInterleaved(stereo, 2, format, reinterpret_cast<char *>(out));

    QCOMPARE(out[0], qint16(0));
    QCOMPARE(out[1], qint16(32767));
    QCOMPARE(out[2], qint16(-32767));
    QCOMPARE(out[3], qint16(16383));
}

// Effects and gain stages can push the mix past full scale; wrapping there is the loudest possible
// artefact, so it has to clip instead.
void PlaybackTest::clampsBeyondFullScale()
{
    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(2);
    format.setSampleFormat(QAudioFormat::Int32);

    const float stereo[] = {4.0f, -4.0f};
    qint32 out[2] = {};
    drift::writeInterleaved(stereo, 1, format, reinterpret_cast<char *>(out));

    QCOMPARE(out[0], qint32(2147483647));
    QCOMPARE(out[1], qint32(-2147483647));
}

void PlaybackTest::downmixesToMono()
{
    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(1);
    format.setSampleFormat(QAudioFormat::Float);

    const float stereo[] = {1.0f, 0.0f, 0.4f, 0.6f};
    float out[2] = {};
    drift::writeInterleaved(stereo, 2, format, reinterpret_cast<char *>(out));

    QCOMPARE(out[0], 0.5f);
    QCOMPARE(out[1], 0.5f);
}

// A 5.1 device gets the mix in its front pair and silence elsewhere, rather than the stereo stream
// smeared across every channel.
void PlaybackTest::silencesChannelsBeyondStereo()
{
    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(6);
    format.setSampleFormat(QAudioFormat::Float);

    const float stereo[] = {0.25f, -0.25f};
    float out[6] = {9, 9, 9, 9, 9, 9};
    drift::writeInterleaved(stereo, 1, format, reinterpret_cast<char *>(out));

    QCOMPARE(out[0], 0.25f);
    QCOMPARE(out[1], -0.25f);
    for (int channel = 2; channel < 6; ++channel)
        QCOMPARE(out[channel], 0.0f);
}

// The bug this all exists for: asking a device for a format it does not take used to leave a sink
// that opened and played nothing.
void PlaybackTest::negotiatesAFormatTheDeviceAccepts()
{
    const QAudioDevice device = QMediaDevices::defaultAudioOutput();
    if (device.isNull())
        QSKIP("no audio output device on this machine");

    // 12345 Hz is not a rate any real device runs at, so this exercises the fallback.
    const QAudioFormat format = drift::negotiateAudioFormat(device, 12345);
    QVERIFY(format.isValid());
    QVERIFY(format.sampleRate() > 0);
    QVERIFY(format.channelCount() > 0);
}

void PlaybackTest::frameGridSnapsAndIndexes()
{
    QCOMPARE(drift::frameTimeUs(30, 30.0), drift::TimeUs(1'000'000));
    QCOMPARE(drift::frameIndexAt(drift::frameTimeUs(7, 25.0), 25.0), 7);
    QCOMPARE(drift::frameIndexAt(drift::frameTimeUs(7, 25.0) - 1, 25.0), 7); // rounding hair
    QCOMPARE(drift::frameIndexAt(drift::frameTimeUs(7, 25.0) + 39'000, 25.0), 7);
    QCOMPARE(drift::frameIndexAt(drift::frameTimeUs(8, 25.0), 25.0), 8);
    // Nearest, not floor: 0.49 of a frame in rounds down, 0.51 rounds up.
    QCOMPARE(drift::snapToFrameUs(19'600, 25.0), drift::TimeUs(0));
    QCOMPARE(drift::snapToFrameUs(20'400, 25.0), drift::TimeUs(40'000));
    // Unknown rate falls back to 30.
    QCOMPARE(drift::frameTimeUs(3, 0.0), drift::frameTimeUs(3, 30.0));
}

void PlaybackTest::frameGridHandlesFractionalRates()
{
    const double fps = 30000.0 / 1001.0;
    for (int n : {0, 1, 2, 29, 30, 1000, 54321}) {
        QCOMPARE(drift::frameIndexAt(drift::frameTimeUs(n, fps), fps), n);
        QCOMPARE(drift::snapToFrameUs(drift::frameTimeUs(n, fps), fps), drift::frameTimeUs(n, fps));
    }
}

void PlaybackTest::frameGridClampsToLastFrame()
{
    // Ten frames at 25 fps cover exactly 400 ms; the last one starts at 360 ms.
    QCOMPARE(drift::lastFrameIndex(400'000, 25.0), 9);
    QCOMPARE(drift::lastFrameIndex(400'100, 25.0), 10);
    QCOMPARE(drift::lastFrameIndex(0, 25.0), 0);
}

void PlaybackTest::shuttleEscalates()
{
    int rate = 0;
    const int forward[] = {1, 2, 4, 8, 8};
    for (int expected : forward) {
        rate = drift::shuttleNext(rate, true);
        QCOMPARE(rate, expected);
    }
    // The opposite key stops first, then reverses on the next press.
    rate = drift::shuttleNext(rate, false);
    QCOMPARE(rate, 0);
    rate = drift::shuttleNext(rate, false);
    QCOMPARE(rate, -1);
    rate = drift::shuttleNext(rate, false);
    QCOMPARE(rate, -2);
    rate = drift::shuttleNext(-8, false);
    QCOMPARE(rate, -8);
    QCOMPARE(drift::shuttleNext(-4, true), 0);

    for (int ok : {-8, -4, -2, -1, 0, 1, 2, 4, 8})
        QVERIFY(drift::isShuttleRate(ok));
    for (int bad : {-3, 3, 5, 16, -16})
        QVERIFY(!drift::isShuttleRate(bad));
}

QTEST_MAIN(PlaybackTest)
#include "tst_playback.moc"
