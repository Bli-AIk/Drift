#include "engine/ml/speech/DenoiseAudio.h"

#include "engine/decode/readers/ClipReaderPool.h"
#include "engine/encode/writers/AudioFileWriter.h"
#include "engine/ml/speech/DeepFilterDenoiser.h"

#include <QCoreApplication>

#include <algorithm>
#include <vector>

namespace drift {

namespace {

constexpr quint64 kDenoiseScanStreamId = 0xA5'11'5C'A4'00'00'00'02ull;

// Same context as the strings had in DenoiseController, so their translations carry over.
QString trDenoise(const char *text)
{
    return QCoreApplication::translate("DenoiseController", text);
}

} // namespace

bool denoiseAudioRange(const QString &input, TimeUs inUs, TimeUs outUs, const QString &outputFlac,
                       QString *error, const std::function<bool(double)> &onProgress,
                       const QString &originalFlac)
{
    const auto fail = [&](const QString &message) {
        if (error)
            *error = message;
        return false;
    };
    bool cancelled = false;
    const auto report = [&](double fraction) {
        if (onProgress && !onProgress(std::clamp(fraction, 0.0, 1.0)))
            cancelled = true;
        return !cancelled;
    };
    const QString cancelMessage = trDenoise("Noise removal cancelled");

    DeepFilterDenoiser &dn = DeepFilterDenoiser::instance();
    if (!report(0.0))
        return fail(cancelMessage);
    if (!dn.available())
        return fail(dn.lastError());

    const int rate = DeepFilterDenoiser::sampleRate();
    const int64_t totalFrames = ((outUs - inUs) * rate) / kUsPerSecond;
    if (totalFrames <= 0)
        return fail(trDenoise("Clip is too short to process"));

    if (!report(0.05))
        return fail(cancelMessage);
    std::vector<float> interleaved(size_t(totalFrames) * 2, 0.0f);
    int64_t have = 0;
    const int chunkFrames = rate * 10;
    while (have < totalFrames) {
        const TimeUs at = inUs + TimeUs((have * kUsPerSecond) / rate);
        const int want = int(std::min<int64_t>(chunkFrames, totalFrames - have));
        const int got = ClipReaderPool::instance().readAudioInterleaved(
            input, kDenoiseScanStreamId, at, want, rate, interleaved.data() + size_t(have) * 2);
        if (got <= 0)
            break;
        have += got;
        if (!report(0.05 + 0.20 * double(have) / double(totalFrames)))
            return fail(cancelMessage);
    }
    if (have <= 0)
        return fail(trDenoise("No audio decoded"));
    interleaved.resize(size_t(have) * 2);

    // Written before the model runs so a cancel still leaves nothing half-made.
    if (!originalFlac.isEmpty()) {
        AudioFileWriter orig;
        QString writeError;
        if (!orig.open(originalFlac, rate, 2, &writeError))
            return fail(writeError);
        if (!orig.writeFrames(interleaved.data(), int(have), &writeError)
            || !orig.finish(&writeError)) {
            orig.abort();
            return fail(writeError);
        }
    }

    // The model is mono, so each channel goes through separately and the stereo image is kept.
    std::vector<float> mono(size_t(have), 0.0f);
    for (int ch = 0; ch < 2; ++ch) {
        for (int64_t i = 0; i < have; ++i)
            mono[size_t(i)] = interleaved[size_t(i) * 2 + ch];

        const double base = 0.25 + 0.35 * ch;
        const std::vector<float> clean =
            dn.denoise(mono, [&](double f) { return report(base + 0.35 * f); });
        if (clean.empty())
            return fail(cancelled ? cancelMessage : dn.lastError());
        for (int64_t i = 0; i < have; ++i)
            interleaved[size_t(i) * 2 + ch] = clean[size_t(i)];
    }

    if (!report(0.95))
        return fail(cancelMessage);
    AudioFileWriter writer;
    QString writeError;
    if (!writer.open(outputFlac, rate, 2, &writeError))
        return fail(writeError);
    if (!writer.writeFrames(interleaved.data(), int(have), &writeError)
        || !writer.finish(&writeError)) {
        writer.abort();
        return fail(writeError);
    }

    report(1.0);
    return true;
}

} // namespace drift
