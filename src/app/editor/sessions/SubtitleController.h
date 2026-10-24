#pragma once

#include "core/project/SubtitleCue.h"

#include <QList>
#include <QObject>
#include <QString>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>

#include <functional>

namespace drift {
struct Clip;
}

class AppController;
class SubtitleCueFilterModel;
class SubtitleCueModel;

// Subtitle text, file and timing tools for the Subtitles workspace panels, reached from QML as
// EditorState.subtitles. Owns the cue selection the panels share. Every apply call is one undo
// step, and every preview returns how many cues the matching apply would change.
class SubtitleController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList selectedCues READ selectedCues NOTIFY selectedCuesChanged)
    Q_PROPERTY(int anchorCue READ anchorCue NOTIFY selectedCuesChanged)
    Q_PROPERTY(int activeCue READ activeCue NOTIFY activeCueChanged)
    Q_PROPERTY(QObject *cueModel READ cueModel CONSTANT)
    Q_PROPERTY(QObject *filteredCueModel READ filteredCueModel CONSTANT)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    explicit SubtitleController(AppController *app, QObject *parent = nullptr);

    QVariantList selectedCues() const;
    int anchorCue() const { return m_anchor; }
    int activeCue() const { return m_activeCue; }
    QObject *cueModel() const;
    QObject *filteredCueModel() const;
    int count() const { return m_count; }

    Q_INVOKABLE void selectCue(int index, int mode);
    Q_INVOKABLE void selectAll(int track, int clip);
    Q_INVOKABLE void clearSelection();
    Q_INVOKABLE void setSelectedCues(const QVariantList &indices);

    Q_INVOKABLE QVariantList cues(int track, int clip) const;
    Q_INVOKABLE double projectFps() const;

    Q_INVOKABLE QString cuesText(int track, int clip, const QString &format, bool timelineTimes) const;
    Q_INVOKABLE QVariantMap parseText(const QString &text, const QString &format) const;
    Q_INVOKABLE bool applyText(int track, int clip, const QString &text, const QString &format,
                               bool timelineTimes);
    Q_INVOKABLE QString detectFormat(const QString &text) const;

    Q_INVOKABLE bool importFile(int track, int clip, const QUrl &url);
    Q_INVOKABLE bool exportFile(int track, int clip, const QUrl &url, bool timelineTimes);

    Q_INVOKABLE int previewShift(int track, int clip, int scope, double seconds, int edges);
    Q_INVOKABLE int applyShift(int track, int clip, int scope, double seconds, int edges);
    Q_INVOKABLE int previewResync(int track, int clip, int scope, double aFrom, double aTo,
                                  double bFrom, double bTo);
    Q_INVOKABLE int applyResync(int track, int clip, int scope, double aFrom, double aTo,
                                double bFrom, double bTo);
    Q_INVOKABLE int previewScale(int track, int clip, int scope, double factor);
    Q_INVOKABLE int applyScale(int track, int clip, int scope, double factor);
    Q_INVOKABLE int previewBridgeGaps(int track, int clip, int scope, double maxGap, double minGap,
                                      double prevRatio);
    Q_INVOKABLE int applyBridgeGaps(int track, int clip, int scope, double maxGap, double minGap,
                                    double prevRatio);
    Q_INVOKABLE int previewMinGap(int track, int clip, int scope, double minGap);
    Q_INVOKABLE int applyMinGap(int track, int clip, int scope, double minGap);
    Q_INVOKABLE int previewLeadInOut(int track, int clip, int scope, double leadIn, double leadOut);
    Q_INVOKABLE int applyLeadInOut(int track, int clip, int scope, double leadIn, double leadOut);
    Q_INVOKABLE int previewDurations(int track, int clip, int scope, double minDur, double maxDur);
    Q_INVOKABLE int applyDurations(int track, int clip, int scope, double minDur, double maxDur);
    Q_INVOKABLE int previewFixOverlaps(int track, int clip, int scope);
    Q_INVOKABLE int applyFixOverlaps(int track, int clip, int scope);

signals:
    void selectedCuesChanged();
    void cuesChanged();
    void activeCueChanged();
    void countChanged();

private:
    using ToolFn = std::function<int(QList<drift::SubtitleCue> &, const QList<int> &)>;

    const drift::Clip *subtitleClip(int track, int clip) const;
    int runTool(int track, int clip, int scope, const QString &undoText, bool commit,
                const ToolFn &fn);
    void setSelection(QList<int> indices, int anchor);
    void syncCurrentCue();
    const drift::Clip *selectedSubtitleClip() const;
    void refreshModel();
    void refreshActiveCue();

    AppController *m_app = nullptr;
    QList<int> m_selected;
    int m_anchor = -1;
    int m_track = -1;
    int m_clip = -1;
    bool m_syncing = false;
    SubtitleCueModel *m_model = nullptr;
    SubtitleCueFilterModel *m_filtered = nullptr;
    int m_activeCue = -1;
    int m_count = 0;
};
