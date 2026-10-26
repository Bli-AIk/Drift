#pragma once

#include <QString>
#include <QStringList>

#include <functional>

namespace drift {

// Remote "manbo" voice: the milorapart public endpoint takes plain text on the
// query string and answers with a JSON body carrying a direct mp3 link, which is
// then downloaded. There is no API key and no streaming.
//
// Blocking on purpose: this only ever runs on a JobRegistry worker lane, never on
// the UI thread. The request cap is the endpoint's own — 299 characters per call,
// above which it answers with a 字数超限 error instead of audio.
class ManboTts
{
public:
    // Returns false to request cancellation.
    using Progress = std::function<bool(double fraction)>;

    struct Result
    {
        QString path;   // mp3 written to disk; empty when the call failed
        QString error;
        int segments = 0;
        int characters = 0;
    };

    static constexpr int kMaxCharsPerRequest = 280;

    static QString endpoint();

    // Splits on Chinese sentence punctuation first, then on commas, and finally
    // hard-cuts, so no single request exceeds kMaxCharsPerRequest.
    static QStringList segmentsFor(const QString &text);

    // Writes an mp3 to outPath. Multi-segment input is refused rather than
    // stitched: joining mp3s needs a real muxer and a single caption line never
    // needs more than one request.
    Result synthesize(const QString &text, const QString &outPath, const Progress &progress);
};

} // namespace drift
