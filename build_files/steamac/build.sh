#!/usr/bin/env bash
set -euo pipefail
[[ "$(rpm --eval '%{_arch}')" == aarch64 ]]
dnf -y --setopt=install_weak_deps=False --setopt=timeout=20 \
    --setopt=minrate=100000 install \
    gtk2 openal-soft libssh2 pciutils plasma-pa upower glibc-langpack-en
install -Dm755 /ctx/steamac/steam-arm64 /usr/bin/steam-arm64
ln -s steam-arm64 /usr/bin/steam
install -Dm755 /ctx/steamac/steam-arm64-bootstrap.py /usr/libexec/steam-arm64-bootstrap
install -Dm644 /ctx/steamac/steam-arm64.desktop /usr/share/applications/steam-arm64.desktop
printf 'LANG=C.UTF-8\n' > /etc/locale.conf
# FEX must own x86 binfmt handlers; the Fedora base also bundles QEMU handlers.
# Mask only those conflicting definitions, preserving other architectures.
install -d /etc/binfmt.d
for arch in i386 i486 x86_64; do
    ln -sfn /dev/null "/etc/binfmt.d/qemu-${arch}-static.conf"
done
rpm -qa --qf '%{NAME} %{VERSION}-%{RELEASE} %{ARCH}\n' \
    | sort > /usr/share/doc/bazzite-arm64/packages.txt
# This image is a single-user VM guest. No password or SSH key is shipped.
install -d /etc/sddm.conf.d /etc/environment.d /etc/xdg/autostart
printf '[Autologin]\nUser=bazzite\nSession=plasma.desktop\nRelogin=false\n' > /etc/sddm.conf.d/90-steamac.conf
printf 'MESA_LOADER_DRIVER_OVERRIDE=zink\n' > /etc/environment.d/90-steamac.conf
install -Dm644 /ctx/steamac/steam-arm64-autostart.desktop /etc/xdg/autostart/steam-arm64.desktop
# Fedora's initramfs has its own bootc root discovery. Do not use SteamOS's layer.
# Release guests have no remote login service; test disks can enable it explicitly.
systemctl disable sshd.service sshd.socket || true
dnf clean all
# /var is empty on first boot. Package state belongs in /usr or tmpfiles rules.
find /var/cache /var/log -mindepth 1 -delete
