#!/usr/bin/env bash
# Cross-builds the native dependencies Drift links that have no WebAssembly package: FFmpeg, x264,
# dav1d, vid.stab, zstd, OpenSSL (libcrypto) and SoundTouch. Output goes to
# third_party/prebuilt/wasm/{include,lib}, which is where the root CMakeLists looks.
#
# JUCE and the ONNX Runtime headers are NOT here, same as build-android.sh. Everything is a static
# archive: the app is one wasm module, and there is no dlopen of anything.
#
# Usage: third_party/build-wasm.sh
#   Needs an activated emsdk (emcc on PATH) and pkg-config, meson, ninja and cmake on the host.
#   JOBS            parallel jobs; default min(nproc, MemAvailable / 1.5 GB)
#   WASM_EH_FLAGS   exception-handling flags, default -fexceptions. MUST match how the
#                   installed Qt for wasm was built (the official Qt 6.11 wasm builds use JS exceptions).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/src"
OUT="$HERE/prebuilt/wasm"

# Pinned to the same versions as build-android.sh.
FFMPEG_TAG="n8.1.2"
X264_TAG="stable"
ZSTD_TAG="v1.5.7"
OPENSSL_TAG="openssl-3.6.3"
DAV1D_TAG="1.5.4"
VIDSTAB_TAG="v1.1.1"
# Upstream tags this release "2.4.1"; there is no plain "2.4.0".
SOUNDTOUCH_TAG="2.4.1"

command -v emcc >/dev/null 2>&1 || {
  echo "emcc not found on PATH — activate the emsdk first (source <emsdk>/emsdk_env.sh)" >&2
  exit 1
}

WASM_EH_FLAGS="${WASM_EH_FLAGS--fexceptions}"
# -pthread on every object, not just the ones that spawn threads: the app links multithreaded Qt
# (shared memory), and wasm-ld refuses to mix shared-memory and non-shared objects at link time.
# -matomics/-mbulk-memory are what -pthread implies; spelled out so configure link tests, which
# take CFLAGS but not always the driver defaults, agree. -ffp-contract=off keeps float results
# bit-identical to the desktop build (no fused multiply-add).
COMMON_FLAGS="-O3 -pthread -matomics -mbulk-memory -ffp-contract=off $WASM_EH_FLAGS"

if [ -z "${JOBS:-}" ]; then
  avail_kb="$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)"
  JOBS=$(( avail_kb / 1572864 ))
  nproc_n="$(nproc)"
  [ "$JOBS" -gt "$nproc_n" ] && JOBS="$nproc_n"
  [ "$JOBS" -lt 1 ] && JOBS=1
fi
export CMAKE_BUILD_PARALLEL_LEVEL="$JOBS"

mkdir -p "$SRC" "$OUT/include" "$OUT/lib"

clone() { # clone <url> <tag> <dir>
  [ -d "$SRC/$3" ] || git clone --depth 1 --branch "$2" "$1" "$SRC/$3"
}

echo "==> building for wasm (-j$JOBS, flags: $COMMON_FLAGS) into $OUT"

# --- x264 --------------------------------------------------------------------
# i686-gnu only makes configure accept a 32-bit x86 host; --disable-asm keeps it from emitting any
# x86 assembly. Threads stay on, matching -pthread.
clone https://code.videolan.org/videolan/x264.git "$X264_TAG" x264
( cd "$SRC/x264" && make distclean >/dev/null 2>&1 || true
  emconfigure ./configure --prefix="$OUT" --host=i686-gnu --enable-static --enable-pic \
      --disable-asm --disable-cli --disable-opencl \
      --extra-cflags="$COMMON_FLAGS" --extra-ldflags="$COMMON_FLAGS"
  make -j"$JOBS" && make install )

# --- dav1d -------------------------------------------------------------------
# See build-android.sh: the only software AV1 decoder, picked by FFmpeg over the native hwaccel shell.
# needs_exe_wrapper stops meson from trying to run wasm test binaries during configure.
clone https://code.videolan.org/videolan/dav1d.git "$DAV1D_TAG" dav1d
MESON_C_ARGS=""
for f in $COMMON_FLAGS; do MESON_C_ARGS="$MESON_C_ARGS'$f', "; done
cat > "$SRC/dav1d/cross-wasm.txt" <<EOF
[binaries]
c = 'emcc'
cpp = 'em++'
ar = 'emar'
ranlib = 'emranlib'
strip = 'emstrip'
pkg-config = 'pkg-config'

[built-in options]
c_args = [$MESON_C_ARGS]
c_link_args = [$MESON_C_ARGS]

[properties]
needs_exe_wrapper = true

[host_machine]
system = 'emscripten'
cpu_family = 'wasm32'
cpu = 'wasm32'
endian = 'little'
EOF
rm -rf "$SRC/dav1d/build-wasm"
meson setup "$SRC/dav1d/build-wasm" "$SRC/dav1d" --cross-file "$SRC/dav1d/cross-wasm.txt" \
  --prefix="$OUT" --libdir=lib --buildtype=release --default-library=static \
  -Denable_asm=false -Denable_tools=false -Denable_tests=false
ninja -C "$SRC/dav1d/build-wasm" -j"$JOBS" install
# Emscripten's meson integration writes its own -sPTHREAD_POOL_SIZE into the .pc; the app sets the pool.
sed -i 's/ -sPTHREAD_POOL_SIZE=[0-9]*//' "$OUT/lib/pkgconfig/dav1d.pc"

