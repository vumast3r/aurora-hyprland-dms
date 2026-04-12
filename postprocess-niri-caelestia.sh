#!/usr/bin/env bash
# Post-process script for Niri + Caelestia Shell variant
# This runs inside the rootfs during rpm-ostree compose
set -xeuo pipefail

# === Run the base postprocess first (readonly sysroot migration) ===
# Source: postprocess.sh from fedora-common-ostree.yaml
cat > /usr/lib/systemd/system/fedora-silverblue-readonly-sysroot.service <<'EOF'
[Unit]
Description=Fedora Silverblue Read-Only Sysroot Migration
Documentation=https://fedoraproject.org/wiki/Changes/Silverblue_Kinoite_readonly_sysroot
ConditionPathExists=!/var/lib/.fedora_silverblue_readonly_sysroot
RequiresMountsFor=/sysroot /boot
ConditionPathIsReadWrite=/sysroot

[Service]
Type=oneshot
ExecStart=/usr/libexec/fedora-silverblue-readonly-sysroot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

chmod 644 /usr/lib/systemd/system/fedora-silverblue-readonly-sysroot.service

cat > /usr/libexec/fedora-silverblue-readonly-sysroot <<'SYSROOTEOF'
#!/bin/bash
set -euo pipefail

main() {
    local -r stamp_file="/var/lib/.fedora_silverblue_readonly_sysroot"
    if [[ -f "${stamp_file}" ]]; then
        exit 0
    fi
    local -r ostree_sysroot_readonly="$(ostree config --repo=/sysroot/ostree/repo get "sysroot.readonly" &> /dev/null || echo "false")"
    if [[ "${ostree_sysroot_readonly}" == "true" ]]; then
        touch "${stamp_file}"
        exit 0
    fi
    local -r boot_entries="$(ls -A /boot/loader/entries/ | wc -l)"
    if [[ "${boot_entries}" -eq 0 ]]; then
        echo "No BLS entry found: Maybe /boot is not mounted?" 1>&2
        echo "This is unexpected thus no migration will be performed" 1>&2
        touch "${stamp_file}"
        exit 0
    fi
    local rw_kargs_found=0
    local count=0
    for f in "/boot/loader/entries/"*; do
        count="$(grep -c "^options .* rw" "${f}" || true)"
        if [[ "${count}" -ge 1 ]]; then
            rw_kargs_found=$((rw_kargs_found + 1))
        fi
    done
    if [[ "${boot_entries}" -ne "${rw_kargs_found}" ]]; then
        ostree admin kargs edit-in-place --append-if-missing=rw || \
            echo "Failed to edit kargs in place with ostree" 1>&2
    fi
    rw_kargs_found=0
    count=0
    for f in "/boot/loader/entries/"*; do
        count="$(grep -c "^options .* rw" "${f}" || true)"
        if [[ "${count}" -ge 1 ]]; then
            rw_kargs_found=$((rw_kargs_found + 1))
        fi
    done
    unset count
    if [[ "${boot_entries}" -eq "${rw_kargs_found}" ]]; then
        echo "Setting up the sysroot.readonly option in the ostree repo config"
        ostree config --repo=/sysroot/ostree/repo set "sysroot.readonly" "true"
        touch "${stamp_file}"
        exit 0
    fi
    echo "Will retry next boot" 1>&2
    exit 0
}

main "${@}"
SYSROOTEOF

chmod 755 /usr/libexec/fedora-silverblue-readonly-sysroot
systemctl enable fedora-silverblue-readonly-sysroot.service

# === Build and install niri-caelestia-shell ===
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

# === Install Material Symbols font ===
mkdir -p /usr/share/fonts/material-symbols
curl -Lo /usr/share/fonts/material-symbols/MaterialSymbolsRounded.ttf \
  "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
fc-cache -f

# === Remove build-time packages to keep image small ===
rpm -e --nodeps cmake ninja-build gcc-c++ cpp gcc \
  qt6-qtdeclarative-devel qt6-qtbase-devel \
  pipewire-devel aubio-devel \
  kernel-headers glibc-devel libstdc++-devel \
  2>/dev/null || true

# === Install default configs in /etc/skel/ ===

# Niri config
mkdir -p /etc/skel/.config/niri
cat > /etc/skel/.config/niri/config.kdl << 'NIRIEOF'
// Niri configuration for Caelestia Shell
// See https://github.com/YaLTeR/niri/wiki/Configuration

