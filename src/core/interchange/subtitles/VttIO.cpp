#include "core/interchange/subtitles/VttIO.h"

#include "core/base/Time.h"

#include <QCoreApplication>
#include <QFile>
#include <QRegularExpression>
#include <QStringList>

#include <utility>

namespace drift {
namespace {

QString formatVttTimestamp(TimeUs us)
{
    if (us < 0)
        us = 0;
    const qint64 totalMs = us / kUsPerMs;
    const qint64 hours = totalMs / 3'600'000;
    const qint64 minutes = (totalMs / 60'000) % 60;
    const qint64 seconds = (totalMs / 1'000) % 60;
    const qint64 millis = totalMs % 1'000;
    return QStringLiteral("%1:%2:%3.%4")
        .arg(hours, 2, 10, QLatin1Char('0'))
        .arg(minutes, 2, 10, QLatin1Char('0'))
        .arg(seconds, 2, 10, QLatin1Char('0'))
        .arg(millis, 3, 10, QLatin1Char('0'));
}

bool parseVttTimestamp(QStringView token, TimeUs *outUs)
{
    static const QRegularExpression re(
        QStringLiteral(R"(^(?:(\d+):)?(\d{2}):(\d{2})\.(\d{1,3})$)"));
    const auto match = re.matchView(token);
    if (!match.hasMatch())
        return false;

    const qint64 hours = match.captured(1).toLongLong();
    const qint64 minutes = match.captured(2).toLongLong();
    const qint64 seconds = match.captured(3).toLongLong();
    QString msStr = match.captured(4);
    while (msStr.size() < 3)
        msStr.append(QLatin1Char('0'));
    const qint64 millis = msStr.left(3).toLongLong();
    if (minutes >= 60 || seconds >= 60)
        return false;

    *outUs = ((hours * 3600 + minutes * 60 + seconds) * kUsPerSecond) + (millis * kUsPerMs);
    return true;
}

const QRegularExpression &vttTimingRegex()
{
    static const QRegularExpression re(QStringLiteral(R"(^\s*(\S+)\s*-->\s*(\S+)(?:\s.*)?$)"));
    return re;
}

QString normalizeNewlines(QString text)
{
    text.replace(QLatin1String("\r\n"), QLatin1String("\n"));
    text.replace(QLatin1Char('\r'), QLatin1Char('\n'));
    if (text.startsWith(QChar(0xFEFF)))
        text.remove(0, 1);
    return text;
}

void appendVttCue(const QStringList &lines, int firstLine, SubtitleParseResult *result)
{
    const int timingLine = lines.first().contains(QLatin1String("-->")) ? 0 : 1;
    if (timingLine >= lines.size()) {
        result->errors.append({firstLine, QCoreApplication::translate("VttIO", "Invalid subtitle timing line")});
        return;
    }

    const auto match = vttTimingRegex().match(lines.at(timingLine).trimmed());
    if (!match.hasMatch()) {
        result->errors.append({firstLine, QCoreApplication::translate("VttIO", "Invalid subtitle timing line")});
        return;
    }

    TimeUs startUs = 0;
    TimeUs endUs = 0;
    if (!parseVttTimestamp(match.capturedView(1), &startUs)
        || !parseVttTimestamp(match.capturedView(2), &endUs)) {
        result->errors.append({firstLine, QCoreApplication::translate("VttIO", "Invalid subtitle timestamp")});
        return;
    }
    if (endUs < startUs) {
        result->errors.append({firstLine, QCoreApplication::translate("VttIO", "Subtitle ends before it starts")});
        return;
    }

    const QStringList body = lines.mid(timingLine + 1);
    if (body.isEmpty()) {
        result->errors.append({firstLine, QCoreApplication::translate("VttIO", "Subtitle cue has no text")});
        return;
    }

    SubtitleCue cue;
    cue.startUs = startUs;
    cue.endUs = endUs;
    cue.text = body.join(QLatin1Char('\n'));
    result->cues.append(cue);
}

} // namespace

bool parseVtt(const QString &content, QList<SubtitleCue> *outCues, QString *error)
{
    if (!outCues) {
        if (error)
            *error = QCoreApplication::translate("VttIO", "Missing output");
        return false;
    }

    if (normalizeNewlines(content).trimmed().isEmpty()) {
        if (error)
            *error = QCoreApplication::translate("VttIO", "Subtitle file is empty");
        return false;
    }

    SubtitleParseResult result = parseVttDetailed(content);
    if (!result.errors.isEmpty()) {
        if (error)
            *error = result.errors.first().message;
        return false;
    }
    if (result.cues.isEmpty()) {
        if (error)
            *error = QCoreApplication::translate("VttIO", "No subtitle cues found");
        return false;
    }

    *outCues = std::move(result.cues);
    return true;
}

bool parseVttFile(const QString &path, QList<SubtitleCue> *outCues, QString *error)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        if (error)
            *error = QCoreApplication::translate("VttIO", "Could not open subtitle file");
        return false;
    }

