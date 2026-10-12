#pragma once

#include <QList>
#include <QString>
#include <QStringList>
#include <optional>

namespace drift {

// A numbered run of still images played as video. It lives in MediaAsset::path as one
// self-describing string, "<image2 pattern>#start=<N>&fps=<num>:<den>", e.g.
// "/renders/render_%04d.png#start=1&fps=24:1". The pattern is an absolute FFmpeg image2 path
// (a literal '%' is written "%%"); the metadata follows the LAST '#'. The fps uses ':' so the
// file name never contains a '/'. The suffix therefore never matches a still-image extension,
// which keeps kind inference treating the asset as video.
struct ImageSequence {
    QString pattern;
    int start = 0;
    int fpsNum = 0;
    int fpsDen = 1;
};

bool isImageSequencePath(const QString &path);
// Strict: the pattern must hold exactly one %d / %0Nd conversion (ignoring %%).
std::optional<ImageSequence> parseImageSequencePath(const QString &path);
QString imageSequencePath(const ImageSequence &seq);
// The real file on disk for frame `number`.
QString imageSequenceFramePath(const ImageSequence &seq, int number);
// Frame files from seq.start up to, but not including, the first missing number. Stops at
// maxFrames when it is above 0.
QStringList imageSequenceFrames(const ImageSequence &seq, int maxFrames = 0);
// Bin name such as "render_[0001-0240].png".
QString imageSequenceDisplayName(const ImageSequence &seq, int frameCount);
// A folder name for the sequence's frames: the file name without the number or extension, e.g.
// "render". Never holds '%', so a path built from it still has exactly one conversion.
QString imageSequenceFolderName(const ImageSequence &seq);
// 23.976 -> 24000:1001 and friends, integral rates -> N:1, anything else rounded to 1/1000.
void setImageSequenceFps(ImageSequence &seq, double fps);

struct DetectedImageSequence {
    ImageSequence sequence; // fps left 0
    int frameCount = 0;     // frames on disk from start to the first gap
    // Input paths this sequence replaces, including selected frames past the gap, which are
    // dropped rather than imported.
    QStringList consumedPaths;
    int skippedAfterGap = 0; // how many of consumedPaths lie past the gap
    QString displayName;
};

// Groups numbered still images into sequences, in order of first appearance. Files that are not
// numbered images, or whose run is shorter than minFrames, are left out of every consumedPaths.
QList<DetectedImageSequence> detectImageSequences(const QStringList &absolutePaths, int minFrames = 3);

} // namespace drift
