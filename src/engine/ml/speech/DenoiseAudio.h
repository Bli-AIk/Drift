#pragma once

#include "core/base/Time.h"

#include <QString>

#include <functional>

namespace drift {

// Decodes [inUs, outUs) of `input` at DeepFilterDenoiser::sampleRate(), runs each stereo channel
// through the (mono) model separately so the stereo image survives, and writes the result as
// 16-bit FLAC at that rate. The speed and reverse of a clip are not applied: the render stays in
// the source's own time base.
//
// `originalFlac`, when non-empty, also receives the untouched decoded window, for an A/B preview.
//
// onProgress is called with 0..1 and returns false to cancel; the phases are decode 0.05-0.25,
// left channel 0.25-0.60, right channel 0.60-0.95, write 0.95-1. Blocking: run it off the GUI
// thread. Failure and cancel leave no finished output file behind.
bool denoiseAudioRange(const QString &input, TimeUs inUs, TimeUs outUs, const QString &outputFlac,
                       QString *error, const std::function<bool(double)> &onProgress,
                       const QString &originalFlac = QString());

} // namespace drift
