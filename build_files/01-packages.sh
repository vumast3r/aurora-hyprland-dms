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
    sddm
    sddm-breeze
    sddm-kcm
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

# Enable additional COPRs (isolated enablement: enable then disable)
for copr in \
    celestelove/libcava \
    celestelove/app2unit \
    celestelove/caelestia \
    mineiro/satty \
    solopasha/hyprland \
    brycensranch/gpu-screen-recorder-git
do
    dnf5 -y copr enable "$copr"
    dnf5 -y copr disable "$copr"
done

# Runtime libcava from celestelove/libcava
dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:celestelove:libcava" \
    libcava

# Packages to add on top of kinoite base
NIRI_PACKAGES=(
    # Login manager
    greetd
    tuigreet
    # Compositor
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
    # Display, brightness, sensors (tuned-ppd comes from kinoite base)
    brightnessctl
    ddcutil
    lm_sensors
    # Clipboard & screenshots
    wl-clipboard
    grim
    slurp
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
    # Fonts
    jetbrains-mono-fonts-all
    google-noto-sans-fonts
    google-roboto-fonts
    # Qt6 extras for Quickshell
    qt6-qtsvg
    qt6-qt5compat
    qt6-qtmultimedia
    # Theming
    papirus-icon-theme
    # Misc desktop
    pinentry-qt
    # Extras
    fastfetch
    distrobox
    htop
)

dnf5 -y install "${NIRI_PACKAGES[@]}"

# app2unit (caelestia app launcher helper)
dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:celestelove:app2unit" \
    app2unit

# Caelestia fonts (rubik, cascadia-code-nerd, material-symbols)
dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:celestelove:caelestia" \
    rubik-fonts cascadia-code-nerd-fonts material-symbols-fonts

# Screenshot annotator
dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:mineiro:satty" \
    satty

# GTK theme tweaker
dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:solopasha:hyprland" \
    nwg-look

# Screen recorder with instant-replay UI
dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:brycensranch:gpu-screen-recorder-git" \
    gpu-screen-recorder gpu-screen-recorder-ui

# Install niri without weak deps (skips waybar and swaylock recommendations;
# caelestia-shell provides the bar and lock screen)
dnf5 -y install --setopt=install_weak_deps=False niri

# Build-time dependencies for niri-caelestia-shell
dnf5 -y install \
    cmake ninja-build gcc-c++ git \
    qt6-qtdeclarative-devel qt6-qtbase-devel qt6-qtmultimedia-devel \
    kf6-networkmanager-qt-devel \
    pipewire-devel aubio-devel \
    libqalculate-devel

dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:celestelove:libcava" \
    libcava-devel

echo "::endgroup::"
