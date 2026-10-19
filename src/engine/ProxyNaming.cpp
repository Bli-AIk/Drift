#include "engine/ProxyNaming.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>

#include <algorithm>

namespace drift {

QString proxyRuleToString(const ProxyNameRule &rule)
{
    QString text;
    if (!rule.subdir.isEmpty())
        text += rule.subdir + QLatin1Char('/');
    text += rule.prefix + QLatin1Char('*') + rule.suffix;
    if (!rule.ext.isEmpty())
        text += QLatin1Char('.') + rule.ext;
    return text;
}

std::optional<ProxyNameRule> proxyRuleFromString(const QString &text)
{
    const QString trimmed = text.trimmed();
    const qsizetype slash = trimmed.lastIndexOf(QLatin1Char('/'));
    const QString subdir = slash < 0 ? QString() : trimmed.left(slash);
    const QString name = slash < 0 ? trimmed : trimmed.mid(slash + 1);

    if (name.count(QLatin1Char('*')) != 1 || subdir.contains(QLatin1Char('*')))
        return std::nullopt;
    if (subdir.startsWith(QLatin1Char('/')) || subdir.split(QLatin1Char('/')).contains(QStringLiteral("..")))
        return std::nullopt;

    const qsizetype star = name.indexOf(QLatin1Char('*'));
    ProxyNameRule rule;
    rule.subdir = subdir;
    rule.prefix = name.left(star);
    QString tail = name.mid(star + 1);
    const qsizetype dot = tail.lastIndexOf(QLatin1Char('.'));
    if (dot >= 0) {
        rule.ext = tail.mid(dot + 1);
        tail.truncate(dot);
    }
    rule.suffix = tail;

    if (rule.subdir.isEmpty() && rule.prefix.isEmpty() && rule.suffix.isEmpty() && rule.ext.isEmpty())
        return std::nullopt;
    return rule;
}

std::optional<ProxyNameRule> learnProxyRule(const QString &sourcePath, const QString &proxyPath)
{
    const QFileInfo source(sourcePath);
    const QFileInfo proxy(proxyPath);
    if (source.completeBaseName().isEmpty() || proxy.completeBaseName().isEmpty())
        return std::nullopt;

    const QString sourceDir = QDir::cleanPath(source.absolutePath());
    const QString proxyDir = QDir::cleanPath(proxy.absolutePath());
    QString subdir;
    if (proxyDir != sourceDir) {
        const QString prefix = sourceDir.endsWith(QLatin1Char('/')) ? sourceDir : sourceDir + QLatin1Char('/');
        if (!proxyDir.startsWith(prefix))
            return std::nullopt;
        subdir = proxyDir.mid(prefix.size());
    }

    const QString sourceStem = source.completeBaseName();
    const QString proxyStem = proxy.completeBaseName();
    const qsizetype at = proxyStem.indexOf(sourceStem);
    if (at < 0)
        return std::nullopt;

    ProxyNameRule rule;
    rule.subdir = subdir;
    rule.prefix = proxyStem.left(at);
    rule.suffix = proxyStem.mid(at + sourceStem.size());
    if (proxy.suffix() != source.suffix())
        rule.ext = proxy.suffix();

    if (rule.subdir.isEmpty() && rule.prefix.isEmpty() && rule.suffix.isEmpty() && rule.ext.isEmpty())
        return std::nullopt;
    return rule;
}

QString proxyCandidatePath(const ProxyNameRule &rule, const QString &sourcePath)
{
    const QFileInfo source(sourcePath);
    QDir dir(source.absolutePath());
    if (!rule.subdir.isEmpty())
        dir.setPath(dir.filePath(rule.subdir));
    const QString ext = rule.ext.isEmpty() ? source.suffix() : rule.ext;
    QString name = rule.prefix + source.completeBaseName() + rule.suffix;
    if (!ext.isEmpty())
        name += QLatin1Char('.') + ext;
    return QDir::cleanPath(dir.filePath(name));
}

QString generatedProxyPath(const QString &sourcePath, int shortSide)
{
    const QFileInfo source(sourcePath);
    return QDir(source.absolutePath())
        .filePath(QStringLiteral("%1_proxy_%2.mp4").arg(source.completeBaseName()).arg(shortSide));
}

QStringList defaultProxyNamePatterns()
{
    return {QStringLiteral("*_proxy"), QStringLiteral("*_Proxy"), QStringLiteral("*_PRXY")};
}

bool isLocalSourcePath(const QString &path)
{
    return QDir::isAbsolutePath(path)
        && !path.startsWith(QLatin1String("content:"), Qt::CaseInsensitive);
}

bool canWriteBeside(const QString &target)
{
    QFile probe(target + QStringLiteral(".part"));
    if (!probe.open(QIODevice::WriteOnly))
        return false;
    probe.close();
    probe.remove();
    return true;
}

QString reversedSidecarPath(const QString &sourcePath, TimeUs inUs, TimeUs outUs)
{
    const QFileInfo source(sourcePath);
    const TimeUs inMs = qMax<TimeUs>(0, inUs) / 1000;
    const TimeUs outMs = (qMax<TimeUs>(0, outUs) + 999) / 1000;
    return QDir(source.absolutePath())
        .filePath(QStringLiteral("%1_reversed_%2-%3.mp4")
                      .arg(source.completeBaseName())
                      .arg(inMs)
                      .arg(outMs));
}

std::optional<ReversedRange> parseReversedSidecarName(const QString &sourcePath,
                                                      const QString &fileName)
{
    const QString head = QFileInfo(sourcePath).completeBaseName() + QStringLiteral("_reversed_");
    const QString tail = QStringLiteral(".mp4");
    if (!fileName.startsWith(head) || !fileName.endsWith(tail)
        || fileName.size() < head.size() + tail.size())
        return std::nullopt;

    const QString range = fileName.mid(head.size(), fileName.size() - head.size() - tail.size());
    const QStringList parts = range.split(QLatin1Char('-'));
    if (parts.size() != 2)
        return std::nullopt;
    bool inOk = false;
    bool outOk = false;
    const qint64 inMs = parts[0].toLongLong(&inOk);
    const qint64 outMs = parts[1].toLongLong(&outOk);
    // toLongLong would also take "+5" and " 5"; the name is digits only.
    const auto digits = [](const QString &text) {
        return !text.isEmpty() && std::all_of(text.begin(), text.end(), [](QChar c) {
            return c >= QLatin1Char('0') && c <= QLatin1Char('9');
        });
    };
    if (!inOk || !outOk || !digits(parts[0]) || !digits(parts[1]) || inMs >= outMs)
        return std::nullopt;
    return ReversedRange{inMs * 1000, outMs * 1000};
}

} // namespace drift
