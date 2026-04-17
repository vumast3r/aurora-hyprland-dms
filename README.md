# aurora-hyprland-dms

A Fedora bootc image derived from `kinoite:43`, swapping the KDE Plasma session
for [Hyprland](https://hypr.land) + [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
(via [Quickshell](https://quickshell.org)) and using
[greetd + tuigreet](https://git.sr.ht/~kennylevinsen/greetd) as the login
manager. Everything else from the kinoite base — pipewire, NetworkManager,
Flatpak, the bootc/ostree machinery — is preserved.

## Image

Built and published by GitHub Actions on every push to `main`, every Monday,
and on manual dispatch.

```
ghcr.io/vumast3r/aurora-hyprland-dms:latest
ghcr.io/vumast3r/aurora-hyprland-dms:43
ghcr.io/vumast3r/aurora-hyprland-dms:43-<YYYYMMDD>
ghcr.io/vumast3r/aurora-hyprland-dms:43-<short-sha>
```

The package is public — no `podman login` needed to pull.

## Rebasing an existing host

From any kinoite-based Fedora 43 system:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/vumast3r/aurora-hyprland-dms:latest
sudo systemctl reboot
```

To roll back:

```bash
sudo rpm-ostree rollback
sudo systemctl reboot
```

## What's in the image

- **Compositor**: hyprland, hyprlock, hypridle, hyprpaper, xdg-desktop-portal-hyprland (solopasha/hyprland COPR)
- **Shell**: DankMaterialShell + Quickshell, dgop, danksearch, matugen, cliphist, material-symbols-fonts (avengemedia/dms + danklinux COPRs)
- **Login**: greetd + tuigreet (replaces SDDM)
- **Terminal / files**: kitty, Thunar, fish
- **Audio**: pipewire, wireplumber, pavucontrol, playerctl, cava
- **Capture**: grim, slurp, satty, gpu-screen-recorder + ui, wl-clipboard
- **Hardware**: brightnessctl, ddcutil, lm_sensors, tuned-ppd
- **Misc**: gnome-keyring, pinentry-qt, accountsservice, fastfetch, distrobox, htop

KDE Plasma packages from the base are removed during build (see
`build_files/01-packages.sh`).

## Repository layout

```
Containerfile              # Build entrypoint
build_files/
  01-packages.sh           # Strip KDE, enable COPRs, install Hyprland + DMS stack
  03-configs.sh            # Copy system_files, enable services, set graphical target
  04-cleanup.sh            # Disable COPRs, drop build artifacts, reset /var
  05-tests.sh              # Sanity checks (run before cleanup)
system_files/              # Files rsync'd into the image as-is
  etc/skel/.config/hypr/hyprland.conf
  etc/greetd/config.toml
.github/workflows/build.yml  # GHA: build + push to ghcr.io
```

## Building locally

```bash
podman build -t aurora-hyprland-dms:43 --build-arg FEDORA_MAJOR_VERSION=43 .
```

You'll need ~15 GB of free space and a recent podman/buildah.

## License

Mozilla Public License 2.0 — see [LICENSE](./LICENSE).

## Credits

- [ublue-os/aurora](https://github.com/ublue-os/aurora) — base image lineage and conventions
- [AvengeMedia/DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) — the shell
- [hyprwm/Hyprland](https://github.com/hyprwm/Hyprland) — the compositor
- [solopasha/hyprland](https://copr.fedorainfracloud.org/coprs/solopasha/hyprland/) — Fedora packaging for the Hyprland stack
