# Hyprland screen sharing

## Supported architecture

Wayland screen sharing uses the XDG ScreenCast portal to negotiate a user-approved source and expose it as a PipeWire stream. The upstream ScreenCast lifecycle is `CreateSession` → `SelectSources` → `Start` → `OpenPipeWireRemote`; `Start` returns the selected PipeWire streams and `OpenPipeWireRemote` returns the remote file descriptor. [XDG Desktop Portal ScreenCast API](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.ScreenCast.html)

Hyprland requires PipeWire, WirePlumber, and `xdg-desktop-portal-hyprland` (XDPH), with monitor bit depth matching the physical output. Native Wayland applications can share Wayland windows and outputs; XWayland applications are limited to XWayland content. [Hyprland screen-sharing guide](https://wiki.hypr.land/Useful-Utilities/Screen-Sharing/)

This workstation uses UWSM. UWSM owns the systemd graphical-session lifecycle and exports the compositor environment before starting `graphical-session.target`. This is the supported alternative to manually importing `WAYLAND_DISPLAY` and desktop variables from a Hyprland `exec-once`. [Hyprland systemd startup guide](https://wiki.hypr.land/Useful-Utilities/Systemd-start/)

## Current system

Verified 2026-08-19:

- `pipewire` 1.6.8, `wireplumber` 0.5.15, `xdg-desktop-portal` 1.22.1, `xdg-desktop-portal-hyprland` 1.4.1, and `xdg-desktop-portal-gtk` 1.15.3 are installed.
- `xdg-desktop-portal-wlr` is not installed. The GTK backend remains for interfaces XDPH does not implement, such as file selection.
- PipeWire, WirePlumber, the portal frontend, XDPH, and `graphical-session.target` are active.
- Arch's package-supplied `/usr/share/xdg-desktop-portal/hyprland-portals.conf` contains `default=hyprland;gtk`. No user or `/etc` override is needed. Portal selection is desktop-specific and keyed by `XDG_CURRENT_DESKTOP`; vendor defaults belong under `/usr/share/xdg-desktop-portal`. [portals.conf manual](https://flatpak.github.io/xdg-desktop-portal/docs/portals.conf.html)
- UWSM exports `WAYLAND_DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE`, `XDG_CURRENT_DESKTOP=Hyprland`, `XDG_SESSION_DESKTOP=Hyprland`, and `XDG_SESSION_TYPE=wayland` before XDPH starts. The live XDPH process has the same values.
- Both active outputs use `XRGB8888`, matching Hyprland's default 8-bit monitor configuration.
- Firefox runs natively on Wayland (`xwayland=false`) and is connected to PipeWire.

## Removed legacy workarounds

The required [Bruno Anç screen-sharing gist](https://gist.github.com/brunoanc/2dea6ddf6974ba4e5d26c3139ffb7580) remains useful as historical troubleshooting context, but several instructions predate the current Hyprland, XDPH, browser, and UWSM stack.

Removed from the tracked Hyprland configuration:

- `exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP` and its gist citation. UWSM already exports the complete environment and waits for `WAYLAND_DISPLAY` before starting graphical-session services.
- Manual `XDG_CURRENT_DESKTOP` and `XDG_SESSION_DESKTOP` environment declarations labelled as screen-sharing support. UWSM derives both from the selected `hyprland.desktop` session.

Do not reintroduce these older gist remedies:

- XDPH's `-git` AUR package: XDPH is available as the current Arch package.
- `xdg-desktop-portal-wlr`: XDPH is the Hyprland backend and supports monitor, window, and virtual sources.
- The patched `hyprland-nvidia-git`/wlroots read-format workaround: it targets the gist's old stack and is unnecessary on the installed Hyprland 0.56.2/XDPH 1.4.1 path, which returned a valid NVIDIA-backed stream.
- `wlrobs`: do not add it unless OBS itself demonstrates a gap; the standard ScreenCast/PipeWire path is working.
- Chromium's old experimental “WebRTC PipeWire support” flag: treat it as version-sensitive advice, not a current system requirement. Verify an application's current Wayland/WebRTC behavior before adding flags.

`grim` and `slurp` remain installed for screenshots and region selection, but they are not part of the ScreenCast portal path.

## End-to-end verification

A live D-Bus ScreenCast transaction exercised the real portal API after the cleanup:

1. `CreateSession` succeeded.
2. `SelectSources` requested one monitor with an embedded cursor.
3. XDPH displayed its source picker and the user selected a monitor.
4. `Start` returned a monitor stream (`source_type=1`) sized 3840×2160.
5. `OpenPipeWireRemote` returned a valid file descriptor.
6. The session was closed cleanly.

The live portal advertises ScreenCast interface version 6 and source mask 7: monitor, window, and virtual sources. PipeWire, WirePlumber, the portal frontend, and XDPH remained active, and no portal/PipeWire error was logged during or after the transaction.

## Troubleshooting checklist

```bash
# Required processes
systemctl --user status pipewire wireplumber \
  xdg-desktop-portal xdg-desktop-portal-hyprland

# UWSM/systemd environment inherited by XDPH
systemctl --user show-environment | \
  grep -E '^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_CURRENT_DESKTOP|XDG_SESSION_DESKTOP|XDG_SESSION_TYPE)='

# Portal and PipeWire failures from this boot
journalctl --user -b \
  -u xdg-desktop-portal.service \
  -u xdg-desktop-portal-hyprland.service \
  -u pipewire.service -u wireplumber.service

# PipeWire clients and active streams
wpctl status

# Confirm an application is native Wayland; xwayland must be false
hyprctl clients -j | jq '.[] | {class, xwayland, title}'

# Active output pixel format
hyprctl monitors all -j | jq '.[] | {name, currentFormat}'
```

When an individual application fails while the portal smoke path works, check that application first: native Wayland mode, current browser/Electron version, and its own WebRTC or capture permissions. Do not restart every portal or add global environment hacks without identifying a missing environment value or backend-selection error.
