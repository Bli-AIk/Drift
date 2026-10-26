#include "app/jobs/audio/ManboTts.h"

#include <QCoreApplication>
#include <QEventLoop>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>
#include <QUrl>
#include <QUrlQuery>

#include <utility>

namespace drift {
namespace {

constexpr int kLookupTimeoutMs = 90'000;
constexpr int kDownloadTimeoutMs = 180'000;
constexpr int kAttempts = 3;

struct HttpResponse
{
    QByteArray body;
    QString error;
};

HttpResponse get(QNetworkAccessManager &nam, const QUrl &url, int timeoutMs)
{
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("Drift/1.0"));

    QNetworkReply *reply = nam.get(request);

    QEventLoop loop;
    QTimer timer;
    timer.setSingleShot(true);
    QObject::connect(&timer, &QTimer::timeout, &loop, [&reply, &loop]() {
        if (!reply->isFinished())
            reply->abort();
        loop.quit();
    });
    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    timer.start(timeoutMs);
    loop.exec();

    HttpResponse out;
    out.body = reply->readAll();
    if (reply->error() != QNetworkReply::NoError)
        out.error = reply->errorString();
    reply->deleteLater();
    return out;
}

bool isTerminalPunctuation(QChar c)
{
    return c == QChar(0x3002) // 。
        || c == QChar(0xFF01) // ！
        || c == QChar(0xFF1F) // ？
        || c == QChar(0x2026) // …
        || c == QLatin1Char('.')
        || c == QLatin1Char('!')
        || c == QLatin1Char('?');
}

bool isClausePunctuation(QChar c)
{
    return c == QChar(0xFF0C) // ，
        || c == QChar(0x3001) // 、
        || c == QChar(0xFF1A) // ：
        || c == QChar(0xFF1B) // ；
        || c == QLatin1Char(',')
        || c == QLatin1Char(':')
        || c == QLatin1Char(';');
}

int lastCutAt(const QString &text, int cap, bool (*predicate)(QChar))
{
    for (int i = cap; i > 0; --i) {
        if (predicate(text.at(i - 1)))
            return i;
    }
    return -1;
}

} // namespace

QString ManboTts::endpoint()
{
    return QStringLiteral("https://api.milorapart.top/apis/mbAIsc");
}

QStringList ManboTts::segmentsFor(const QString &text)
{
    QStringList out;
    QString rest = text.trimmed();
    while (!rest.isEmpty()) {
        if (rest.size() <= kMaxCharsPerRequest) {
            out.append(rest);
            break;
        }
        int cut = lastCutAt(rest, kMaxCharsPerRequest, &isTerminalPunctuation);
        if (cut <= 0)
            cut = lastCutAt(rest, kMaxCharsPerRequest, &isClausePunctuation);
        if (cut <= 0)
            cut = kMaxCharsPerRequest;
        const QString piece = rest.left(cut).trimmed();
        if (!piece.isEmpty())
            out.append(piece);
        rest = rest.mid(cut).trimmed();
    }
    return out;
}

ManboTts::Result ManboTts::synthesize(const QString &text, const QString &outPath,
                                      const Progress &progress)
{
    Result result;
    const QString script = text.trimmed();
    if (script.isEmpty()) {
        result.error = QCoreApplication::translate("ManboTts", "Nothing to speak");
        return result;
    }

    const QStringList parts = segmentsFor(script);
    result.segments = static_cast<int>(parts.size());
    result.characters = static_cast<int>(script.size());
    if (parts.size() > 1) {
        // Joining mp3 chunks needs a muxer and a single caption line never needs
        // more than one request; refuse rather than ship broken audio.
        result.error = QCoreApplication::translate(
                           "ManboTts",
                           "This line is %1 characters; manbo accepts at most %2 per request. "
                           "Split it into shorter captions first.")
                           .arg(script.size())
                           .arg(kMaxCharsPerRequest);
        return result;
    }

    QNetworkAccessManager nam;
    QString lastError;

    for (int attempt = 1; attempt <= kAttempts; ++attempt) {
        if (progress && !progress(attempt == 1 ? 0.1 : 0.1))
            return result;

        QUrl url(endpoint());
        QUrlQuery query;
        query.addQueryItem(QStringLiteral("text"), script);
        url.setQuery(query);

        const HttpResponse lookup = get(nam, url, kLookupTimeoutMs);
        if (!lookup.error.isEmpty()) {
            lastError = lookup.error;
            continue;
        }

        QJsonParseError parseError{};
        const QJsonDocument doc = QJsonDocument::fromJson(lookup.body, &parseError);
        if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
            lastError = QCoreApplication::translate("ManboTts", "Unexpected response from the voice service");
            continue;
        }

        const QJsonObject object = doc.object();
        const QJsonValue code = object.value(QStringLiteral("code"));
        const int status = code.isString() ? code.toString().toInt() : code.toInt();
        if (status != 200) {
            // The endpoint reports over-length and quota failures through `msg`,
            // and repeating the same request cannot fix either of them.
            const QString message = object.value(QStringLiteral("msg")).toString();
            result.error = message.isEmpty()
                ? QCoreApplication::translate("ManboTts", "The voice service refused the line")
                : message;
            return result;
        }

        const QString mp3 = object.value(QStringLiteral("url")).toString();
        if (mp3.isEmpty()) {
            lastError = QCoreApplication::translate("ManboTts", "The voice service returned no audio");
            continue;
        }

        if (progress && !progress(0.6))
            return result;

        const HttpResponse audio = get(nam, QUrl(mp3), kDownloadTimeoutMs);
        if (!audio.error.isEmpty()) {
            lastError = audio.error;
            continue;
        }
        if (audio.body.isEmpty()) {
            lastError = QCoreApplication::translate("ManboTts", "The downloaded audio was empty");
            continue;
        }

        QFile file(outPath);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            result.error = QCoreApplication::translate("ManboTts", "Could not write the voice file");
            return result;
        }
        const qint64 written = file.write(audio.body);
        file.close();
        if (written != audio.body.size()) {
            result.error = QCoreApplication::translate("ManboTts", "Could not write the voice file");
            return result;
        }

        if (progress && !progress(1.0))
            return result;
        result.path = outPath;
        return result;
    }

    result.error = lastError.isEmpty()
        ? QCoreApplication::translate("ManboTts", "Could not reach the voice service")
        : lastError;
    return result;
}

} // namespace drift
