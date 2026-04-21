#!/usr/bin/bash
set -eoux pipefail

echo "::group:: Build hyprscroller plugin from source"

# hyprscroller (dawsers/hyprscroller) isn't packaged in solopasha/hyprland
# COPR, so we compile it against the hyprland-devel headers from the same
# COPR and drop the toolchain before the layer is committed.

BUILD_DEPS=(git make gcc gcc-c++ pkgconf hyprland-devel)

dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:solopasha:hyprland" \
    "${BUILD_DEPS[@]}"

# Pin so rebuilds are reproducible; bump deliberately when upstream
# introduces useful changes.
HYPRSCROLLER_REV="${HYPRSCROLLER_REV:-main}"

git clone --depth 1 --branch "${HYPRSCROLLER_REV}" \
    https://github.com/dawsers/hyprscroller.git /tmp/hyprscroller
make -C /tmp/hyprscroller all

# The Makefile output name varies across revisions (hyprscroller.so vs
# libhyprscroller.so). Locate whatever it emitted and install it under
# the stable name the hyprland.conf references.
PLUGIN_SO="$(find /tmp/hyprscroller -maxdepth 2 -name '*.so' -type f | head -n 1)"
[[ -n "${PLUGIN_SO}" ]] || { echo "hyprscroller build produced no .so"; exit 1; }
install -Dm755 "${PLUGIN_SO}" /usr/lib64/hyprland-plugins/libhyprscroller.so

# Shed build toolchain to keep the image slim. Removing -devel doesn't
# pull out hyprland itself (the -devel subpackage Requires hyprland, not
# the other way around).
dnf5 -y remove "${BUILD_DEPS[@]}"
rm -rf /tmp/hyprscroller

echo "::endgroup::"