    const QByteArray bytes = file.readAll();
    // Prefer UTF-8 (with or without BOM); fall back to Latin-1 for older files.
    QString content = QString::fromUtf8(bytes);
    if (content.contains(QChar::ReplacementCharacter))
        content = QString::fromLatin1(bytes);
    return parseVtt(content, outCues, error);
}

QString writeVtt(const QList<SubtitleCue> &cues)
{
    QList<SubtitleCue> sorted = cues;
    sortSubtitleCues(sorted);

    QString out = QStringLiteral("WEBVTT\n\n");
    for (const SubtitleCue &cue : sorted) {
        if (cue.endUs <= cue.startUs && cue.text.trimmed().isEmpty())
            continue;
        TimeUs endUs = cue.endUs;
        if (endUs <= cue.startUs)
            endUs = cue.startUs + kUsPerMs;

        out += formatVttTimestamp(cue.startUs);
        out += QStringLiteral(" --> ");
        out += formatVttTimestamp(endUs);
        out += QLatin1Char('\n');
        out += cue.text;
        out += QStringLiteral("\n\n");
    }
    return out;
}

bool writeVttFile(const QString &path, const QList<SubtitleCue> &cues, QString *error)
{
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        if (error)
            *error = QCoreApplication::translate("VttIO", "Could not write subtitle file");
        return false;
    }

    const QByteArray bytes = writeVtt(cues).toUtf8();
    if (file.write(bytes) != bytes.size()) {
        if (error)
            *error = QCoreApplication::translate("VttIO", "Could not write subtitle file");
        return false;
    }
    return true;
}

SubtitleParseResult parseVttDetailed(const QString &content)
{
    static const QRegularExpression headerRe(QStringLiteral(R"(^WEBVTT(?:[ \t].*)?$)"));
    static const QRegularExpression skippedBlockRe(QStringLiteral(R"(^(?:NOTE|STYLE|REGION)(?:[ \t].*)?$)"));

    SubtitleParseResult result;
    const QStringList lines = normalizeNewlines(content).split(QLatin1Char('\n'));
    bool headerChecked = false;
    int i = 0;
    while (i < lines.size()) {
        if (lines.at(i).trimmed().isEmpty()) {
            ++i;
            continue;
        }
        const int firstLine = i + 1;
        QStringList block;
        while (i < lines.size() && !lines.at(i).trimmed().isEmpty())
            block.append(lines.at(i++));

        if (!headerChecked) {
            headerChecked = true;
            if (headerRe.match(block.first()).hasMatch())
                continue;
            result.errors.append({1, QCoreApplication::translate("VttIO", "Missing WEBVTT header")});
        }
        if (skippedBlockRe.match(block.first()).hasMatch())
            continue;
        appendVttCue(block, firstLine, &result);
    }
    sortSubtitleCues(result.cues);
    return result;
}

} // namespace drift
