#!/usr/bin/env bash
# Create a fresh distribution disk: never export a disk used for local testing.
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo"
out="${STEAMAC_DISK_OUTPUT:-$repo/arm64-output/steamac-release}"
mkdir -p "$out"
[[ ! -e "$out/qcow2/disk.qcow2" ]] || { echo 'Disk exists; choose a new output directory.' >&2; exit 1; }
cat > "$out/config.json" <<'JSON'
{"customizations":{"user":[{"name":"bazzite","groups":["wheel"]}],"filesystem":[{"mountpoint":"/","minsize":"40 GiB"}],"kernel":{"append":"console=hvc0"}}}
JSON
docker run --rm --privileged --name bazzite-steamac-release-builder \
    -v bazzite-steamac-release-storage:/var/lib/containers/storage \
    -v bazzite-arm64-osbuild:/store \
    -v "$repo/arm64-output/steamac-integrated:/input:ro" \
    -v "$out:/output" \
    --entrypoint sh localhost/bazzite-arm64-disk-tools:nested -c '
      set -eu
      rm -rf /run/containers/storage /run/libpod
      mkdir -p /etc/containers
      printf "[storage]\ndriver=\"overlay\"\nrunroot=\"/run/containers/storage\"\ngraphroot=\"/var/lib/containers/storage\"\n" > /etc/containers/storage.conf
      podman load -i /input/image.tar
      cp /output/config.json /config.json
      bootc-image-builder build --type qcow2 --rootfs ext4 --output /output --store /store --progress verbose localhost/bazzite-steamac:integrated
    '