input {
    keyboard {
        xkb {
        }
    }
    touchpad {
        tap
        natural-scroll
        dwt
    }
}

output "eDP-1" {
    scale 1.0
}

layout {
    gaps 8
    center-focused-column "never"
    default-column-width { proportion 0.5; }
    focus-ring {
        width 2
        active-color "#89b4fa"
        inactive-color "#585b70"
    }
    border {
        off
    }
}

spawn-at-startup "quickshell" "-c" "niri-caelestia-shell" "-n"
spawn-at-startup "xwayland-satellite"

prefer-no-csd

screenshot-path "~/Pictures/Screenshots/screenshot-%Y-%m-%d-%H-%M-%S.png"

hotkey-overlay {
    skip-at-startup
}

binds {
    // Window management
    Mod+Q { close-window; }
    Mod+Left  { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+Up    { focus-window-up; }
    Mod+Down  { focus-window-down; }
    Mod+Shift+Left  { move-column-left; }
    Mod+Shift+Right { move-column-right; }
    Mod+Shift+Up    { move-window-up; }
    Mod+Shift+Down  { move-window-down; }

    // Workspace navigation
    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+4 { focus-workspace 4; }
    Mod+5 { focus-workspace 5; }
    Mod+Shift+1 { move-column-to-workspace 1; }
    Mod+Shift+2 { move-column-to-workspace 2; }
    Mod+Shift+3 { move-column-to-workspace 3; }
    Mod+Shift+4 { move-column-to-workspace 4; }
    Mod+Shift+5 { move-column-to-workspace 5; }

    // Applications
    Mod+T { spawn "kitty"; }
    Mod+Return { spawn "kitty"; }
    Mod+E { spawn "thunar"; }

    // Caelestia Shell IPC
    Mod+Space { spawn "qs" "-c" "niri-caelestia-shell" "ipc" "call" "toggleLauncher"; }
    Mod+V { spawn "qs" "-c" "niri-caelestia-shell" "ipc" "call" "toggleClipboard"; }
    Mod+Tab { toggle-overview; }

    // Session
    Mod+L { spawn "qs" "-c" "niri-caelestia-shell" "ipc" "call" "toggleSessionMenu"; }

    // Layout
    Mod+F { maximize-column; }
    Mod+Shift+F { fullscreen-window; }
    Mod+Minus { set-column-width "-10%"; }
    Mod+Equal { set-column-width "+10%"; }
    Mod+R { switch-preset-column-width; }

    // Screenshots
    Print { screenshot; }
    Mod+Print { screenshot-screen; }
    Mod+Shift+Print { screenshot-window; }

    // Hardware keys
    XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
    XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
    XF86AudioMicMute { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
    XF86MonBrightnessUp { spawn "brightnessctl" "set" "+5%"; }
    XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }
    XF86AudioPlay { spawn "playerctl" "play-pause"; }
    XF86AudioNext { spawn "playerctl" "next"; }
    XF86AudioPrev { spawn "playerctl" "previous"; }

    // Power
    Mod+Shift+E { quit; }
}
NIRIEOF

# Caelestia shell config
mkdir -p /etc/skel/.config/caelestia
cat > /etc/skel/.config/caelestia/shell.json << 'SHELLEOF'
{
  "terminal": ["kitty"],
  "explorer": ["thunar"],
  "fonts": {
    "main": "JetBrains Mono",
    "titlebar": "Rubik",
    "iconFont": "Material Symbols Rounded"
  },
  "wallpaperDir": "~/Pictures/Wallpapers",
  "gpuType": "",
  "time": {
    "use12h": true
  },
  "weather": {
    "location": "Denver"
  },
  "theme": {
    "name": "catppuccin-mocha"
  }
}
SHELLEOF

# Create default directories
mkdir -p /etc/skel/Pictures/Wallpapers
mkdir -p /etc/skel/Pictures/Screenshots

# === Install desktop session entry ===
mkdir -p /usr/share/wayland-sessions
cat > /usr/share/wayland-sessions/niri-caelestia.desktop << 'DESKTOPEOF'
[Desktop Entry]
Name=Niri (Caelestia)
Comment=Scrollable tiling Wayland compositor with Caelestia Shell
Exec=niri-session
Type=Application
DesktopNames=niri
DESKTOPEOF
