#!/usr/bin/bash
set -eoux pipefail

echo "::group:: Install niri-caelestia packages"

# Enable danklinux COPR (quickshell-git, cliphist, matugen)
dnf5 -y copr enable avengemedia/danklinux
dnf5 -y copr disable avengemedia/danklinux

NIRI_PACKAGES=(
    # Compositor
    niri
    xwayland-satellite
    # Shell framework (from danklinux COPR)
    quickshell-git
    # Desktop portals & session
    xdg-desktop-portal
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    gnome-keyring
    gnome-keyring-pam
    polkit
    # Audio & media
    pipewire
    wireplumber
    pipewire-pulseaudio
    pipewire-libs
    cava
    aubio
    pavucontrol
    playerctl
    # Display & brightness
    brightnessctl
    ddcutil
    # Networking
    NetworkManager
    NetworkManager-wifi
    bluez
    # Clipboard & screenshots
    wl-clipboard
    cliphist
    grim
    swappy
    # Terminal & file manager
    kitty
    Thunar
    thunar-archive-plugin
    # Shell scripting runtime
    fish
    bash
    curl
    jq
    # OCR & utilities
    tesseract
    tesseract-langpack-eng
    libqalculate
    qalculate-gtk
    lm_sensors
    # Theming (from danklinux COPR)
    matugen
    # Fonts
    jetbrains-mono-fonts-all
    google-noto-sans-fonts
    google-roboto-fonts
    fira-code-fonts
    google-noto-emoji-fonts
    # Qt6 runtime (for Quickshell/QML)
    qt6-qtbase
    qt6-qtdeclarative
    qt6-qtwayland
    qt6-qtsvg
    qt6-qt5compat
    qt6-qtmultimedia
    # XWayland support
    xorg-x11-server-Xwayland
    # Login manager
    sddm
    # Misc desktop
    pinentry-gnome3
    plymouth-system-theme
    fprintd-pam
    bolt
    system-config-printer
    # Extras
    fastfetch
    distrobox
    htop
)

# Install from danklinux COPR (isolated)
dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:avengemedia:danklinux" \
    quickshell-git cliphist matugen

# Install the rest from Fedora repos
dnf5 -y install "${NIRI_PACKAGES[@]}"

# Build-time dependencies for niri-caelestia-shell
dnf5 -y install \
    cmake ninja-build gcc-c++ git \
    qt6-qtdeclarative-devel qt6-qtbase-devel \
    pipewire-devel aubio-devel

echo "::endgroup::"
