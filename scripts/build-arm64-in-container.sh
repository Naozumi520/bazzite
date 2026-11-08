#!/usr/bin/env bash
# Called by build-arm64-local.sh inside its privileged ARM64 Linux container.
set -euo pipefail
# VFS avoids overlay-on-overlay xattr failures in Docker Desktop.
podman_cmd=(podman --root /var/lib/containers/storage-vfs --storage-driver=vfs --events-backend=file)
mkdir -p /var/lib/containers/arm64-dnf-cache
"${podman_cmd[@]}" build \
    --isolation=chroot --platform linux/arm64 --cap-add=all \
    --volume /var/lib/containers/arm64-dnf-cache:/var/cache/libdnf5 \
    --security-opt label=disable --build-arg "REVISION=$BUILD_REVISION" \
    -f Containerfile.arm64 -t localhost/bazzite-arm64:experimental .
"${podman_cmd[@]}" image inspect localhost/bazzite-arm64:experimental > /out/image-inspect.json
[[ "$("${podman_cmd[@]}" image inspect localhost/bazzite-arm64:experimental --format '{{.Architecture}}')" == arm64 ]]
"${podman_cmd[@]}" run --rm --cgroups=disabled --entrypoint cat \
    localhost/bazzite-arm64:experimental \
    /usr/share/doc/bazzite-arm64/packages.txt > /out/packages.txt
"${podman_cmd[@]}" save --format oci-archive -o /out/bazzite-arm64.oci.tar.partial \
    localhost/bazzite-arm64:experimental
mv /out/bazzite-arm64.oci.tar.partial /out/bazzite-arm64.oci.tar
cd /out
sha256sum bazzite-arm64.oci.tar > SHA256SUMS
printf '%s\n' "$BUILD_REVISION" > source-revision.txt
