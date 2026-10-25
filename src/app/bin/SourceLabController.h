#pragma once

#include "core/base/Time.h"
#include "core/project/media/SourceLab.h"

#include <QAtomicInt>
#include <QHash>
#include <QJsonObject>
#include <QObject>
#include <QRectF>
#include <QSharedPointer>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QTimer>
#include <QVariantMap>

#include <limits>

class AppController;

namespace drift {
struct MediaAsset;
}

struct MediaInfo;

// Per-source ranges, markers and ratings (persisted, undoable) plus the transient edit recipe
// Source Lab builds up. Reached from QML as EditorState.sourceLab.
class SourceLabController : public QObject
{
    friend class AppController;

    Q_OBJECT

    Q_PROPERTY(QString currentAssetId READ currentAssetId NOTIFY currentAssetIdChanged)
    Q_PROPERTY(QString name READ name NOTIFY assetChanged)
    Q_PROPERTY(QString kind READ kind NOTIFY assetChanged)
    Q_PROPERTY(double durationSeconds READ durationSeconds NOTIFY assetChanged)
    Q_PROPERTY(double fps READ fps NOTIFY assetChanged)
    Q_PROPERTY(int width READ width NOTIFY assetChanged)
    Q_PROPERTY(int height READ height NOTIFY assetChanged)
    Q_PROPERTY(bool hasAudio READ hasAudio NOTIFY assetChanged)
    Q_PROPERTY(int rating READ rating NOTIFY assetChanged)
    // Maps {id, in, out, rating, name, note}, in seconds, sorted by in.
    Q_PROPERTY(QVariantList ranges READ ranges NOTIFY rangesChanged)
    // Maps {id, time, name, note}, in seconds, sorted by time.
    Q_PROPERTY(QVariantList markers READ markers NOTIFY markersChanged)
    // Keys: trimIn, trimOut (seconds, trimOut -1 = to the end), crop (rect), aspect, speed,
    // keepPitch, gainDb, normalizeLufs (NaN = off), denoise, stabilize, decompressModel,
    // upscaleModel.
    Q_PROPERTY(QVariantMap recipe READ recipe NOTIFY recipeChanged)
    // Only trim and crop can differ from the defaults, so applying needs no re-encode.
    Q_PROPERTY(bool recipeIsPureTrimCrop READ recipeIsPureTrimCrop NOTIFY recipeChanged)
    // The recipe differs from what the asset already is (its stored trim and crop, defaults elsewhere).
    Q_PROPERTY(bool recipeDirty READ recipeDirty NOTIFY recipeChanged)
    // Apply and auto-split run one at a time. progress is 0..1, etaSeconds -1 when unknown (it is
    // only estimated for enhance), lastError empty after a success or a cancel.
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(double progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString status READ status NOTIFY progressChanged)
    Q_PROPERTY(double etaSeconds READ etaSeconds NOTIFY progressChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    // A renderPreviewSegment job is running.
    Q_PROPERTY(bool previewBusy READ previewBusy NOTIFY previewBusyChanged)
    // What the Output panel can offer: restore models installed, a vid.stab build, the denoise model.
    Q_PROPERTY(bool enhanceAvailable READ enhanceAvailable NOTIFY availabilityChanged)
    Q_PROPERTY(bool stabilizeAvailable READ stabilizeAvailable NOTIFY availabilityChanged)
    Q_PROPERTY(bool denoiseAvailable READ denoiseAvailable NOTIFY availabilityChanged)

public:
    explicit SourceLabController(AppController *app, QObject *parent = nullptr);
    ~SourceLabController() override;

    // Never serialized; one per asset id for the session.
    struct SourceRecipe
    {
        QRectF crop{0, 0, 1, 1};
        QString aspect = QStringLiteral("free");
        double speed = 1.0;
        bool keepPitch = true;
        double gainDb = 0.0;
        double normalizeLufs = std::numeric_limits<double>::quiet_NaN();
        bool denoise = false;
        bool stabilize = false;
        QString decompressModel;
        QString upscaleModel;
        drift::TimeUs trimInUs = 0;
        drift::TimeUs trimOutUs = -1;
    };

    QString currentAssetId() const { return m_assetId; }
    QString name() const;
    QString kind() const;
    double durationSeconds() const;
    double fps() const;
    int width() const;
    int height() const;
    bool hasAudio() const;
    int rating() const;
    QVariantList ranges() const { return m_ranges; }
    QVariantList markers() const { return m_markers; }
    QVariantMap recipe() const;
    bool recipeIsPureTrimCrop() const;
    bool recipeDirty() const;
    bool busy() const { return m_busy; }
    double progress() const { return m_progress; }
    QString status() const { return m_status; }
    double etaSeconds() const;
    QString lastError() const { return m_lastError; }
    bool previewBusy() const { return m_previewBusy; }
    bool enhanceAvailable() const;
    bool stabilizeAvailable() const;
    bool denoiseAvailable() const;

    Q_INVOKABLE bool load(const QString &assetId);
    Q_INVOKABLE void clear();

    Q_INVOKABLE QString addRange(double inSeconds, double outSeconds);
    Q_INVOKABLE bool updateRange(const QString &id, double inSeconds, double outSeconds);
    Q_INVOKABLE bool setRangeRating(const QString &id, int rating);
    Q_INVOKABLE bool renameRange(const QString &id, const QString &name);
    Q_INVOKABLE bool setRangeNote(const QString &id, const QString &note);
    Q_INVOKABLE bool removeRange(const QString &id);
    // Swaps the whole list in one undo step. Entries are maps shaped like `ranges`; a missing id
    // gets a fresh one, and entries that are empty after clamping are dropped.
    Q_INVOKABLE bool replaceRanges(const QVariantList &ranges);

    Q_INVOKABLE QString addMarker(double timeSeconds);
    Q_INVOKABLE bool moveMarker(const QString &id, double timeSeconds);
    Q_INVOKABLE bool renameMarker(const QString &id, const QString &name);
    Q_INVOKABLE bool setMarkerNote(const QString &id, const QString &note);
    Q_INVOKABLE bool removeMarker(const QString &id);

    Q_INVOKABLE bool setAssetRating(int rating);

    // The sample boundary nearest `seconds` (within +/- windowSeconds) where the audio crosses
    // zero, for clicks-free cuts; `seconds` itself when there is none or nothing decodes.
    Q_INVOKABLE double nearestZeroCrossing(double seconds, double windowSeconds = 0.02) const;

    // One sub-clip per range, all in a single undo step. Returns the new asset ids.
    Q_INVOKABLE QStringList makeSubclips(const QStringList &rangeIds);

    Q_INVOKABLE bool setRecipeValue(const QString &key, const QVariant &value);
    // section: trim, crop, speed, audio, stabilize, enhance or all.
    Q_INVOKABLE void resetRecipe(const QString &section);

    // Puts the current recipe into effect. mode: "replace" (the asset becomes the result, its
    // timeline clips, ranges and markers rebased onto it, one undo step), "copy" (the result is a
    // new "<name> (edited)" bin item) or "export" (written to exportOptions.path, the project
    // untouched). exportOptions: path, streamCopy (pure trim only), container, videoCodec, crf,
    // maxHeight, audioBitrateKbps, wavBitDepth. A trim and crop alone never re-encode for replace
    // and copy. Returns the sourceLab.process job id, or empty when nothing was started (done
    // already, or refused with lastError set).
    Q_INVOKABLE QString apply(const QString &mode, const QVariantMap &exportOptions = {});
    Q_INVOKABLE void cancel();
    // What apply(mode, exportOptions) would do: {encode, streamCopy, snappedIn (seconds; where a
    // stream copy really starts), steps (strings), outputDuration (seconds), enhanceSeconds (estimated
    // enhance time, -1 when there is none or it is unknown), error}.
    Q_INVOKABLE QVariantMap plan(const QString &mode, const QVariantMap &exportOptions = {}) const;
    Q_INVOKABLE QStringList availableVideoCodecs() const;
    // Renders `lengthSeconds` of the recipe's result around `centerSeconds` (source time) into a
    // temp file for the A/B preview, without any upscale, and announces it with
    // previewSegmentReady. A newer call cancels the one before; an unchanged request is answered
    // from the last render. Returns the job id, or empty when answered or refused.
    Q_INVOKABLE QString renderPreviewSegment(double centerSeconds, double lengthSeconds = 5);
    // Replaces the asset's ranges with one "Shot N" per detected scene inside the recipe's trim, as
    // one undo step. options: threshold, minSceneSeconds.
    Q_INVOKABLE void autoSplit(const QVariantMap &options = {});

    // Re-reads the current asset after the project changed underneath (undo, redo, load).
    void refresh();

signals:
    void currentAssetIdChanged();
    void assetChanged();
    void rangesChanged();
    void markersChanged();
    void recipeChanged();
    void busyChanged();
    void progressChanged();
    void lastErrorChanged();
    void previewBusyChanged();
    void availabilityChanged();
    // An export finished; the file is at `path`.
    void exported(const QString &path);
    // The preview render is at `path`; it starts at `startSeconds` of the source.
    void previewSegmentReady(const QString &path, double startSeconds);

private:
    struct Pipeline;
    bool buildPipeline(const QString &mode, const QVariantMap &exportOptions, Pipeline *out,
                       QString *error) const;
    static SourceRecipe recipeFor(const drift::MediaAsset &asset);
    void resetRecipeToAsset(const QString &assetId);
    bool applyWithoutEncode(const QString &mode);
    void finishJob(const QJsonObject &job, const Pipeline &pipeline, const QString &mode,
                   const QString &assetId, const MediaInfo &info);
    void startReplace(const QString &assetId, const QString &outputPath, drift::TimeUs trimIn,
                      double speed);
    void finishReplace(bool ok, const QString &message);
    void beginBusy(const QString &status);
    void endBusy();
    void setLastError(const QString &message);
    void pollJob();
    void discardPreview();

    const drift::MediaAsset *current() const;
    // Runs `change` on the current asset between an undo snapshot and its push. `change` returns
    // false, without having modified anything, to cancel.
    template <typename Fn>
    bool edit(const QString &text, Fn &&change);

    AppController *m_app = nullptr;
    QString m_assetId;
    QVariantList m_ranges;
    QVariantList m_markers;
    QHash<QString, SourceRecipe> m_recipes;

    bool m_busy = false;
    double m_progress = 0.0;
    QString m_status;
    double m_etaTotal = -1.0;
    QString m_lastError;
    QString m_jobId;
    QTimer m_poll;
    QSharedPointer<QAtomicInt> m_splitCancel;
    // A replace's swap is asynchronous (the new file is probed); these carry it to replaceFinished.
    QString m_replaceAssetId;
    QString m_replaceOutput;
    bool m_previewBusy = false;
    QString m_previewJobId;
    QString m_previewPath;
    QString m_previewKey;
    drift::TimeUs m_previewStartUs = 0;
    quint64 m_previewSerial = 0;
};
