set -euo pipefail
export CARGO_HOME=/tmp/cargo
export RUSTUP_HOME=/tmp/rustup
dnf -y --setopt=install_weak_deps=False --setopt=timeout=20 install gcc gcc-c++ meson ninja-build python3-mako python3-pyyaml python3-packaging libdrm-devel wayland-devel wayland-protocols-devel libX11-devel libxcb-devel libxshmfence-devel libXrandr-devel libXext-devel libXfixes-devel libXxf86vm-devel libglvnd-devel xcb-proto xorg-x11-proto-devel vulkan-headers systemd-devel libzstd-devel expat-devel zlib-ng-compat-devel bison flex rust cargo git patch
cp -a /agent /tmp/agent
cargo test --manifest-path /tmp/agent/Cargo.toml --release --locked
cargo build --manifest-path /tmp/agent/Cargo.toml --release --locked
install -Dm755 /tmp/agent/target/release/fx-progress-agent /out/fx-progress-agent
source /common.sh
build_venus /tmp/venus lib64 /tmp/dest-venus
install -Dm755 /tmp/dest-venus/usr/lib64/libvulkan_virtio.so /out/mesa/usr/lib64/libvulkan_virtio.so
install -Dm644 /tmp/dest-venus/usr/share/vulkan/icd.d/virtio_icd.aarch64.json /out/mesa/usr/share/vulkan/icd.d/virtio_icd.aarch64.json
build_gl /tmp/gl lib64 /tmp/dest-gl
install_gl /tmp/dest-gl lib64 /out/mesa
