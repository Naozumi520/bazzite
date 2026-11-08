# Experimental ARM64 work

Source: [`codex/arm64-port`](https://github.com/Naozumi520/bazzite/tree/codex/arm64-port).
Launcher: [`Naozumi520/steamac:codex/bazzite-arm64`](https://github.com/Naozumi520/steamac/tree/codex/bazzite-arm64).

This partial port builds Fedora 45 bootc with KDE Plasma, native Mesa/Venus,
gamescope, Lutris, FEX and a native ARM64 Steam bootstrap. A separate steamac
backend uses Fedora's bootc initramfs and a matched 4K libkrun kernel; its original
first-run interface offers SteamOS or Bazzite and downloads versioned guest
builds from this fork's GitHub Releases.

Generic UEFI and steamac boots, KDE, a Venus/MoltenVK Vulkan cube, FEX x86-64
shell execution and the native Steam Big Picture sign-in screen were validated.
Steam/Proton gameplay and full Bazzite/SteamOS feature parity are not established.
A build that displays Steam is not yet a supported gaming distribution.

See [build instructions and validation limits](docs/arm64.md).
