#!/usr/bin/bash
set -eoux pipefail

echo "::group:: Install niri-caelestia packages"

# Remove KDE-specific packages we don't need
# (kinoite base provides SDDM, Qt6, pipewire, NetworkManager, etc. which we keep)
KDE_REMOVE=(
    plasma-desktop
    plasma-workspace
    plasma-workspace-wayland
    plasma-workspace-x11
    plasma-workspace-wallpapers
    plasma-workspace-geolocation
    plasma-breeze
    plasma-discover
    plasma-discover-notifier
    plasma-disks
    plasma-drkonqi
    plasma-nm
    plasma-nm-openconnect
    plasma-nm-openvpn
    plasma-nm-vpnc
    plasma-pa
    plasma-systemmonitor
    plasma-thunderbolt
    plasma-vault
    plasma-welcome
    kdeplasma-addons
    kscreen
    kscreenlocker
    kwin
    kwin-wayland
    kwayland-integration
    dolphin
    kate
    konsole5
    kwrite
    ark
    spectacle
    kfind
    kinfocenter
    kmenuedit
    khotkeys
    kmag
    kmousetool
    colord-kde
    kde-connect
    kde-gtk-config
    kde-partitionmanager
    kde-print-manager
    kde-settings-pulseaudio
    kdegraphics-thumbnailers
    kdialog
    kdnssd
    kamera
    kwalletmanager5
    krfb
    pam-kwallet
    bluedevil
    breeze-icon-theme
    flatpak-kcm
    polkit-kde
    filelight
    ffmpegthumbs
    kcharselect
    khelpcenter
    phonon-qt5-backend-gstreamer
    qt-at-spi
    sddm-breeze
    plasma-lookandfeel-fedora
)

# Remove what's actually installed (skip packages not found)
readarray -t INSTALLED_KDE < <(rpm -qa --queryformat='%{NAME}\n' "${KDE_REMOVE[@]}" 2>/dev/null || true)
if [[ "${#INSTALLED_KDE[@]}" -gt 0 ]]; then
    dnf5 -y remove "${INSTALLED_KDE[@]}" || true
fi

# Enable danklinux COPR (quickshell-git, cliphist, matugen)
dnf5 -y copr enable avengemedia/danklinux
dnf5 -y copr disable avengemedia/danklinux

# Install COPR packages (isolated enablement)
dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:avengemedia:danklinux" \
    quickshell-git cliphist matugen

# Packages to add on top of kinoite base
NIRI_PACKAGES=(
    # Compositor
    niri
    xwayland-satellite
    # Desktop portals
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    gnome-keyring
    gnome-keyring-pam
    # Audio extras
    cava
    aubio
    pavucontrol
    playerctl
    # Display & brightness
    brightnessctl
    ddcutil
    # Clipboard & screenshots
    wl-clipboard
    grim
    swappy
    # Terminal & file manager
    kitty
    Thunar
    thunar-archive-plugin
    # Shell scripting
    fish
    jq
    # OCR & utilities
    tesseract
    tesseract-langpack-eng
    libqalculate
    qalculate-gtk
    # Fonts
    jetbrains-mono-fonts-all
    google-noto-sans-fonts
    google-roboto-fonts
    fira-code-fonts
    # Qt6 extras for Quickshell
    qt6-qtsvg
    qt6-qt5compat
    qt6-qtmultimedia
    # Misc desktop
    pinentry-gnome3
    bolt
    # Extras
    fastfetch
    distrobox
    htop
)

dnf5 -y install "${NIRI_PACKAGES[@]}"

# Build-time dependencies for niri-caelestia-shell
dnf5 -y install \
    cmake ninja-build gcc-c++ git \
    qt6-qtdeclarative-devel qt6-qtbase-devel qt6-qtmultimedia-devel \
    pipewire-devel aubio-devel

echo "::endgroup::"
