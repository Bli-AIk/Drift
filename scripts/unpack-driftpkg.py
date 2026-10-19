"""Unpack a Drift addon .driftpkg into a directory, for CI staging of test models and ONNX Runtime.

Checks the container digest and each file's sha256. Signatures are not verified.
Needs the `zstd` command-line tool on PATH.
"""

import hashlib
import json
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

MAGIC = b"DRIFTPKG"
FORMAT_VERSION = 1
SIGNATURE_LENGTH = 64


def fail(message: str) -> None:
    raise SystemExit(f"unpack-driftpkg: {message}")


def main() -> None:
    if len(sys.argv) != 3:
        fail("usage: unpack-driftpkg.py <package.driftpkg> <dest-dir>")
    package, dest = Path(sys.argv[1]), Path(sys.argv[2])
    blob = package.read_bytes()
    if blob[:8] != MAGIC:
        fail(f"{package} is not a .driftpkg")
    version, meta_length = struct.unpack_from("<II", blob, 8)
    if version != FORMAT_VERSION:
        fail(f"{package} uses format version {version}")
    meta_end = 16 + meta_length
    metadata = json.loads(blob[16:meta_end])
    compressed_length, raw_length = struct.unpack_from("<QQ", blob, meta_end)
    payload_start = meta_end + 16
    payload_end = payload_start + compressed_length
    if len(blob) < payload_end + 32:
        fail(f"{package} is truncated")

    digest = hashlib.sha256(blob[:payload_end]).digest()
    if digest != blob[payload_end:payload_end + 32]:
        fail(f"{package} digest mismatch")

    with tempfile.TemporaryDirectory() as tmp:
        compressed = Path(tmp) / "payload.zst"
        raw = Path(tmp) / "payload.raw"
        compressed.write_bytes(blob[payload_start:payload_end])
        subprocess.run(
            ["zstd", "-d", "-q", "-f", "--long=27", str(compressed), "-o", str(raw)],
            check=True,
        )
        payload = raw.read_bytes()
    if len(payload) != raw_length:
        fail(f"{package} decompressed to {len(payload)} bytes, expected {raw_length}")

    entries = metadata["files"]
    for entry in entries:
        name = entry["path"]
        parts = name.replace("\\", "/").split("/")
        if name.startswith(("/", "\\")) or ":" in name or ".." in parts:
            fail(f"unsafe path in package: {name!r}")
        data = payload[entry["offset"]:entry["offset"] + entry["size"]]
        if len(data) != entry["size"] or hashlib.sha256(data).hexdigest() != entry["sha256"]:
            fail(f"sha256 mismatch for {name}")
        target = dest / Path(*parts)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)

    print(f"unpacked {metadata['id']} {metadata['version']}: {len(entries)} files -> {dest}")


if __name__ == "__main__":
    main()
