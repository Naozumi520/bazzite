#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo"
revision=$(git rev-parse HEAD)
[[ -z "$(git status --porcelain)" ]] || { echo 'Commit source changes first.' >&2; exit 1; }
# SHA256SUMS is relative to its output folder.
(cd arm64-output && shasum -a 256 -c SHA256SUMS)
if ! docker image inspect localhost/bazzite-arm64:experimental >/dev/null 2>&1; then
    docker load -i arm64-output/bazzite-arm64.oci.tar
fi
docker build --platform linux/arm64 --build-arg "REVISION=$revision" \
    -f Containerfile.steamac -t localhost/bazzite-steamac:experimental .
mkdir -p arm64-output/steamac
[[ ! -e arm64-output/steamac/image.tar ]] || { echo 'Image archive already exists.' >&2; exit 1; }
docker save -o arm64-output/steamac/image.tar.partial localhost/bazzite-steamac:experimental
mv arm64-output/steamac/image.tar.partial arm64-output/steamac/image.tar
(cd arm64-output/steamac && shasum -a 256 image.tar > SHA256SUMS)
