#pragma once

#include "core/project/sources/Model3dSource.h"
#include "engine/ClipTransform3d.h"

#include <QMatrix3x3>
#include <QMatrix4x4>
#include <QRectF>
#include <QSizeF>
#include <QVector3D>

#include <array>

namespace drift {

// Resolved light knobs for one model clip draw.
struct ModelClipParams
{
    std::array<ModelLight, kModelLightCount> lights = defaultModelLights();
    double ambient = 0.35;
};

// The frame a model clip's lights are placed in (see ModelLight), in world space: the clip's rect
// laid flat at the model's centre depth, unturned by the clip's rotations.
struct ModelLightFrame
{
    QVector3D origin; // light (0, 0, 0): the rect's top-left corner at the centre's depth
    double width = 1.0;
    double height = 1.0;

    QVector3D toWorld(const QVector3D &light) const;
    QVector3D fromWorld(const QVector3D &world) const;
    // Where a spot aimed at (aimX, aimY) points.
    QVector3D aimWorld(double aimX, double aimY) const { return toWorld(QVector3D(float(aimX), float(aimY), 0.f)); }
};
ModelLightFrame modelLightFrame(const QRectF &rect, const ClipPose3d &pose, const QSizeF &canvas);

ModelClipParams modelClipParamsFromSource(const Model3dSource &source);

// Model space (the file's own units, glTF axes: +y up, +z toward the viewer) to world space
// (canvas px about the canvas centre, y down, +z toward the viewer), the space every clip's quad
// lives in. The model's rest bounding box is fitted to the clip: its front face is the layout
// `rect` at the rect's centre and `pose.positionZ`, its depth scales with the geometric mean of
// the two face scales, and the clip's rotations turn it about its centre exactly as they turn a
// flat clip (X, then Y, then the in-plane spin). `pose.perspective` plays no part: the eye
// belongs to whoever views the world.
QMatrix4x4 modelClipWorld(const QRectF &rect, double rotation, const ClipPose3d &pose,
                          const QVector3D &aabbMin, const QVector3D &aabbMax, const QSizeF &canvas);

// The size a model's bounding box front face gets when the largest rest extent spans `span` px.
QSizeF modelClipFaceSize(const QVector3D &aabbMin, const QVector3D &aabbMax, double span);

} // namespace drift
