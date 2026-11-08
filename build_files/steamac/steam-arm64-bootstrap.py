#!/usr/bin/env python3
"""Fetch only Valve's native bootstrap; the client manages later updates.

The selected package SHA-256 is checked against Valve's HTTPS manifest. This
is not an independent signature verification. No client binaries are bundled
in this repository or accepted from a third-party mirror.
"""
from __future__ import annotations

import hashlib
import io
import json
import os
from pathlib import Path
import re
import struct
import tempfile
import urllib.request
import zipfile

BASE = "https://client-update.steamstatic.com/"
MANIFEST = "steam_client_steamdeck_stable_linuxarm64"
PACKAGE = "bins_linuxarm64_linuxarm64"
MEMBER = "steamrtarm64/steam"


def main() -> None:
    root = Path.home() / ".local/share/Steam"
    target = root / MEMBER
    if target.exists():
        raise SystemExit(f"Refusing to overwrite {target}")
    with urllib.request.urlopen(BASE + MANIFEST, timeout=60) as response:
        manifest = response.read(2_000_001)
    if len(manifest) > 2_000_000:
        raise SystemExit("Steam manifest exceeds expected size")
    match = re.search(r'"' + PACKAGE + r'"\s*\{([^{}]*)\}', manifest.decode())
    if not match:
        raise SystemExit("Valve's manifest has no native ARM64 client package")
    fields = dict(re.findall(r'"([^"\n]+)"\s+"([^"\n]*)"', match[1]))
    filename, digest = fields["file"], fields["sha2"]
    if not re.fullmatch(r"[A-Za-z0-9_.-]+", filename):
        raise SystemExit("Invalid package filename")
    if not re.fullmatch(r"[a-f0-9]{64}", digest):
        raise SystemExit("Invalid SHA-256")
    print(f"Downloading Valve ARM64 bootstrap: {filename}", flush=True)
    with urllib.request.urlopen(BASE + filename, timeout=120) as response:
        payload = response.read(300_000_001)
    if len(payload) > 300_000_000 or hashlib.sha256(payload).hexdigest() != digest:
        raise SystemExit("Steam package size/hash verification failed")
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        if archive.getinfo(MEMBER).file_size > 50_000_000:
            raise SystemExit("Bootstrap exceeds expected size")
        binary = archive.read(MEMBER)
    # Do not trust a filename containing 'arm64': older bootstrap packages are x86.
    if len(binary) < 20 or binary[:6] != b"\x7fELF\x02\x01" or struct.unpack_from("<H", binary, 18)[0] != 183:
        raise SystemExit("Bootstrap is not a little-endian ARM64 ELF executable")
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix=".steam-arm64-", dir=target.parent)
    try:
        with os.fdopen(fd, "wb") as output:
            output.write(binary)
            os.fchmod(output.fileno(), 0o755)
        # link() is atomic and fails if another bootstrap won the race.
        os.link(temp, target)
    finally:
        os.unlink(temp)
    receipt = {"manifest": BASE + MANIFEST, "package": filename, "sha256": digest}
    (root / "arm64-bootstrap.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(f"Installed {target}")


if __name__ == "__main__":
    main()
