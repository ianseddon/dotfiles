# Dotfiles

Dotfiles for two Arch machines, deployed with [GNU Stow](https://www.gnu.org/software/stow/):

- **Desktop:** the Hyprland workstation. `XDG_CONFIG_HOME` is set (uwsm).
- **M75q:** the headless development host on the tailnet, reached over Tailscale SSH and herdr. `XDG_CONFIG_HOME` is unset.

Both run the same development tools from one Nix flake and the same agent, review, and shell config from the Stow packages here. What only one machine needs is in its own place: `nix/hosts/<name>.nix` for packages, the `m75q` package for the M75q's units.

## Structure

Each top-level directory is a Stow package, mirroring `$HOME`.

| Package | What it holds | Desktop | M75q |
|---|---|---|---|
| `nix` | The flake and its fish/session PATH integration | ✓ | ✓ |
| `m75q` | Rootless Docker and herdr server units, `DOCKER_HOST` | | ✓ |
| `fish` | Shell config, functions, plugins | ✓ | ✓ |
| `git`, `gh`, `gh-dash`, `lazygit`, `bat`, `fd`, `nvim` | CLI tool config | ✓ | ✓ |
| `agents` | `~/AGENTS.md`, shared skills, `nexus-skills` | ✓ | ✓ |
| `pi`, `claude` | pi and Claude Code settings | ✓ | ✓ |
| `herdr`, `worktrunk`, `hunk`, `tuicr` | Workspaces, worktrees, and review | ✓ | ✓ |
| `hyprland`, `waybar`, `rofi`, `ghostty`, `voxtype`, `fontconfig` | The desktop session | ✓ | |
| `commitizen` | Commit message conventions | ✓ | ✓ |

`ly` and `pam` are system files, installed into `/etc` by hand rather than stowed; `i3` is the retired X11 session, kept for reference.

Packages whose app writes its own state next to the config are stowed with `--no-folding`, so only the tracked files are links and the directory stays real. `agents` and `gh` are stowed without it: their directories are links on purpose.

## Nix

`nix/` provides the development tools as a user profile on `x86_64-linux`. It is not an Arch installer or a NixOS configuration.

- **Arch owns:** the kernel, hardware, networking, the Nix daemon, OpenSSH, Tailscale, the desktop session, and the login shell (`/bin/fish` from pacman, so a login never depends on a Nix generation).
- **Nix owns:** every development tool, listed in `nix/dev.nix`: git and gh (with its extensions), worktrunk, herdr, Hunk, tuicr, the agents (pi, Claude Code, codex), Node 24 with npm and Corepack, Bun, uv, fnm, the AWS CLI, linters, and the rest. `nix/hosts/m75q.nix` adds rootless Docker.
- **Stow owns:** the dotfile symlinks. No Home Manager.

A tool belongs in `dev.nix` when both machines use it. Python is uv's (per-project interpreters, `uv tool`); Node is fnm's per project (`.node-version`, `.nvmrc`, `engines`), falling back to `fnm default`, the newest 24.x. Nix's Node 24 serves everything outside fish.

nixpkgs is the only flake input that moves on its own, so `nix flake update` advances everything. pi is the exception: it comes from its repository at a release tag (`inputs.pi.url` in `nix/flake.nix`), because nixpkgs trails its releases and its main branch often doesn't build. `nix/patches/pi-schema-tarball.patch` carries an upstream fix until [earendil-works/pi#11685](https://github.com/earendil-works/pi/pull/11685) merges; delete it then, and the build fails loudly if it stops applying.

### Bootstrap a machine

From an installed, networked Arch system with a normal sudo user:

```bash
sudo pacman -Syu --needed nix git fish openssh tailscale stow
sudo systemctl enable --now nix-daemon.service tailscaled.service
source /etc/profile.d/nix-daemon.sh
sudo tailscale up --ssh

git clone https://github.com/ianseddon/dotfiles.git ~/dotfiles
cd ~/dotfiles
# `desktop` or `m75q`. Explicit flags: the user-level nix.conf isn't stowed yet.
nix --extra-experimental-features 'nix-command flakes' profile add path:./nix#m75q
export PATH="$HOME/.nix-profile/bin:$PATH"

# pi's settings.json: drop the state pi writes back on each machine when staging.
git config filter.pi-settings.clean "jq --indent 2 'del(.deviceId, .lastChangelogVersion, .extensionChangelogVersions)'"
git config filter.pi-settings.smudge cat

mkdir -p ~/.config/{worktrunk,herdr,hunk,pi} ~/.pi/agent ~/.claude
stow --no-folding --target="$HOME" nix fish git gh-dash lazygit bat fd nvim pi claude herdr worktrunk hunk
stow --target="$HOME" agents gh tuicr
fnm install 24 && fnm default 24
```

The M75q also stows `m75q` (`--no-folding`) and starts its user services; lingering runs them without a login:

```bash
sudo loginctl enable-linger "$USER"
systemctl --user daemon-reload
systemctl --user enable --now docker.service herdr.service
```

Keep the checkout at `~/dotfiles`: the symlinks and the profile refer to it. Stow refuses to overwrite existing files; move each aside and compare it with the repo's version rather than forcing it.

Then sign in: `gh auth login`, `claude`, `codex login`, and pi's `/login` per provider. Nothing in this repository holds a credential (see [Secrets](#secrets)).

### Update and roll back

```bash
cd ~/dotfiles
nix flake update --flake path:./nix      # nixpkgs; a pi release is an edit of its tag
nix build --no-link path:./nix#desktop path:./nix#m75q
nix profile upgrade desktop               # or m75q
# Review and commit nix/flake.lock.

nix profile history
nix profile rollback
```

A new herdr keeps running the old binary, and its panes, until the server stops (`herdr server stop`; the desktop's next connection starts it again).

### Docker (M75q)

Docker runs rootless: `docker.service` is a `systemd --user` unit running the profile's `dockerd-rootless`, so there's no pacman Docker, `docker` group, or sudo. Arch only supplies `newuidmap`/`newgidmap` and the `ian:100000:65536` range in `/etc/subuid` and `/etc/subgid`. `m75q/.config/fish/conf.d/docker.fish` points the CLI at `/run/user/$UID/docker.sock`, because Tailscale SSH sessions don't set `XDG_RUNTIME_DIR`.

```bash
systemctl --user status docker.service
docker info --format '{{json .SecurityOptions}}'   # includes "name=rootless"
```

Rootless limits: published ports must be 1024 or higher, `--network host` is RootlessKit's namespace, and files that non-root container users write to bind mounts belong to subordinate UIDs (reclaim with `docker run --rm -v "$PWD:/w" alpine chown -R 0:0 /w`). Images and volumes live under `~/.local/share/docker`.

## Agents

pi, Claude Code, and codex all run from the Nix profile; their self-updaters don't apply.

- **Instructions:** `~/AGENTS.md` (from `agents/AGENTS.md`).
- **Skills:** `~/.agents/skills` is `agents/.agents/skills`. Skills a Nix package ships (herdr, Hunk, worktrunk, gh-stack) are links into `~/.nix-profile/share/skills`, so they move with the package; the rest are copies, and `agents/.agents/.skill-lock.json` records where they came from.
- **pi:** `pi/.pi/agent/settings.json` holds the shared settings and packages (`pi update --extensions` installs them). `pi-web-access` reads `web-search.json` from `~/.config/pi` when `XDG_CONFIG_HOME` is set and from `~/.pi/agent` when it isn't, so the file is linked into both. It routes `web_search` through Kagi (v1 API, funded balance), then keyless Exa, and reads `$KAGI_API_KEY` from the environment.
- **Claude Code:** `claude/.claude/settings.json`, including the plugin marketplaces it installs from.
- **codex:** its `config.toml` is machine state (project trust, hook hashes), so it isn't tracked; add its plugins with `codex plugin add`.

### Nexus-only skills

The AWS and Bedrock skills are work material, so they stay out of this public repository and out of every other project. Each machine keeps them in `~/.local/share/nexus-skills/<name>/`, and `nexus-skills` links them into a checkout's `.agents/skills` (pi, codex) and `.claude/skills` (Claude Code), listing the links in `.git/info/exclude` so they never show as changes. It only touches `workforce-monorepo` and `nexus-*` checkouts. worktrunk runs it for every new worktree; for existing checkouts:

```bash
nexus-skills ~/dev/nexus/*/          # any checkouts; others are skipped
```

### WakaTime

Every harness reports to WakaTime through its own plugin, each of which installs `wakatime-cli` under `~/.wakatime` and reads `~/.wakatime.cfg`:

```bash
# pi: npm:pi-wakatime is in settings.json.
# Claude Code: the marketplace and plugin are in settings.json; on a new machine
claude plugin install claude-code-wakatime@wakatime
# codex
codex plugin marketplace add wakatime/codex-cli-wakatime
codex plugin add codex-cli-wakatime@wakatime
```

Since November 2026 WakaTime accepts API keys only on the endpoints plugins use (heartbeats, today's total); anything reading the rest of its API needs OAuth.

## Review

Hunk reviews my own agents' changes; tuicr reviews other people's PRs. See [docs/pr-review.md](docs/pr-review.md).

Hunk's extensions are copied, not linked: Hunk resolves their imports relative to the real path, which a Stow link breaks.

```bash
mkdir -p ~/.config/hunk/extensions
cp -R ~/dotfiles/hunk/extensions/* ~/.config/hunk/extensions/
```

## herdr

The desktop opens the M75q as a saved herdr machine (`herdr machine add m75q --label M75q`). Plugin actions and hooks run on the server that owns the workspace, and herdr copies nothing to SSH hosts, so both machines install the same plugins:

```bash
herdr plugin install -y --ref b187fb76a9b12810d4fde937da0e4215689006d0 ianseddon/herdr-git-status
herdr plugin install -y --ref e393ef593e44d2497f43d20aa7b0e4a26ea3d445 tomasvarga/herdr-pickr
herdr plugin install -y --ref 742db891e7d1f9a550b16c01dc8a6763f2b1493a paulbkim-dev/vim-herdr-navigation
herdr plugin install -y --ref f9df9ba700b8a4f4d97ddfe3ea3eb345e80b880b devashish2203/herdr-worktrunk
herdr plugin install -y --ref v0.13.0 jeffarese/herdr-bar
herdr plugin install -y --ref v0.5.0 jhochenbaum/herdr-hunk-diff
for p in ~/dotfiles/herdr/.local/share/herdr-plugins/*/; do herdr plugin link "$p"; done
# Once: git-status's startup hook only restarts a poller that was running before.
herdr plugin action invoke start --plugin git-status
```

### Phone and browser: Ovis (M75q)

[Ovis](https://github.com/devswha/ovis) (formerly herdr web UI) runs where the agents do: it shows herdr's layout, each agent's transcript as a chat beside the live terminal, and sends push alerts when an agent needs input or finishes. Requests from this host's own Tailscale login get in; any other device needs a pairing code.

```bash
herdr plugin install devswha/ovis --yes
cfg=$(herdr plugin config-dir devswha.ovis); mkdir -p "$cfg"
printf '%s\n' OVIS_TELEMETRY=0 OVIS_APP_NAME=M75q \
  OVIS_PUSH_SUBJECT=mailto:ianseddon55@gmail.com > "$cfg/env"; chmod 600 "$cfg/env"
herdr plugin action invoke devswha.ovis.start   # also starts with herdr from now on
tailscale serve --bg --https=443 http://127.0.0.1:7317
```

Open `https://m75q.hawk-monster.ts.net` on the phone, install it, then **Settings → Alerts → Send test**. HTTPS is required for install and push, Tailscale's operator must be this user (`sudo tailscale set --operator=$USER`) for `tailscale serve` to run unprivileged, and renaming the host changes the origin, so phones subscribe again. State (push keys, subscriptions, updates) is in `~/.config/ovis`; new releases come through **Settings → Updates**. Collie, used before it, is removed from both machines.

## Secrets

None are in this repository. The agents' API keys (`KAGI_API_KEY`, `OPENCODE_API_KEY`) live in the `agents` project of the self-hosted [Infisical](https://infisical.ians.cloud), environment `prod`. Each machine reads it as its own Universal Auth machine identity (`desktop`, `m75q`) with the project's Viewer role, so either can be revoked alone.

```bash
agent-secrets-login    # once per machine: project ID, client ID, client secret
```

That writes `~/.config/infisical/agents.env` (mode 0600), the machine's one local secret. `with-agent-secrets <command>` signs in with it, caches Infisical's token on tmpfs for an hour, and starts the command with the project's secrets added to its environment; Infisical's token itself never reaches the command. The `pi` fish function runs pi that way. To add a key, add it to the project; nothing here changes.

OAuth logins stay with each tool on each machine (pi's `/login`, `claude`, `codex login`), because the tools refresh and rewrite those tokens themselves. The AWS CLI's configuration stays out too, since `~/.aws/config` names account IDs and SSO URLs: copy it between machines (mode 0600) and sign in on the headless host with a device code:

```bash
aws sso login --use-device-code --sso-session <name>
```

## Troubleshooting

### Hyprlock rejects the correct password

`pam_faillock` keeps one per-user tally (`/run/faillock/$USER`, `deny=3`, `unlock_time=600`). Failed prompts from any service share it, including `sudo` without a TTY: an agent shell or a `paru`/`pacman` retry loop logs `pam_unix(sudo:auth): conversation failed` every few minutes and drains the tally, and Hyprlock then refuses the correct password.

```bash
faillock --user $USER
journalctl -b -g 'authentication failure|conversation failed|faillock' -o short-iso
faillock --user $USER --reset   # no root needed
```

`pam/hyprlock` removes faillock from the locker's stack, so unrelated failures can't lock a live session: `sudo install -m 0644 pam/hyprlock /etc/pam.d/hyprlock`. Run package managers in a real terminal, not a detached shell.
