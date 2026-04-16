#!/usr/bin/bash
set -eoux pipefail

echo "::group:: Sanity checks"

REQUIRED_PACKAGES=(
    hyprland
    hyprlock
    hypridle
    hyprpaper
    xdg-desktop-portal-hyprland
    dms
    dgop
    danksearch
    quickshell-git
    greetd
    tuigreet
    pipewire
    wireplumber
    kitty
    fish
    cliphist
    matugen
    lm_sensors
    tuned-ppd
    satty
    nwg-look
    gpu-screen-recorder
    material-symbols-fonts
    pinentry-qt
    accountsservice
)

for package in "${REQUIRED_PACKAGES[@]}"; do
    rpm -q "${package}" >/dev/null || { echo "Missing package: ${package}"; exit 1; }
done

# Check DankMaterialShell installed via quickshell config path
test -d /usr/share/quickshell/dms || { echo "DankMaterialShell not installed at /usr/share/quickshell/dms"; exit 1; }

# Check default configs
test -f /etc/skel/.config/hypr/hyprland.conf || { echo "Missing hyprland config"; exit 1; }
test -f /etc/greetd/config.toml || { echo "Missing greetd config"; exit 1; }

# Check services
systemctl is-enabled greetd.service >/dev/null || { echo "greetd not enabled"; exit 1; }
systemctl is-enabled NetworkManager.service >/dev/null || { echo "NetworkManager not enabled"; exit 1; }
systemctl is-enabled tuned-ppd.service >/dev/null || { echo "tuned-ppd not enabled"; exit 1; }

echo "All checks passed."
echo "::endgroup::"
