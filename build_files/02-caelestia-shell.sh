#!/usr/bin/bash
set -eoux pipefail

echo "::group:: Build and install niri-caelestia-shell"

SHELL_DIR="/tmp/niri-caelestia-shell"
git clone https://github.com/AyushKr2003/niri-caelestia-shell.git "$SHELL_DIR"
cd "$SHELL_DIR"
git tag -f 1.0.0 2>/dev/null || true

cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DINSTALL_QSCONFDIR=/usr/share/quickshell/niri-caelestia-shell

cmake --build build
cmake --install build
rm -rf "$SHELL_DIR"

# Rebuild font cache (material-symbols-fonts RPM was installed in 01-packages.sh)
fc-cache -f

# Remove build-time packages to keep image small
rpm -e --nodeps cmake ninja-build gcc-c++ cpp gcc \
    qt6-qtdeclarative-devel qt6-qtbase-devel qt6-qtmultimedia-devel \
    kf6-networkmanager-qt-devel \
    pipewire-devel aubio-devel \
    libqalculate-devel libcava-devel \
    kernel-headers glibc-devel libstdc++-devel \
    2>/dev/null || true

echo "::endgroup::"
