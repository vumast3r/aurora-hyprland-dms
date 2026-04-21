#!/usr/bin/bash
set -eoux pipefail

echo "::group:: Install hyprland-dms packages"

# Remove KDE-specific packages we don't need.
# aurora-nvidia-open base gives us: nvidia-open drivers, ublue tooling,
# codecs, Flatpak setup, Qt6, pipewire, NetworkManager — all kept.
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

# Enable COPRs (isolated enablement: enable then disable)
for copr in \
    avengemedia/danklinux \
    avengemedia/dms \
    solopasha/hyprland \
    mineiro/satty \
    brycensranch/gpu-screen-recorder-git
do
    dnf5 -y copr enable "$copr"
    dnf5 -y copr disable "$copr"
done

# Packages to add on top of aurora-nvidia-open base
HYPR_PACKAGES=(
    # Login manager
    greetd
    tuigreet
    # Desktop portals
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    gnome-keyring
    gnome-keyring-pam
    # Audio extras
    cava
    pavucontrol
    playerctl
    # Display, brightness, sensors (tuned-ppd comes from the Aurora base)
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
    # Services DMS integrates with
    accountsservice
    # Misc desktop
    pinentry-qt
    # Extras
    fastfetch
    distrobox
    htop
)

dnf5 -y install "${HYPR_PACKAGES[@]}"

# Hyprland stack from solopasha/hyprland.
# hyprland-plugins provides hyprexpo (workspace overview). hyprscroller
# (community plugin for niri-style scrolling columns) is not packaged in
# this COPR; 02-plugins.sh builds it from source against hyprland-devel.
dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:solopasha:hyprland" \
    hyprland hyprlock hypridle hyprpaper xdg-desktop-portal-hyprland nwg-look \
    hyprland-plugins

# DankMaterialShell runtime (shell, cli, system monitor, search, fonts, quickshell)
dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:avengemedia:danklinux" \
    --enablerepo="copr:copr.fedorainfracloud.org:avengemedia:dms" \
    dms quickshell-git cliphist matugen dgop danksearch material-symbols-fonts

# Screenshot annotator
dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:mineiro:satty" \
    satty

# Screen recorder with instant-replay UI
dnf5 -y install \
    --enablerepo="copr:copr.fedorainfracloud.org:brycensranch:gpu-screen-recorder-git" \
    gpu-screen-recorder gpu-screen-recorder-ui

echo "::endgroup::"