# --- vid.stab ----------------------------------------------------------------
# OpenMP off and CMAKE_POLICY_VERSION_MINIMUM for the same reasons as build-android.sh.
clone https://github.com/georgmartius/vid.stab.git "$VIDSTAB_TAG" vid.stab
emcmake cmake -S "$SRC/vid.stab" -B "$SRC/vid.stab/build-wasm" -G Ninja \
  -DCMAKE_INSTALL_PREFIX="$OUT" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="$COMMON_FLAGS" -DCMAKE_CXX_FLAGS="$COMMON_FLAGS" \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_SHARED_LIBS=OFF -DUSE_OMP=OFF
cmake --build "$SRC/vid.stab/build-wasm" --target install

# --- FFmpeg ------------------------------------------------------------------
# --target-os=none --arch=x86_32 is the usual Emscripten recipe: configure has no wasm target, and
# a 32-bit arch gets the right pointer size and keeps it off the 64-bit x86 paths. All asm is off.
# --disable-autodetect so nothing from the host (or an emsdk port) is picked up behind our back;
# the three external libs are enabled explicitly and found through pkg-config in $OUT. zlib is the
# exception, from emscripten's port: the PNG decoder and compressed MOV headers need it.
# No --disable-postproc: libpostproc was removed in FFmpeg 8.0 and configure hard-errors on it.
# Dropped vs. Android: mediacodec, jni and the hwaccel switches (--disable-hwaccels covers them).
clone https://git.ffmpeg.org/ffmpeg.git "$FFMPEG_TAG" ffmpeg
( cd "$SRC/ffmpeg" && make distclean >/dev/null 2>&1 || true
  # emconfigure overwrites PKG_CONFIG_PATH/LIBDIR with its sysroot; EM_PKG_CONFIG_PATH is what it keeps.
  export EM_PKG_CONFIG_PATH="$OUT/lib/pkgconfig"
  emconfigure ./configure \
    --prefix="$OUT" \
    --target-os=none --arch=x86_32 --enable-cross-compile \
    --cc=emcc --cxx=em++ --ar=emar --nm=emnm --ranlib=emranlib \
    --disable-asm --disable-x86asm --disable-inline-asm \
    --enable-static --disable-shared --disable-stripping \
    --enable-gpl --enable-version3 --enable-libx264 --enable-libdav1d --enable-libvidstab \
    --enable-pthreads --enable-zlib \
    --extra-cflags="-I$OUT/include $COMMON_FLAGS -sUSE_ZLIB=1" \
    --extra-cxxflags="$COMMON_FLAGS" \
    --extra-ldflags="-L$OUT/lib $COMMON_FLAGS -sUSE_ZLIB=1" \
    --pkg-config-flags="--static" \
    --disable-programs --disable-doc --disable-network --disable-hwaccels \
    --disable-devices --disable-autodetect \
    --enable-avfilter --enable-swscale --enable-swresample
  make -j"$JOBS" && make install )

# --- zstd --------------------------------------------------------------------
# .driftpkg addons and .drift project bundles.
clone https://github.com/facebook/zstd.git "$ZSTD_TAG" zstd
emcmake cmake -S "$SRC/zstd/build/cmake" -B "$SRC/zstd/build-wasm" -G Ninja \
  -DCMAKE_INSTALL_PREFIX="$OUT" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="$COMMON_FLAGS" -DCMAKE_CXX_FLAGS="$COMMON_FLAGS" \
  -DZSTD_BUILD_SHARED=OFF -DZSTD_BUILD_STATIC=ON -DZSTD_BUILD_PROGRAMS=OFF \
  -DZSTD_BUILD_TESTS=OFF -DZSTD_BUILD_CONTRIB=OFF -DZSTD_LEGACY_SUPPORT=OFF
cmake --build "$SRC/zstd/build-wasm" --target install

# --- OpenSSL -----------------------------------------------------------------
# Static libcrypto.a only: Ed25519 verification of .driftpkg signatures (AddonPackage.cpp). There is
# no libssl/Qt Network TLS here — the browser owns the network. linux-generic32 because there is no
# wasm target; no-secure-memory because the secure heap wants mmap/mprotect semantics wasm lacks.
clone https://github.com/openssl/openssl.git "$OPENSSL_TAG" openssl
( cd "$SRC/openssl" && make clean >/dev/null 2>&1 || true
  emconfigure ./Configure linux-generic32 --prefix="$OUT" --openssldir="$OUT/ssl" \
      no-asm no-shared no-dso no-engine no-tests no-ui-console no-afalgeng no-apps no-secure-memory \
      CC=emcc CXX=em++ AR=emar RANLIB=emranlib $COMMON_FLAGS
  # emconfigure exports CROSS_COMPILE=em, which the Makefile prefixes onto CC: "ememcc".
  sed -i 's|^CROSS_COMPILE=.*|CROSS_COMPILE=|' Makefile
  make -j"$JOBS" build_libs
  cp libcrypto.a "$OUT/lib/"
  cp -r include/openssl "$OUT/include/" )

# --- SoundTouch --------------------------------------------------------------
# Sources include <soundtouch/SoundTouch.h>; its own install puts the headers in include/soundtouch.
clone https://codeberg.org/soundtouch/soundtouch.git "$SOUNDTOUCH_TAG" soundtouch
emcmake cmake -S "$SRC/soundtouch" -B "$SRC/soundtouch/build-wasm" -G Ninja \
  -DCMAKE_INSTALL_PREFIX="$OUT" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="$COMMON_FLAGS" -DCMAKE_CXX_FLAGS="$COMMON_FLAGS" \
  -DBUILD_SHARED_LIBS=OFF -DSOUNDSTRETCH=OFF -DSOUNDTOUCH_DLL=OFF
cmake --build "$SRC/soundtouch/build-wasm" --target install

echo
echo "==> done. $OUT/lib:"
ls -1 "$OUT/lib"/*.a
