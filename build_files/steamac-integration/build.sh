#!/usr/bin/env bash
set -euo pipefail
# This stack replaces the Fedora GL drivers as a unit. Retain the Fedora Vulkan
# software ICD for diagnostics, while selecting Venus for the normal VM session.
rm -f /usr/lib64/libgallium-26.2.6.so
install -d /etc/xdg/autostart /etc/udev/rules.d
install -m644 /ctx/integration/fx-progress.desktop /etc/xdg/autostart/
install -m644 /ctx/integration/70-fx-progress.rules /etc/udev/rules.d/
install -m644 /ctx/integration/fx-clock-sync.service /usr/lib/systemd/system/
install -m644 /ctx/integration/fx-pad.service /usr/lib/systemd/system/
install -m644 /ctx/integration/fx-pad@.service /usr/lib/systemd/system/
install -Dm644 /ctx/integration/fx-clipboard.desktop /etc/xdg/autostart/fx-clipboard.desktop
chmod 755 /usr/lib/steamac/fx-progress-agent
# Native KWin accepts the tablet; Steam updates and its dialog should run on Xwayland.
printf 'MESA_LOADER_DRIVER_OVERRIDE=zink\n' > /etc/environment.d/90-steamac.conf
ldconfig
ldd /usr/lib64/libvulkan_virtio.so /usr/lib64/libgallium-26.3.0-devel.so /usr/lib/steamac/fx-progress-agent > /tmp/native-ldd.txt
if grep -q 'not found' /tmp/native-ldd.txt; then cat /tmp/native-ldd.txt; exit 1; fi
rm /tmp/native-ldd.txt
