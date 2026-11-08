# Experimental ARM64 foundation

This fork adds `Containerfile.arm64` and an independent native ARM64 workflow.
It is a **partial port / development foundation**, not a feature-equivalent
Bazzite release. The upstream x86 build is unchanged.

The base is Fedora 45 bootc, pinned by manifest digest, with the Fedora kernel,
KDE Plasma, Bazzite's convergence wallpaper, native Mesa (including the Venus
ICD), gamescope, Lutris and FEX. All RPMs must be aarch64 or noarch. Required
packages are not silently skipped. Build-time validation checks these packages,
the Venus ICD, OCI architecture and `bootc container lint`.

There is no bundled Steam client, Proton, FEX x86 rootfs, configured binfmt
execution, Bazzite Game Mode, third-party akmods, or Bazzite updater integration.
Installing FEX alone does not make x86 games runnable. No VM boot or game test
has been performed. The image is not signed and is published with explicitly
experimental tags, never the upstream Bazzite stable tags.

## Build

On an aarch64 Linux machine with Podman (or inside a privileged Linux VM on macOS):

```sh
sudo podman build --platform linux/arm64 --cap-add=all \
  --security-opt label=disable -f Containerfile.arm64 \
  -t localhost/bazzite-arm64:experimental .
```

On an Apple Silicon Mac with Docker running, the equivalent reproducible local
build is:

```sh
./scripts/build-arm64-local.sh
```

It uses a separate Docker volume for the Podman image store, requires committed
sources, and exports `arm64-output/bazzite-arm64.oci.tar`, `SHA256SUMS`, package
inventory, image metadata and source revision. It refuses to overwrite an
existing final archive. Load the archive on an ARM64 Linux machine with
`sudo podman load -i bazzite-arm64.oci.tar`. Docker is used as the Linux build VM;
this operating system image is intended for bootc, not as an ordinary desktop
application container.

The `Build ARM64 experimental` GitHub workflow uses `ubuntu-24.04-arm` and pushes
`ghcr.io/naozumi520/bazzite-arm64:experimental` plus an immutable `sha-<commit>`
tag when GitHub Actions and package publishing are available for the account.
The first attempt did not start because GitHub reported an account billing lock;
local builds do not require GitHub Actions. Its downloadable build manifest records the package list, image metadata
and pushed digest. A successful build validates container construction; it does
not establish that the operating system boots or games work.

This is a bootc OCI image, not an installer ISO or `steamos.img`. Creating a
bootable UEFI disk requires bootc-image-builder and an explicit account/SSH
configuration. That separate step must be followed by a VM boot test. Do not
rebase an existing Bazzite installation to this incomplete image.

## steamac target

Reviewed against fxgl/steamac commit
`3b62cbe47084a0e38ba241b93212f68b6449f2f8` and Bazzite commit
`a6344eff701f5e38a443d6d9a6c6e37048f93ea7`.

steamac is not a generic UEFI VM launcher. Its guest is Valve's ARM64 SteamOS
image with a custom 4K-page kernel, libkrun, a Mesa/Venus layer, and an initramfs
that expects SteamOS partitions named `esp`, `efi-A/B`, `rootfs-A/B`, `var-A/B`
and `home`. It uses SteamOS bootconf, RAUC/atomupd, and SteamOS-specific services.
Its image receipt and release checks also bind the expected guest inputs.

**Do not rename this image to `steamos.img`, or reuse steamac's current initramfs
or `/usr` layer with it.** Fedora's bootc deployment and SteamOS's A/B update
layout are different, and Arch-built libraries in steamac's layer cannot be
assumed compatible with Fedora.

Remaining work for a working steamac guest:

1. Add a separate Fedora/bootc guest backend to steamac, including disk layout,
   boot/initramfs, persistent state and update/rollback handling.
2. Port/build its custom 4K kernel with the libkrun, virtio-gpu, vsock and Apple
   TSO patches; validate interaction with Fedora's systemd/SELinux.
3. Build its patched guest Mesa/Venus and helper agents for Fedora, rather than
   copying the SteamOS binary layer. Validate Venus against its macOS renderer.
4. Integrate a maintained FEX rootfs, binfmt and a supported Steam/Proton launch
   path; package dependencies, licenses and updates must be handled explicitly.
5. Add a gamescope session and adapt progress, clipboard, audio/input, suspend,
   desktop switching and other launcher guest services.
6. Boot on Apple Silicon and test Vulkan, desktop mode, Steam login, a game,
   disk persistence and update/rollback before calling this supported.

These are open engineering tasks, not capabilities supplied by the current
container. The Fedora kernel in this foundation is for generic ARM64 UEFI
experiments; it is not an Apple Silicon bare-metal kernel or steamac's kernel.
