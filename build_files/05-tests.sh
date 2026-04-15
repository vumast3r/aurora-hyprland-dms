#!/usr/bin/bash
set -eoux pipefail

echo "::group:: Sanity checks"

REQUIRED_PACKAGES=(
    niri
    quickshell-git
    greetd
    tuigreet
    pipewire
    wireplumber
    kitty
    fish
    cliphist
    matugen
    xwayland-satellite
)

for package in "${REQUIRED_PACKAGES[@]}"; do
    rpm -q "${package}" >/dev/null || { echo "Missing package: ${package}"; exit 1; }
done

# Check that caelestia-shell was installed
test -d /usr/share/quickshell/niri-caelestia-shell || { echo "niri-caelestia-shell not installed"; exit 1; }

# Check wayland session file
test -f /usr/share/wayland-sessions/niri-caelestia.desktop || { echo "Missing wayland session desktop file"; exit 1; }

# Check Material Symbols font
test -f /usr/share/fonts/material-symbols/MaterialSymbolsRounded.ttf || { echo "Missing Material Symbols font"; exit 1; }

# Check default configs
test -f /etc/skel/.config/niri/config.kdl || { echo "Missing niri config"; exit 1; }
test -f /etc/skel/.config/caelestia/shell.json || { echo "Missing caelestia config"; exit 1; }

# Check services
systemctl is-enabled greetd.service >/dev/null || { echo "greetd not enabled"; exit 1; }
test -f /etc/greetd/config.toml || { echo "Missing greetd config"; exit 1; }
systemctl is-enabled NetworkManager.service >/dev/null || { echo "NetworkManager not enabled"; exit 1; }

echo "All checks passed."
echo "::endgroup::"
