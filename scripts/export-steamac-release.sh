#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo"
build=${1:?usage: export-steamac-release.sh BUILD_ID}
[[ "$build" =~ ^[a-zA-Z0-9._-]+$ ]] || { echo 'Invalid build id' >&2; exit 1; }
revision=$(docker image inspect localhost/bazzite-steamac:integrated --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')
vm="${STEAMAC_DISK_OUTPUT:-$repo/arm64-output/steamac-release}"
[[ ! -e "$vm/disk.raw" && ! -e "$vm/assets" ]] || { echo 'Export exists; use a new fresh build.' >&2; exit 1; }
qemu-img convert -f qcow2 -O raw "$vm/qcow2/disk.qcow2" "$vm/disk.raw"
cp -c '/Applications/FX Steam Launcher.app/Contents/Resources/Image' "$vm/Image"
docker run --rm --privileged \
    -v "$vm:/output" -v "$repo/scripts:/scripts:ro" \
    --entrypoint bash localhost/bazzite-arm64-disk-tools:nested -c '
      set -euo pipefail
      mkdir -p /mnt/release-boot
      offset=$(sfdisk --json /output/disk.raw | python3 -c '\''import json,sys; print(json.load(sys.stdin)["partitiontable"]["partitions"][1]["start"]*512)'\'')
      loop=$(losetup --find --show --read-only --offset "$offset" /output/disk.raw)
      trap '\''umount /mnt/release-boot 2>/dev/null || true; losetup -d "$loop"'\'' EXIT
      mount -o ro,noload "$loop" /mnt/release-boot
      python3 /scripts/export-steamac-release.py --disk /output/disk.raw --boot /mnt/release-boot \
        --kernel /output/Image --output /output/assets --build "$1" --revision "$2"
    ' bash "$build" "$revision"
