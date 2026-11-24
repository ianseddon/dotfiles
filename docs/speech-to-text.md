# Speech-to-text proposal

## Recommendation

Use Voxtype exactly where Omarchy does, but port only its durable pieces:

- `voxtype-bin` for local transcription
- `wtype` for direct Wayland typing
- the existing `wl-clipboard` package as fallback
- Voxtype's generated systemd user service
- Omarchy's `Super+Ctrl+X` toggle binding in Hyprland
- a small Stow-managed `voxtype/.config/voxtype/config.toml`
- a systemd override pinning Vulkan to NVIDIA

Start with Whisper `base.en` on the Vulkan backend. Pin Voxtype to NVIDIA because its hardware inventory detects both the RTX 4080 SUPER and Intel iGPU. This preserves Omarchy's small model and moves inference onto the otherwise underused GPU.

## Why this fits

The existing system already has `pipewire`, `pipewire-alsa`, `pipewire-pulse`, `wireplumber`, `wl-clipboard`, `playerctl`, `libnotify`, and a working UWSM/Hyprland session. `voxtype-bin` and `wtype` are the only missing runtime pieces.

Omarchy uses `Super+Ctrl+X` to toggle dictation and `F9` for push-to-talk. This setup keeps only the toggle binding because `F9` requires the Tofu Jr function layer.

The existing US keyboard layout is ideal for `wtype`; no `dotool`, `ydotool`, input-group membership, or compositor submap is needed. The current UWSM startup and Hyprland environment import are sufficient for a systemd user daemon to reach Wayland and PipeWire.

## Managed files

- [`voxtype/.config/voxtype/config.toml`](../voxtype/.config/voxtype/config.toml) owns transcription, audio, and output settings.
- [`voxtype/.config/systemd/user/voxtype.service.d/gpu.conf`](../voxtype/.config/systemd/user/voxtype.service.d/gpu.conf) pins Vulkan to NVIDIA.
- [`hyprland/.config/hypr/bindings.lua`](../hyprland/.config/hypr/bindings.lua) owns the `Super+Ctrl+X` toggle binding.

This keeps config in the repo while leaving models and generated service state in their normal XDG locations.

## Setup sequence

```bash
paru -S voxtype-bin wtype
stow voxtype
voxtype setup --download --no-post-install
sudo voxtype setup gpu --enable
voxtype setup systemd
hyprctl reload
voxtype setup check
voxtype info variants
systemctl --user show voxtype -p Environment
journalctl --user -u voxtype -b | rg 'ggml_vulkan.*NVIDIA'
```

Test with a focused text field by pressing `Super+Ctrl+X`, speaking, then pressing it again. Diagnose failures with:

```bash
systemctl --user status voxtype
journalctl --user -u voxtype -f
```

## Bar status

The Quickshell bar shows dictation only while it happens: a red mic that pulses while recording, and a spinner while transcribing. It follows `voxtype status --follow --format json` (see [desktop-shell/SPEC-bar.md](desktop-shell/SPEC-bar.md)). Upstream supports this command for status bars, so no wrapper is needed.

## Deliberately skipped

- GPU index configuration: the vendor-level systemd override reliably selects NVIDIA without coupling the config to a device index.
- Additional dictation shortcuts: one toggle binding is enough.
- Built-in evdev hotkeys and `input` group membership: the Hyprland toggle binding already solves activation.
- Custom systemd unit: `voxtype setup systemd` owns the service lifecycle upstream.
- Post-processing through an LLM: adds latency and failure modes before a need is demonstrated.
- Omarchy install/remove wrappers, hooks, menus, and shell plugin framework: those solve distro concerns absent from these Stow dotfiles.

## Sources

- Omarchy installer: [`omarchy/bin/omarchy-voxtype-install`](../omarchy/bin/omarchy-voxtype-install)
- Omarchy defaults: [`omarchy/default/voxtype/config.toml`](../omarchy/default/voxtype/config.toml)
- Omarchy bindings: [`omarchy/default/hypr/bindings/voxtype.lua`](../omarchy/default/hypr/bindings/voxtype.lua)
- Omarchy status bridge: [`omarchy/bin/omarchy-voxtype-status`](../omarchy/bin/omarchy-voxtype-status)
- [Voxtype 0.7.5 README](https://github.com/peteonrails/voxtype/blob/v0.7.5/README.md)
- [Voxtype 0.7.5 installation guide](https://github.com/peteonrails/voxtype/blob/v0.7.5/docs/INSTALL.md)
- [Voxtype 0.7.5 default configuration](https://github.com/peteonrails/voxtype/blob/v0.7.5/config/default.toml)
- [Voxtype 0.7.5 troubleshooting guide](https://github.com/peteonrails/voxtype/blob/v0.7.5/docs/TROUBLESHOOTING.md)
- [AUR `voxtype-bin` metadata](https://aur.archlinux.org/packages/voxtype-bin)
