#!/usr/bin/env bash
# Native macOS/Linux ARM64 build, using an isolated Podman store inside Docker.
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
out=${ARM64_OUTPUT_DIR:-"$repo/arm64-output"}
store=${ARM64_BUILD_VOLUME:-bazzite-arm64-build-storage}
builder=quay.io/podman/stable@sha256:f7a17ef911a2b9b866ada8a9426a07e29a6e4f8109ef8c0e0b7010c2541b4e49
revision=$(git -C "$repo" rev-parse HEAD)
if [[ -n "$(git -C "$repo" status --porcelain --untracked-files=normal)" ]]; then
    echo 'Commit source changes before producing a release artifact.' >&2
    exit 1
fi
[[ "$(docker info --format '{{.Architecture}}')" == aarch64 ]]
mkdir -p "$out"
# No existing image or disk is overwritten implicitly.
[[ ! -e "$out/bazzite-arm64.oci.tar" ]]
docker run --rm --privileged \
    -v "$store:/var/lib/containers" -v "$repo:/src:ro" -v "$out:/out" \
    -e "BUILD_REVISION=$revision" -w /src "$builder" \
    bash /src/scripts/build-arm64-in-container.sh
