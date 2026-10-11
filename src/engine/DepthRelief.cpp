#include "engine/DepthRelief.h"

#include "engine/DepthSidecar.h"
#include "engine/EffectCatalog.h"

#include <algorithm>
#include <cmath>

namespace drift {

namespace {

constexpr double kDefaultDepthRange = 1.0;
const QLatin1String kRelight("depth.relight");

QColor colorParam(const QVariant &value)
{
    if (value.typeId() == QMetaType::QColor)
        return value.value<QColor>();
    const QColor c(value.toString());
    return c.isValid() ? c : QColor(Qt::white);
}

void addLine(QList<EditorLine> &out, const QVector3D &a, const QVector3D &b, const QColor &color, float width)
{
    out.append(EditorLine{a, b, color, width, false});
}

void addDashed(QList<EditorLine> &out, const QVector3D &a, const QVector3D &b, const QColor &color,
               float width, float dash)
{
    const float length = (b - a).length();
    if (length <= 0.f || dash <= 0.f)
        return;
    const int pieces = std::clamp(int(length / dash), 1, 64);
    for (int i = 0; i < pieces; i += 2)
        addLine(out, a + (b - a) * (float(i) / pieces), a + (b - a) * (float(i + 1) / pieces), color, width);
}

void addCircle(QList<EditorLine> &out, const QVector3D &centre, const QVector3D &u, const QVector3D &v,
               float radius, const QColor &color, float width, int segments = 32)
{
    for (int i = 0; i < segments; ++i) {
        const double a0 = 2.0 * M_PI * i / segments;
        const double a1 = 2.0 * M_PI * (i + 1) / segments;
        addLine(out, centre + (u * float(std::cos(a0)) + v * float(std::sin(a0))) * radius,
                centre + (u * float(std::cos(a1)) + v * float(std::sin(a1))) * radius, color, width);
    }
}

// Two unit vectors spanning the plane square to `axis`.
void planeBasis(const QVector3D &axis, QVector3D *u, QVector3D *v)
{
    const QVector3D helper = std::abs(axis.y()) < 0.9f ? QVector3D(0.f, 1.f, 0.f) : QVector3D(1.f, 0.f, 0.f);
    *u = QVector3D::crossProduct(axis, helper).normalized();
    *v = QVector3D::crossProduct(axis, *u).normalized();
}

} // namespace

QVector3D ReliefPlacement::toQuad(const QVector3D &relief) const
{
    // The quad spans [-1, 1] across the frame, so one clip height is 2 in y and 2 / aspect in x.
    // Its z is left unscaled by clipQuadToWorld, so it is world px, and the quad faces +z.
    return QVector3D(float(2.0 * relief.x() / aspect), 2.f * relief.y(), float(-relief.z() * heightPx));
}

QVector3D ReliefPlacement::toWorld(const QVector3D &relief) const
{
    return quadToWorld.map(toQuad(relief));
}

QVector3D ReliefPlacement::fromWorld(const QVector3D &world) const
{
    bool invertible = false;
    const QVector3D q = quadToWorld.inverted(&invertible).map(world);
    if (!invertible)
        return {};
    return QVector3D(float(q.x() * aspect * 0.5), q.y() * 0.5f, float(-q.z() / std::max(1e-6, heightPx)));
}

double reliefDepthRange(const QList<Effect> &effects)
{
    for (const Effect &effect : effects) {
        if (!effect.enabled || effect.catalogId != kRelight)
            continue;
        if (const EffectPresetEntry *def = effectDefForId(effect.catalogId)) {
            return std::max(0.01, resolvedEffectParameters(effect, *def)
                                      .value(QStringLiteral("depthRange"), kDefaultDepthRange)
                                      .toDouble());
        }
    }
    return kDefaultDepthRange;
}

double sampleReliefDepth(const DepthFrame *frame, const QPointF &uv)
{
    if (!frame || frame->size.isEmpty()
        || frame->values.size() != size_t(frame->size.width()) * size_t(frame->size.height())) {
        return 0.0;
    }
    const int w = frame->size.width();
    const int h = frame->size.height();
    // Texel centres sit at (i + 0.5) / size, as GL_LINEAR with clamp-to-edge reads them.
    const double fx = std::clamp(uv.x() * w - 0.5, 0.0, double(w - 1));
    const double fy = std::clamp(uv.y() * h - 0.5, 0.0, double(h - 1));
    const int x0 = int(fx);
    const int y0 = int(fy);
    const int x1 = std::min(x0 + 1, w - 1);
    const int y1 = std::min(y0 + 1, h - 1);
    const double tx = fx - x0;
    const double ty = fy - y0;
    const auto at = [&](int x, int y) { return frame->values[size_t(y) * size_t(w) + size_t(x)] / 65535.0; };
    const double top = at(x0, y0) + (at(x1, y0) - at(x0, y0)) * tx;
    const double bottom = at(x0, y1) + (at(x1, y1) - at(x0, y1)) * tx;
    return top + (bottom - top) * ty;
}

QVector3D reliefSurfacePoint(const DepthFrame *frame, const QPointF &uv, double aspect, double depthRange)
{
    return QVector3D(float((uv.x() - 0.5) * aspect), float(uv.y() - 0.5),
                     float((1.0 - sampleReliefDepth(frame, uv)) * depthRange));
}

QList<ReliefLight> reliefLights(const QList<Effect> &effects, const DepthFrame *frame, double aspect)
{
    QList<ReliefLight> out;
    for (int i = 0; i < effects.size(); ++i) {
        const Effect &effect = effects.at(i);
        if (!effect.enabled || effect.catalogId != kRelight)
            continue;
        const EffectPresetEntry *def = effectDefForId(effect.catalogId);
        if (!def)
            continue;
        const QMap<QString, QVariant> p = resolvedEffectParameters(effect, *def);
        const double range = std::max(0.01, p.value(QStringLiteral("depthRange"), kDefaultDepthRange).toDouble());
        for (int n = 1; n <= 4; ++n) {
            const QString k = QStringLiteral("light%1_").arg(n);
            if (!p.value(k + QStringLiteral("enabled")).toBool())
                continue;
            ReliefLight light;
            light.effectIndex = i;
            light.light = n;
            light.position = QVector3D(float((p.value(k + QStringLiteral("x")).toDouble() - 0.5) * aspect),
                                       float(p.value(k + QStringLiteral("y")).toDouble() - 0.5),
                                       float(p.value(k + QStringLiteral("z")).toDouble() * range));
            light.color = colorParam(p.value(k + QStringLiteral("color")));
            light.cone = p.value(k + QStringLiteral("cone"), 180.0).toDouble();
            light.spot = light.cone < 179.5;
            const QPointF aimUv(p.value(k + QStringLiteral("aimX"), 0.5).toDouble(),
                                p.value(k + QStringLiteral("aimY"), 0.5).toDouble());
            light.aim = reliefSurfacePoint(frame, aimUv, aspect, range);
            out.append(light);
        }
    }
    return out;
}

QVector3D reliefLightParams(const QVector3D &relief, double aspect, double depthRange)
{
    return QVector3D(float(std::clamp(relief.x() / aspect + 0.5, -0.5, 1.5)),
                     float(std::clamp(double(relief.y()) + 0.5, -0.5, 1.5)),
                     float(std::clamp(relief.z() / std::max(0.01, depthRange), -1.0, 1.0)));
}

bool reliefRayHit(const ReliefPlacement &placement, const DepthFrame *frame, double depthRange,
                  const QVector3D &origin, const QVector3D &through, QPointF *uv)
{
    const QVector3D a = placement.fromWorld(origin);
    const QVector3D dir = placement.fromWorld(through) - a;
    if (std::abs(dir.z()) < 1e-9f)
        return false;
    // March the slab the surface lives in, from where the ray enters it to where it leaves.
    double t0 = (0.0 - a.z()) / dir.z();
    double t1 = (depthRange - a.z()) / dir.z();
    if (t0 > t1)
        std::swap(t0, t1);
    t0 = std::max(t0, 0.0);
    if (t1 <= t0)
        return false;
    const auto uvAt = [&](const QVector3D &p) {
        return QPointF(p.x() / placement.aspect + 0.5, p.y() + 0.5);
    };
    const auto inside = [](const QPointF &q) { return q.x() >= 0.0 && q.x() <= 1.0 && q.y() >= 0.0 && q.y() <= 1.0; };
    constexpr int kSteps = 256;
    double previous = t0;
    for (int i = 0; i <= kSteps; ++i) {
        const double t = t0 + (t1 - t0) * i / kSteps;
        const QVector3D p = a + dir * float(t);
        const QPointF q = uvAt(p);
        if (inside(q) && p.z() >= (1.0 - sampleReliefDepth(frame, q)) * depthRange) {
            // Halve back to the crossing between the last step in front and this one.
            double lo = previous;
            double hi = t;
            for (int k = 0; k < 8; ++k) {
                const double mid = (lo + hi) * 0.5;
                const QVector3D m = a + dir * float(mid);
                const QPointF mq = uvAt(m);
                if (inside(mq) && m.z() >= (1.0 - sampleReliefDepth(frame, mq)) * depthRange)
                    hi = mid;
                else
                    lo = mid;
            }
            *uv = uvAt(a + dir * float(hi));
            return true;
        }
        previous = t;
    }
    return false;
}

void addReliefLightGuides(QList<EditorLine> &out, const QList<ReliefLight> &lights,
                          const ReliefPlacement &placement, const DepthFrame *frame, double depthRange,
                          const QVector3D &eye, bool selected)
{
    const float width = selected ? 2.f : 1.5f;
    for (const ReliefLight &light : lights) {
        QColor color = light.color;
        color.setAlpha(selected ? 235 : 150);
        QColor faint = color;
        faint.setAlpha(selected ? 150 : 90);

        const QVector3D at = placement.toWorld(light.position);
        // A ring that faces the viewer and keeps about the same size on screen, as Blender's does.
        QVector3D toEye = eye - at;
        const float distance = toEye.length();
        if (distance < 1e-3f)
            continue;
        toEye /= distance;
        QVector3D u;
        QVector3D v;
        planeBasis(toEye, &u, &v);
        const float ring = distance * 0.018f;
        addCircle(out, at, u, v, ring, color, width);
        addCircle(out, at, u, v, ring * 0.3f, color, width, 12);

        // Straight back along the frame to the surface it hangs over, so its place in the depth map
        // reads from any angle.
        const QPointF uv(light.position.x() / placement.aspect + 0.5, light.position.y() + 0.5);
        if (uv.x() >= 0.0 && uv.x() <= 1.0 && uv.y() >= 0.0 && uv.y() <= 1.0) {
            const QVector3D below = placement.toWorld(reliefSurfacePoint(frame, uv, placement.aspect, depthRange));
            addDashed(out, at, below, faint, 1.f, ring * 0.6f);
            QVector3D bu;
            QVector3D bv;
            planeBasis(placement.quadToWorld.mapVector(QVector3D(0.f, 0.f, 1.f)).normalized(), &bu, &bv);
            addLine(out, below - bu * ring * 0.5f, below + bu * ring * 0.5f, faint, 1.f);
            addLine(out, below - bv * ring * 0.5f, below + bv * ring * 0.5f, faint, 1.f);
        }

        if (!light.spot)
            continue;
        const QVector3D aim = placement.toWorld(light.aim);
        const QVector3D axisVector = aim - at;
        const float length = axisVector.length();
        if (length < 1e-3f)
            continue;
        const QVector3D axis = axisVector / length;
        // Past about 75 degrees off the axis the cone's mouth runs off towards the horizon, so the
        // drawing stops widening there.
        const double half = std::min(light.cone * 0.5, 75.0) * M_PI / 180.0;
        const float mouth = length * float(std::tan(half));
        QVector3D cu;
        QVector3D cv;
        planeBasis(axis, &cu, &cv);
        addCircle(out, aim, cu, cv, mouth, color, width, 48);
        for (int i = 0; i < 8; ++i) {
            const double a = 2.0 * M_PI * i / 8;
            addLine(out, at, aim + (cu * float(std::cos(a)) + cv * float(std::sin(a))) * mouth, faint, 1.f);
        }
        addDashed(out, at, aim, color, 1.f, ring * 0.6f);
    }
}

} // namespace drift
