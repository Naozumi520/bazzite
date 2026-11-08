#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo"
[[ -z "$(git status --porcelain)" ]] || { echo 'Commit source changes first.' >&2; exit 1; }
revision=$(git rev-parse HEAD)
steamac_revision=$(cat arm64-output/steamac-native/steamac-revision.txt)
[[ "$steamac_revision" =~ ^[0-9a-f]{40}$ ]]
out=arm64-output/steamac-integrated
mkdir -p "$out"
[[ ! -e "$out/image.tar" ]] || { echo 'Archive already exists.' >&2; exit 1; }
docker build --platform linux/arm64 --build-context native=arm64-output/steamac-native \
    --build-arg "REVISION=$revision" --build-arg "STEAMAC_REVISION=$steamac_revision" \
    -f Containerfile.steamac-integrated -t localhost/bazzite-steamac:integrated .
docker save -o "$out/image.tar.partial" localhost/bazzite-steamac:integrated
mv "$out/image.tar.partial" "$out/image.tar"
(cd "$out" && shasum -a 256 image.tar > SHA256SUMS)
printf '%s\n' "$revision" > "$out/source-revision.txt"
