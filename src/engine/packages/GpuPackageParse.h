#pragma once

#include "engine/gpu/effects/GpuEffectDefinition.h"
#include "core/effects/EffectPreset.h"

#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QMap>
#include <QString>
#include <QVariant>

// Shared JSON grammar for GPU packages. Effects (effect.json) and transitions
// (transition.json) declare parameters and pipelines identically; only the
// surrounding metadata differs.
namespace GpuPackageParse {

QString readTextFile(const QString &path, QString *errorOut);

QString slugifyCategory(const QString &raw);

QVariant jsonToVariant(const QJsonValue &value);

// Parse "parameters": [...]. Rejects identifiers colliding with reserved uniforms when gpuBackend.
// packageDir is used to resolve FilePath defaults via resolvePackageAsset; may be empty.
bool parseParameters(const QJsonArray &params, QList<drift::EffectParamSpec> *out, bool gpuBackend,
                     QString *errorOut, const QString &packageDir = {});

// Refuse a package whose "nextFeatures" names something this Drift doesn't implement.
bool checkNextFeatures(const QJsonObject &root, QString *errorOut);

void parseFixedParams(const QJsonObject &obj, QMap<QString, QVariant> *out);

// Parse "pipeline": { intermediateBuffers, textures, passes }. Sets out->valid on success.
// maxSourceIndex bounds "source_texture" indices: 0 for effects, 1 for transitions.
bool loadGpuPipeline(const QJsonObject &root, const QString &packageDir, int maxSourceIndex,
                     drift::GpuEffectDefinition *out, QString *errorOut);

// Copy the sampler and region params out of a parsed parameter list onto a pipeline, for the runtime.
void collectRuntimeParams(const QList<drift::EffectParamSpec> &params, drift::GpuEffectDefinition *out);

// Resolve an optional relative/absolute asset path inside a package; empty when missing.
QString resolvePackageAsset(const QString &packageDir, const QString &relOrAbs);

} // namespace GpuPackageParse
