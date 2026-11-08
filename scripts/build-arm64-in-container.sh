#!/usr/bin/env bash
# Called by build-arm64-local.sh inside its privileged ARM64 Linux container.
set -euo pipefail
podman --storage-driver=overlay --events-backend=file build \
    --isolation=chroot --platform linux/arm64 --cap-add=all \
    --security-opt label=disable --build-arg "REVISION=$BUILD_REVISION" \
    -f Containerfile.arm64 -t localhost/bazzite-arm64:experimental .
podman image inspect localhost/bazzite-arm64:experimental > /out/image-inspect.json
[[ "$(podman image inspect localhost/bazzite-arm64:experimental --format '{{.Architecture}}')" == arm64 ]]
podman run --rm --cgroups=disabled --entrypoint cat \
    localhost/bazzite-arm64:experimental \
    /usr/share/doc/bazzite-arm64/packages.txt > /out/packages.txt
podman save --format oci-archive -o /out/bazzite-arm64.oci.tar.partial \
    localhost/bazzite-arm64:experimental
mv /out/bazzite-arm64.oci.tar.partial /out/bazzite-arm64.oci.tar
cd /out
sha256sum bazzite-arm64.oci.tar > SHA256SUMS
printf '%s\n' "$BUILD_REVISION" > source-revision.txt
