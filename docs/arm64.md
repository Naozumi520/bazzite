# Experimental ARM64 guest

This is a partial port based on Fedora 45 bootc. The upstream x86 build remains
separate. Fedora is pinned by digest in `Containerfile.arm64`, with KDE Plasma,
Bazzite's convergence wallpaper, Mesa/Venus, gamescope, Lutris and FEX. Required
RPMs must be aarch64/noarch; missing packages are not silently skipped.

## Build sequence on Apple Silicon

With Docker Desktop, Git and QEMU installed:

```sh
./scripts/build-arm64-local.sh
./scripts/build-steamac-image.sh
./scripts/build-steamac-native.sh /path/to/Naozumi520-steamac-fork
./scripts/build-steamac-integrated.sh
STEAMAC_DISK_OUTPUT="$PWD/arm64-output/steamac-integrated/disk" ./scripts/build-steamac-disk.sh
STEAMAC_DISK_OUTPUT="$PWD/arm64-output/steamac-integrated/disk" ./scripts/export-steamac-release.sh BUILD_ID
```

Commit source changes before image builds. Output folders are gitignored. Scripts
refuse to overwrite final archives/disks. `build-arm64-local.sh` exports an OCI
archive; the derivative scripts export Docker archives for bootc-image-builder's
Podman store. Load the appropriate archive with Podman or Docker.

`build-steamac-native.sh` compiles the fork's guest agent and the exact steamac
Mesa/Venus source plus backports against Fedora dependencies. It does not copy
Arch userspace libraries into Fedora. The integrated target installs that Mesa
stack, progress/clipboard agents, clock synchronization and controller services.
Stock Fedora Mesa lacks the required virtio blob alignment support and has shown
GPU allocation failures; it is not the final steamac driver stack.

The disk builder creates a fresh bootc disk with a local `bazzite` user, automatic
KDE login, no password or SSH key, and SSH disabled. The Steam launcher downloads
and verifies Valve's native ARM64 bootstrap from its HTTPS update manifest, then
Valve's updater manages the client. No Steam account or binaries are bundled.
Do not distribute a disk that has been used for testing or Steam login.

The exporter records the deployment's real root/boot UUIDs and ostree path. It
emits `bazzite-steamac.json`, `bazzite-steamac.img.gz`, `Image`, `initramfs.img`
and `SHA256SUMS`. Publish them together in a prerelease on Naozumi520/bazzite.
The steamac fork's picker detects compatible manifests; downloading verifies
asset size and SHA-256 before installing a sparse disk. The `.bazzite` folder
beside the installed disk contains its boot files and must move with it.

`export-steamac-release.sh` currently takes its matching kernel from the installed
FX Steam Launcher. The reference launcher is fxgl/steamac
`3b62cbe47084a0e38ba241b93212f68b6449f2f8`, kernel 7.2.9-steamac, 4K pages.
The host app and guest kernel/graphics stack must be kept matched. Fedora's
initramfs discovers bootc directly; SteamOS's A/B initramfs and Arch `/usr` layer
are not attached to Bazzite.

## Validation and limitations

The original foundation archive was built from
`9ba19558d1311521f9c086787674a290b0f4915e`, size 1,898,339,840 bytes,
SHA-256 `90433d8db212635b5cae93e0a4dfc610e0675dba3d3663eee3d2868ef43340cb`.
bootc lint passed 12 checks, skipped 1, and warned about `/var` contents and
missing tmpfiles entries. This is build validation, not game validation.

Local tests established:

- Generic QEMU/HVF UEFI boot with Fedora kernel, running system, SDDM and
  enforcing SELinux, with a real login-screen capture.
- libkrun/steamac boot with its 4K kernel and Fedora initramfs; KDE desktop.
- Venus/MoltenVK detects Apple M5 Max; a Vulkan cube rendered successfully.
- FEX 2604 runs an x86-64 Fedora shell using a minimal test rootfs.
- Native ARM64 Steam updates itself and displays Big Picture sign-in.
- The steamac fork's guest agent passes 80 tests; release validation tests cover
  trusted URLs, streaming hashes, bounded sparse extraction, cancellation,
  existing-file preservation and guest boot routing.

The minimal FEX test rootfs is not shipped or a complete i686 gaming runtime.
Steam login, Proton/Windows games, sustained graphics stability, gamepad/audio,
suspend, disk growth and bootc update/rollback require end-to-end validation.
The custom steamac kernel lacks SELinux support, so the steamac-only manifest
uses `selinux=0`; generic Fedora UEFI testing retained enforcing SELinux. Do not
apply deployment-changing bootc updates until matching boot-file sidecar refresh
and rollback handling exist. This is not an installer ISO or bare-metal Apple
Silicon distribution. Do not rebase an existing installation to this port.

The GitHub ARM64 Actions workflow was blocked before starting by an account
billing lock. Local builds work independently; no successful Actions/GHCR build
is claimed. Local app packaging is ad-hoc signed and not Developer ID notarized.
