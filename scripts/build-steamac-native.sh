#!/usr/bin/env bash
# Usage: build-steamac-native.sh /path/to/steamac-fork
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
steamac=$(cd "${1:?Path to steamac fork required}" && pwd)
[[ -z "$(git -C "$steamac" status --porcelain --untracked-files=no)" ]] || { echo 'Commit steamac changes first.' >&2; exit 1; }
mkdir -p "$repo/arm64-output/steamac-native" "$repo/arm64-output/mesa-src"
# Exact Mesa and Venus protocol inputs used by the launcher/kernel.
fetch() {
    local dir=$1 url=$2 commit=$3
    mkdir -p "$dir"
    if [[ ! -d "$dir/.git" ]]; then git -C "$dir" init -q; git -C "$dir" remote add origin "$url"; fi
    git -C "$dir" fetch --depth 1 origin "$commit"
    git -C "$dir" checkout --detach "$commit"
}
fetch "$repo/arm64-output/mesa-src" https://gitlab.freedesktop.org/mesa/mesa.git 4cf0989083d25b92d02c6fef2bed934ad77b4ecd
fetch "$repo/arm64-output/mesa-src/subprojects/venus-protocol-1.1.3" https://gitlab.freedesktop.org/virgl/venus-protocol.git ca19b6358d7cc491bc3e4de76f04c6700876a8fa
docker run --rm --platform linux/arm64 \
    -v "$repo/arm64-output/mesa-src:/src/mesa:ro" -v "$steamac/guest/mesa/patches:/patches:ro" \
    -v "$steamac/guest/mesa/container/common.sh:/common.sh:ro" -v "$steamac/guest/progress-agent:/agent:ro" \
    -v "$repo/build_files/steamac-integration/build-native.sh:/build.sh:ro" \
    -v "$repo/arm64-output/steamac-native:/out" \
    --entrypoint bash localhost/bazzite-steamac:experimental /build.sh
git -C "$steamac" rev-parse HEAD > "$repo/arm64-output/steamac-native/steamac-revision.txt"
