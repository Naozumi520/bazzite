#!/usr/bin/env bash
set -euo pipefail

# Fail before any package transaction if the build platform was misconfigured.
[[ "$(rpm --eval '%{_arch}')" == aarch64 ]]

# Use native Fedora repositories. Do not pull x86 akmods, Steam RPMs or i686
# libraries into this image, or silently skip missing required packages.
dnf -y --setopt=install_weak_deps=False \
    --setopt=timeout=20 --setopt=minrate=100000 \
    --setopt=retries=3 --setopt=max_parallel_downloads=10 install \
    plasma-desktop plasma-workspace plasma-workspace-wayland \
    sddm sddm-breeze konsole dolphin kde-settings \
    NetworkManager NetworkManager-wifi \
    pipewire pipewire-pulseaudio wireplumber alsa-utils \
    mesa-dri-drivers mesa-vulkan-drivers vulkan-tools glx-utils \
    xorg-x11-server-Xwayland gamescope lutris fex-emu \
    flatpak firefox xdg-user-dirs xdg-utils sudo

systemctl set-default graphical.target
systemctl enable sddm.service NetworkManager.service
install -Dm644 /ctx/arm64/README.txt /usr/share/doc/bazzite-arm64/README.txt
install -Dm644 /ctx/arm64/kdeglobals /etc/xdg/kdeglobals
install -d /usr/share/plasma/look-and-feel/org.bazzite.arm64.desktop/contents
install -m644 /ctx/arm64/defaults /usr/share/plasma/look-and-feel/org.bazzite.arm64.desktop/contents/defaults
install -m644 /ctx/arm64/metadata.json /usr/share/plasma/look-and-feel/org.bazzite.arm64.desktop/metadata.json

# Keep Fedora's ID for package tooling; expose the experimental identity only
# in the human-readable name and a separate variant marker.
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Bazzite ARM64 Experimental (Fedora bootc)"/' /usr/lib/os-release
printf '%s\n' 'experimental-arm64' > /usr/share/doc/bazzite-arm64/variant

# Make the build output reviewable without needing to pull a multi-GB image.
install -d /usr/share/doc/bazzite-arm64
rpm -qa --qf '%{NAME} %{VERSION}-%{RELEASE} %{ARCH}\n' \
    | sort > /usr/share/doc/bazzite-arm64/packages.txt
if rpm -qa --qf '%{ARCH}\n' | grep -Ev '^(aarch64|noarch)$'; then
    echo 'Foreign architecture RPM found' >&2
    exit 1
fi
rpm -q kernel-core plasma-desktop mesa-vulkan-drivers gamescope lutris fex-emu
command -v FEXInterpreter
# A Venus ICD must actually be present, not just assumed from the Mesa package.
find /usr/share/vulkan/icd.d -name '*virtio*.json' -print -quit | grep .

dnf clean all
rm -rf /var/cache/dnf /var/cache/libdnf5 /var/log/*
# bootc images populate /var at runtime; retain the base image's /var layout.
