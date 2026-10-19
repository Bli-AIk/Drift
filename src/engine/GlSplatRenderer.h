#pragma once

#include "engine/GlRuntime.h"

#include <QMatrix4x4>
#include <QOpenGLExtraFunctions>
#include <QSize>

namespace drift::model3d {
struct ModelDrawRequest;
}

namespace drift::gl {

// Draw a Gaussian splat clip into a new pooled, straight-alpha layer target the size of the
// canvas, placed and seen like drawModelClip. Splats are sorted back to front on the CPU and
// blended over; no depth is produced. Invalid on any failure. GL thread only.
GlTarget drawSplatClip(GlRuntime &rt, QOpenGLExtraFunctions *gl, const model3d::ModelDrawRequest &request,
                       const QSize &canvasSize, const QMatrix4x4 &viewProjection);

void destroyGlSplats(GlRuntime &rt, QOpenGLExtraFunctions *gl);

} // namespace drift::gl
