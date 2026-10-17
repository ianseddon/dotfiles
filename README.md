# Dotfiles

Modern dotfiles configuration using GNU Stow for symlink management.

## Structure

This repository uses the [GNU Stow](https://www.gnu.org/software/stow/) package manager to organize and deploy dotfiles. Each directory represents a "package" that can be independently managed.

```
dotfiles/
├── nix/            # Pinned headless development tools and Nix/Fish integration
├── fish/           # Fish shell configuration
├── zellij/         # Zellij terminal multiplexer
├── ghostty/        # Ghostty terminal emulator
├── nvim/           # Neovim configuration
├── hyprland/       # Hyprland window manager
└── README.md
```

## Headless Arch Development Host (Nix)

For the M75q's complete disk-to-development setup, use [the targeted Arch installation guide](M75Q-ARCH-INSTALL.md). It includes encrypted root, Secure Boot, TPM auto-unlock, recovery, and the transfer path while this configuration is not yet published.

The `nix/` flake provides the same pinned tools as either a persistent user profile or a temporary development shell on `x86_64-linux`. It is not an Arch installer or a NixOS configuration.

It is split by machine, the way the reference setups in `docs/multiplexer-agent-review-dotfiles.md` split theirs: `nix/dev.nix` lists the development tools every Nix-managed machine gets, and `nix/hosts/<name>.nix` adds what exists only because of that machine (M75q: Stow and the rootless Docker engine). Each host is one profile, `packages.x86_64-linux.<host>`; the development shell is `dev.nix` alone. Plain package lists, not Home Manager modules, for now.

- **Arch owns:** the kernel, hardware, networking, Nix daemon, OpenSSH, and Tailscale.
- **Nix owns:** Git, GitHub CLI, worktrunk (`wt`), Stow, ripgrep, fd, jq, fzf, zoxide, AWS CLI v2 with the SSM Session Manager plugin, pgcli, Fish, herdr, Zellij, Neovim, tuicr, Node 24 with npm/Corepack, Bun, Python 3.12, uv, GCC, Make, pkg-config, rootless Docker Engine with Compose/Buildx, and omp.
- **Stow owns:** dotfile symlinks. No Home Manager or changes to the login shell.

On the headless host, keep Arch's `/bin/bash` as the login shell. Launch Nix-provided Fish after login; do not follow the desktop installer's `chsh` steps.

`nix/flake.lock` pins the complete Nixpkgs input. herdr, omp, and worktrunk come from their upstream flakes at published release tags rather than the default branch; the tag in `nix/flake.nix` is the version. Project dependencies remain in each repository's own lockfiles. Corepack supplies `pnpm`/`yarn` shims and respects each project's `packageManager`; there is no globally pinned pnpm version.

### Bootstrap a New Host

Start with an installed, networked Arch system and a normal user with sudo access. Run the bootstrap from Bash:

```bash
sudo pacman -Syu --needed nix git openssh tailscale
sudo systemctl enable --now nix-daemon.service tailscaled.service
source /etc/profile.d/nix-daemon.sh

# Authenticate the new machine; access still depends on tailnet SSH policy.
sudo tailscale up --ssh

# Once a published branch contains nix/; otherwise use the guide's file transfer.
git clone https://github.com/ianseddon/dotfiles.git ~/dotfiles
cd ~/dotfiles

test -f nix/flake.lock
# Explicit flags are needed before the user-level nix.conf is installed.
nix --extra-experimental-features 'nix-command flakes' profile add path:./nix#m75q
export PATH="$HOME/.nix-profile/bin:$PATH"
stow --target="$HOME" nix
# worktrunk's worktree location; a real directory first, so only config.toml is
# linked and per-machine approvals stay out of the repo.
mkdir -p ~/.config/worktrunk && stow --target="$HOME" worktrunk
# herdr: the desktop's config and local plugins. --no-folding links files only,
# so each plugin's config dir stays real and machine state (Collie's .env) stays
# out of the repo.
mkdir -p ~/.config/herdr && stow --no-folding --target="$HOME" herdr
# Rootless Docker runs as a user service; lingering starts it without a login.
sudo loginctl enable-linger "$USER"
systemctl --user daemon-reload
systemctl --user enable --now docker.service
# The herdr server, so plugins (Collie) have a socket at boot before the desktop attaches.
systemctl --user enable --now herdr.service

fish
```

Use a checkout containing this configuration. Keep it at the same path: both Stow symlinks and profile upgrades refer to it. Stow refuses conflicting existing files; reconcile those explicitly rather than forcing an overwrite.

Only the `nix`, `worktrunk`, and `herdr` Stow packages are installed here. `nix` enables flakes, adds the user profile to Fish's PATH without overriding an active Nix development shell, and installs the rootless Docker user unit plus Fish's `DOCKER_HOST`; `worktrunk` sets where worktrees go (`~/dev/wt/<owner>/<repo>/<branch>`); `herdr` is the desktop's herdr config, so the host's server runs the same plugins and keys. They do not install the desktop Fish configuration, source `secrets.fish`, or start desktop services. Do not run the desktop `install.sh` or `stow */` on the headless host.

Tailscale SSH does not require enabling `sshd` or exposing port 22 publicly. Complete GitHub authentication with `gh auth login`, and configure the desired provider through omp's `/login` separately. No credentials, SSH keys, or agent state belong in this flake. In particular, do not copy Bridge Commander state or start a second writer as part of this bootstrap.

worktrunk's shell integration and its omp hook are generated by `wt` itself rather than stowed, because the `nix` package doesn't install the desktop Fish configuration: run `wt config shell install` (bash and fish wrappers, so `wt switch` can change directory) and `wt config plugins omp install` (agent status markers in `wt list`) once after the profile is installed.

#### herdr plugins and Collie

The desktop opens this host as a saved herdr machine (`herdr machine add m75q --label M75q`). The desktop client draws the UI with its own theme and keys, but plugin actions and hooks run on the server that owns the workspace, and herdr copies no plugins or config to SSH hosts. So the host installs the desktop's plugins at the same commits:

```bash
herdr plugin install -y --ref b187fb76a9b12810d4fde937da0e4215689006d0 ianseddon/herdr-git-status
herdr plugin install -y --ref e393ef593e44d2497f43d20aa7b0e4a26ea3d445 tomasvarga/herdr-pickr
herdr plugin install -y --ref 742db891e7d1f9a550b16c01dc8a6763f2b1493a paulbkim-dev/vim-herdr-navigation
herdr plugin install -y --ref f9df9ba700b8a4f4d97ddfe3ea3eb345e80b880b devashish2203/herdr-worktrunk
for p in ~/dotfiles/herdr/.local/share/herdr-plugins/*/; do herdr plugin link "$p"; done
# Once: git-status's startup hook only restarts a poller that was running before.
herdr plugin action invoke start --plugin git-status
```

[Collie](https://github.com/AltanS/collie) sends phone notifications when an agent waits on you, so it runs where the agents do. It controls terminals, so set both trust gates before the first start: without them any tailnet identity that reaches it gets a shell, and Host-header checks are off. The VAPID keys are this host's own; a phone subscribes to each Collie origin separately anyway.

```bash
herdr plugin install -y --ref 0c647372d89d50ec62dfe8b569e9109a830660e5 AltanS/collie
cfg=$(herdr plugin config-dir herdr.collie); mkdir -p "$cfg"
printf '%s\n' "COLLIE_TRUSTED_USER=ianseddon55@gmail.com" \
  "COLLIE_PUBLIC_HOSTS=m75q.hawk-monster.ts.net" > "$cfg/.env"; chmod 600 "$cfg/.env"
c=$(herdr plugin list --json | jq -r '.result.plugins[] | select(.plugin_id=="herdr.collie") | .plugin_root')
bash "$c/scripts/collie-ctl.sh" push-keys mailto:ianseddon55@gmail.com
herdr plugin action invoke start --plugin herdr.collie   # systemd --user unit + tailscale serve
```

Then open `https://m75q.hawk-monster.ts.net` on the phone, install it, and enable notifications in Settings; `bash "$c/scripts/collie-ctl.sh" push-test` sends one. Tailscale's operator must be this user (`sudo tailscale set --operator=$USER`) for `tailscale serve` to run unprivileged. Renaming the host changes this origin: every phone has to subscribe again.

The flake installs the AWS CLI, not its configuration: this repository is public, and `~/.aws/config` names account IDs and SSO start URLs. Copy `~/.aws/config` from the workstation (mode 0600). The host has no browser, so sign in with a flow that prints a URL and code for another device:

```bash
aws sso login --use-device-code --sso-session <name>   # IAM Identity Center profiles
aws login --remote                                     # IAM/root sign-in without SSO
```

### Use the Environment

The persistent profile makes the tools available without entering a shell. From a project checkout:

```bash
corepack pnpm install --frozen-lockfile
# Python projects continue to use their own pyproject.toml and uv.lock.
uv sync --locked
```

Run the command appropriate to that project, not both indiscriminately. Do not run `corepack enable`: the Nix package already provides the shims, and the Nix store is read-only.

To try the tools without adding them to a profile or installing dotfiles, run this from the dotfiles checkout after installing Nix:

```bash
nix --extra-experimental-features 'nix-command flakes' develop path:./nix
# Or launch Fish with the same toolchain:
nix --extra-experimental-features 'nix-command flakes' develop path:./nix --command fish
```

Use `path:./nix` deliberately: it keeps the flake source limited to this directory instead of copying the entire dotfiles repository into the world-readable Nix store. Keep secrets out of `nix/` too.

### Docker

Docker runs rootless: `docker.service` is a `systemd --user` unit running the profile's `dockerd-rootless`, and user lingering starts it at boot. It needs no pacman packages, sudo, or `docker` group, which would be root-equivalent. Arch only supplies `newuidmap`/`newgidmap` and the `ian:100000:65536` range in `/etc/subuid` and `/etc/subgid`. A rootful Arch `docker` package was rejected: Arch would own the engine instead of this flake, and every membership of the `docker` group grants root.

`nix/.config/fish/conf.d/docker.fish` points the CLI at `/run/user/$UID/docker.sock`, because Tailscale SSH sessions do not set `XDG_RUNTIME_DIR`. `docker compose` and `docker buildx` are wired into the Nix CLI wrapper; `docker-compose` remains for older scripts.

```bash
systemctl --user status docker.service
docker info --format '{{json .SecurityOptions}}'   # includes "name=rootless"
docker compose up -d
```

Rootless limits: published ports must be 1024 or higher, `--network host` means RootlessKit's namespace rather than the machine's, and files that non-root container users write to bind mounts are owned by subordinate UIDs on the host. Reclaim those with `docker run --rm -v "$PWD:/w" alpine chown -R 0:0 /w` (container root maps to `ian`). Images and volumes live under `~/.local/share/docker`, not `/var/lib/docker`.

### Update and Roll Back

From the same dotfiles checkout, after the bootstrap:

```bash
# After editing flake.nix or pulling an existing lockfile:
nix flake check path:./nix
nix build --no-link path:./nix#m75q
nix profile upgrade m75q

# Once, on a host whose profile entry is still the old `dev`: the output was
# renamed, so `upgrade dev` now fails instead of silently dropping Docker.
nix profile remove dev && nix profile add path:./nix#m75q

# Once, when herdr's config moved from the nix package to the herdr package:
# restowing nix drops the dangling ~/.config/herdr/config.toml link.
stow -R --target="$HOME" nix && stow --no-folding --target="$HOME" herdr

# A new herdr tag: the running server keeps the old binary, and its panes, until
# it stops. Stopping ends every pane; the desktop's next connection starts it again.
herdr server stop

# Only when deliberately advancing package versions. This moves Nixpkgs;
# herdr, omp, and worktrunk move only when their release tags in nix/flake.nix change.
nix flake update --flake path:./nix
# Review and commit nix/flake.lock, then repeat the checks and upgrade above.

# Restore the previous user-profile generation if needed:
nix profile history
nix profile rollback
```

Rollback changes the user profile, not Stow-managed files, project dependencies, or data. Keep the previous lockfile in Git for reproducibility; do not garbage-collect old generations before deciding whether to roll back.

This baseline does not provision databases, browsers, editor plugins, automation services, or secrets. Add project-specific dependencies in the relevant project's environment rather than expanding the shared tool list speculatively; run project services through Docker Compose.

## New Setup (Fish + Zellij + Ghostty)

This is a separate, pacman-managed desktop setup, not a continuation of the headless Nix instructions. Do not run it on the M75q development host.

### Prerequisites

Install the required tools:

```bash
# Arch Linux
sudo pacman -S fish zellij ghostty stow

# Or using your preferred package manager
```

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url> ~/.dotfiles
cd ~/.dotfiles
```

2. Install the configurations using stow:
```bash
# Install all configurations
stow */

# Or install specific configurations
stow fish
stow zellij
stow ghostty
```

3. Change your default shell to fish:
```bash
chsh -s $(which fish)
```

### Fish Shell Features

- **Modern prompt** with git integration
- **Vi key bindings** enabled by default
- **Zellij integration** - auto-starts zellij sessions
- **Modern tool aliases** (eza, bat, fd, rg if available)
- **Useful functions**:
  - `mkcd <dir>` - Create directory and cd into it
  - `extract <archive>` - Extract various archive formats
  - `zj [session] [layout]` - Zellij session manager

### Zellij Configuration

- **Alt-based keybindings** for easy navigation
- **Custom layouts** for different workflows
- **Catppuccin theme** for consistent appearance
- **Fish shell integration**

Key bindings:
- `Alt + h/j/k/l` - Navigate panes
- `Alt + t` - New tab
- `Alt + w` - Close tab
- `Alt + 1-9` - Switch to tab
- `Alt + |` - Split right
- `Alt + -` - Split down
- `Alt + r` - Resize mode
- `Alt + s` - Scroll mode

### Ghostty Configuration

- **Catppuccin theme** matching zellij
- **Fish shell integration**
- **Optimized for zellij** workflow
- **Smart clipboard handling**

## Migration from Zsh + Tmux + Kitty

### Removing Old Configuration

```bash
# Backup existing configurations
mkdir -p ~/.config/backup
mv ~/.config/zsh ~/.config/backup/ 2>/dev/null || true
mv ~/.tmux.conf ~/.config/backup/ 2>/dev/null || true
mv ~/.config/kitty ~/.config/backup/ 2>/dev/null || true

# Remove old shell configuration
rm ~/.zshrc ~/.zshenv 2>/dev/null || true
```

### Key Differences

| Old Stack | New Stack | Notes |
|-----------|-----------|-------|
| Zsh | Fish | More user-friendly, better autocompletion |
| Tmux | Zellij | Modern, Rust-based, better UX |
| Kitty | Ghostty | GPU-accelerated, better performance |

## Usage

### Managing Dotfiles with Stow

```bash
# Install a package
stow <package-name>

# Remove a package
stow -D <package-name>

# Reinstall a package
stow -R <package-name>

# Dry run (see what would happen)
stow -n <package-name>
```

### Adding New Configurations

1. Create a new directory with the package name
2. Mirror the home directory structure inside it
3. Place your configuration files in the appropriate locations
4. Use stow to install: `stow <package-name>`

Example:
```
new-package/
└── .config/
    └── new-app/
        └── config.toml
```

### Zellij Workflows

```bash
# Start a development session
zj dev dev

# Start a work session
zj work work  

# List all sessions
zj

# Attach to existing session
zj <session-name>
```

## Customization

### Fish Shell

- Edit `fish/.config/fish/config.fish` for shell configuration
- Add functions in `fish/.config/fish/functions/`
- Modify aliases and environment variables as needed

### Zellij

- Edit `zellij/.config/zellij/config.kdl` for keybindings and themes
- Add custom layouts in the `layouts` section
- Adjust keybindings to your preference

### Ghostty

- Edit `ghostty/.config/ghostty/ghostty` for terminal settings
- Adjust font, theme, and performance settings
- Customize keybindings for your workflow

## Troubleshooting

### Stow Conflicts

If stow reports conflicts:
```bash
# Remove conflicting files/links
rm ~/.config/fish/config.fish  # example

# Then retry stow
stow fish
```

### Shell Not Changing

If fish doesn't become your default shell:
```bash
# Check available shells
cat /etc/shells

# Ensure fish is in the list
which fish

# Change shell
chsh -s $(which fish)
```

### Zellij Not Auto-starting

If zellij doesn't auto-start, check:
1. Zellij is installed and in PATH
2. Fish configuration is properly sourced
3. No conflicts with other terminal multiplexers

### Hyprlock Rejects the Correct Password

`pam_faillock` keeps a single per-user tally (`/run/faillock/$USER`, `deny=3`,
`unlock_time=600`). Failed prompts from *any* service share it, including
`sudo` invoked without a TTY - an agent shell or a `paru`/`pacman` retry loop
logs `pam_unix(sudo:auth): conversation failed` every few minutes and drains
the tally. Hyprlock then refuses the correct password and reports minutes left
to unlock.

```bash
# Who burned the attempts, and when
faillock --user $USER
journalctl -b -g 'authentication failure|conversation failed|faillock' -o short-iso

# Clear it (no root needed; the tally file is owned by the user)
faillock --user $USER --reset
```

`pam/hyprlock` removes faillock from the locker's stack so unrelated failures
can no longer lock a live session; deploy it with
`sudo install -m 0644 pam/hyprlock /etc/pam.d/hyprlock`. Package managers still
need a real TTY: run them in a terminal, not from a detached/non-TTY shell.

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License. 