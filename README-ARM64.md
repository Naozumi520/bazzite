# Experimental ARM64 work

This fork's ARM64 work is on [`codex/arm64-port`](https://github.com/Naozumi520/bazzite/tree/codex/arm64-port).

An experimental Fedora 45 bootc foundation has been built natively for ARM64,
including KDE, Mesa/Venus, gamescope, Lutris and FEX. It is **not a complete
Bazzite port or a bootable steamac replacement**. Steam/Proton, an x86 FEX rootfs,
Game Mode and steamac's guest integration remain to be ported.

See [build instructions and steamac compatibility details](docs/arm64.md).

Verified local build source: `9ba19558d1311521f9c086787674a290b0f4915e`.
OCI archive SHA-256: `90433d8db212635b5cae93e0a4dfc610e0675dba3d3663eee3d2868ef43340cb`.
Archive size: 1,898,339,840 bytes. bootc lint passed 12 checks, skipped 1,
and reported 2 warnings about `/var` content and tmpfiles entries. No OS boot
or game test has been performed. No GHCR image has been published because the
GitHub runner was blocked before starting by an account billing lock.
