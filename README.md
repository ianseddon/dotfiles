# Dotfiles

Dotfiles for two Arch machines, deployed with [GNU Stow](https://www.gnu.org/software/stow/):

- **Desktop:** the Hyprland workstation. `XDG_CONFIG_HOME` is set (uwsm).
- **M75q:** the headless development host on the tailnet, reached over Tailscale SSH and herdr. `XDG_CONFIG_HOME` is unset. It is a tagged Tailscale node (`tag:server`), so it has no personal owner: the tailnet policy has to let your devices reach `tag:server`.

Both run the same development tools from one Nix flake and the same agent, review, and shell config from the Stow packages here. What only one machine needs is in its own place: `nix/hosts/<name>.nix` for packages, the `m75q` package for the M75q's units.

## Structure

Each top-level directory is a Stow package, mirroring `$HOME`.

| Package | What it holds | Desktop | M75q |
|---|---|---|---|
| `nix` | The flake and its fish/session PATH integration | ✓ | ✓ |
| `m75q` | Rootless Docker and herdr server units, `DOCKER_HOST` | | ✓ |
| `fish` | Shell config and functions; the Tide prompt's settings (`conf.d/tide.fish`) | ✓ | ✓ |
| `atuin`, `direnv` | Shell history search; per-directory environments (nix-direnv) | ✓ | ✓ |
| `git`, `gh`, `gh-dash`, `lazygit`, `bat`, `fd`, `nvim` | CLI tool config | ✓ | ✓ |
| `agents` | `~/AGENTS.md`, shared skills, `nexus-skills` | ✓ | ✓ |
| `pi`, `claude` | pi and Claude Code settings | ✓ | ✓ |
| `herdr`, `worktrunk`, `hunk`, `tuicr` | Workspaces, worktrees, and review | ✓ | ✓ |
| `hyprland`, `rofi`, `ghostty`, `voxtype`, `fontconfig` | The desktop session | ✓ | |
| `theme` | The `theme` command: colour themes and fonts (see [Theme](#theme)) | ✓ | |
| `quickshell` | The desktop shell (see [Shell](#shell)) | ✓ | |
| `vicinae` | The launcher on trial (see [Launcher](#launcher)) | ✓ | |
| `proton-pass` | SSH agent serving keys from Proton Pass | ✓ | |
| `borgmatic` | Hourly backups of `~` to BorgBase (see [Backups](#backups)) | ✓ | |
| `commitizen` | Commit message conventions | ✓ | ✓ |

`ly`, `pam` and `pacman` are system files, installed into `/etc` by hand rather than stowed; `i3` is the retired X11 session, kept for reference. `skills` isn't a Stow package either: it holds my own agent skills (see [Agents](#agents)), and `docs` holds design notes.

Packages whose app writes its own state next to the config are stowed with `--no-folding`, so only the tracked files are links and the directory stays real. `agents` and `gh` are stowed without it: their directories are links on purpose.

fish's universal variables (`~/.config/fish/fish_variables`) stay out of the repository: Tide and sponge rewrite them all the time. Settings belong in `conf.d` as globals instead. Fish plugins (Tide, fzf.fish, done, sponge) come from Nix's `fishPlugins`, not fisher.

## Nix

`nix/` provides the development tools as a user profile on `x86_64-linux`. It is not an Arch installer or a NixOS configuration.

- **Arch owns:** the kernel, hardware, networking, the Nix daemon, OpenSSH, Tailscale, the desktop session, and the login shell (`/bin/fish` from pacman, so a login never depends on a Nix generation).
- **Nix owns:** every development tool, listed in `nix/dev.nix`: git and gh (with its extensions), worktrunk, herdr, Hunk, tuicr, the agents (pi, Claude Code, codex), Node 24 with npm and Corepack, Bun, uv, fnm, the AWS CLI, linters, and the rest. `nix/hosts/m75q.nix` adds rootless Docker.
- **Stow owns:** the dotfile symlinks. No Home Manager.

A tool belongs in `dev.nix` when both machines use it. Python is uv's (per-project interpreters, `uv tool`); Node is fnm's per project (`.node-version`, `.nvmrc`, `engines`), falling back to `fnm default`, the newest 24.x. Nix's Node 24 serves everything outside fish.

nixpkgs is the only flake input that moves on its own, so `nix flake update` advances everything. pi is the exception: it comes from its repository at a release tag (`inputs.pi.url` in `nix/flake.nix`), because nixpkgs trails its releases and its main branch often doesn't build.

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
stow --no-folding --target="$HOME" nix fish atuin direnv git gh-dash lazygit bat fd nvim pi claude herdr worktrunk hunk
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

## Theme

One command sets the desktop's colour scheme, and another sets its fonts. The two are independent. The design is in [docs/desktop-shell/](docs/desktop-shell/).

```bash
theme list                          # the current theme is marked
theme set tokyo-night               # also: kanagawa, gruvbox-material, oxocarbon
theme font                          # the mono and sans families in use
theme font mono "JetBrains Mono"    # any installed family (fc-list : family)
theme check                         # validate every theme without switching
```

**Colours.** A theme is a folder in `theme/.config/theme/themes/<name>/`, holding a `colors.toml` in [Omarchy's palette format](https://github.com/basecamp/omarchy/blob/master/docs/theming.md).

- **Omarchy themes:** an Omarchy theme folder can be copied into `~/.config/theme/themes/` and used as is.
- **Theme files:** other files in a theme folder replace the generated file of the same name. This is how a theme uses an app's native port.
- **Templates:** each target app has a template in `templates/`, with placeholders like `{{ accent }}`, `{{ accent_strip }}` (no `#`) and `{{ accent_rgb }}`.
- **Generated files:** `theme set` writes them to `~/.local/state/theme/current/`, and the app configs include them from there. Switching therefore never changes a tracked file.

**Fonts.** `theme font` writes `~/.local/state/theme/fonts.conf`, which `fontconfig/fonts.conf` includes ahead of its defaults (Mononoki Nerd Font, Inter). Delete that file to return to the defaults.

- **One source:** fontconfig's `monospace` and `sans-serif` aliases decide the fonts. Apps should ask for those generic names, not a named font.
- **Icons:** `Symbols Nerd Font` supplies icons to fonts that have none.
- **Packages:** the fonts come from pacman (desktop only):

  ```bash
  # Defaults, icons, and coverage: Latin, emoji, Japanese, Chinese, Korean, and
  # Arial/Times/Courier-compatible metrics for web pages.
  sudo pacman -S --needed inter-font ttf-mononoki-nerd ttf-nerd-fonts-symbols \
      noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-liberation
  # Monospace alternatives for `theme font mono`.
  sudo pacman -S --needed ttf-jetbrains-mono-nerd ttf-firacode-nerd ttf-ibmplex-mono-nerd
  ```

  Arch's default presets already turn on antialiasing, slight hinting and the LCD filter. Subpixel rendering stays off: DP-3 is rotated, so its subpixels run vertically, and translucent windows would give the text colour fringes.

**Reload hooks.** After either command, the hooks in `hooks/` bring each app in line:

| Hook | What it updates |
|---|---|
| Hyprland | Its borders, via `hyprctl reload`. |
| GTK and libadwaita | gsettings points at the generic font names, and its light or dark mode follows the theme. |
| herdr-app | Its theme (`themes/current.json`) and its fonts (`settings.json`). It does not read fontconfig's aliases, so the hook gives it the resolved family names. |
| Ghostty | It reloads on `SIGUSR2`. |
| The login screen | It gets a copy of the palette. |

hyprlock reads its colours each time it starts. bat, delta and the Tide prompt use the terminal's 16 colours, so they follow the theme through the terminal's palette.

The login screen runs as the `greeter` user, which can't read `~`, so the greeter hook copies the palette to `/var/lib/greeter-theme`. Create that directory once:

```bash
sudo install -d -o "$USER" -g greeter -m 0750 /var/lib/greeter-theme
theme set "$(theme current)"
```

Tests and lint, from the repo root:

```bash
python3 -m unittest discover -s theme/tests
(cd theme && ruff check . && ruff format --check . && basedpyright)
shellcheck theme/.config/theme/hooks/*
```

## Shell

The desktop shell is [Quickshell](https://quickshell.org/) (`sudo pacman -S quickshell`). The design is in [docs/desktop-shell/](docs/desktop-shell/). It is the bar (replacing Waybar), plus the shared theme and style values and a theme preview. The bar is calm at rest and shows detail on hover or click; values and indicators appear by themselves only when something needs attention (see [SPEC-bar.md](docs/desktop-shell/SPEC-bar.md)).

```bash
stow --target="$HOME" quickshell             # folded: ~/.config/quickshell links to the package
systemctl --user enable --now quickshell     # starts with the Hyprland session
qs ipc call theme preview                    # show or hide the palette and fonts
journalctl --user -u quickshell -f           # the log
qs -p ~/dotfiles/quickshell/.config/quickshell   # a second instance for development
```

Editing a QML file reloads the running shell. The `60-quickshell` theme hook tells every running instance to re-read the palette and fonts.

- **Colours and fonts:** `theme/Theme.qml` exposes the palette and the font families fontconfig resolves. It uses the resolved names rather than `monospace`, because Qt reads fontconfig's configuration only at startup, and exact names switch live.
- **Sizes:** spacing, radius, font sizes and motion are in `theme/Style.qml`.

Checks, from the repo root:

```bash
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input quickshell/tests
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml $(find "$PWD/quickshell/.config/quickshell" -name '*.qml')
/usr/lib/qt6/bin/qmlformat -i <file.qml>
```

Known noise:

- **`qmllint`'s path handling:** pass absolute paths. With relative paths it misreads `theme/qmldir` and reports the singletons as undeclared.
- **Quickshell's own type information (`qmllint`):** three kinds of finding come from it, and the code works in each case:
  - `PanelWindow` "is not creatable": Quickshell creates its window types through a proxy, so its type information marks them uncreatable.
  - `values` "not found on type UntypedObjectModel": Quickshell's object models have a `values` list that its type information doesn't describe.
  - A popup's `anchor.item`, `anchor.edges` and the like "not found": the same proxy problem, for `PopupWindow`.
- **`qt.qpa.wayland.textinput` "Trying to disable … but 0x0 is focused" (the log):** Qt logs this whenever a shell surface that had keyboard focus closes. It is a known, harmless Qt Wayland bug that also appears in other Qt apps and Quickshell shells.

## Launcher

[Vicinae](https://vicinae.com) is on trial as the launcher (`SUPER+SPACE`; Rofi remains on `SUPER+ALT+SPACE` until the trial ends). It comes from the AUR (`vicinae-bin`) and runs as its own user service, which launches apps through `uwsm app`.

```bash
sudo install -m 0644 pacman/hooks/vicinae-no-capability.hook /etc/pacman.d/hooks/   # before installing
paru -S vicinae-bin
stow --no-folding --target="$HOME" vicinae
printf '{\n\t"imports": ["dotfiles.jsonc"]\n}\n' > ~/.config/vicinae/settings.json   # if it doesn't exist yet
systemctl --user enable --now vicinae
```

- **Settings:** Vicinae rewrites `settings.json` itself, so the tracked settings live in `dotfiles.jsonc`, which `settings.json` imports and Vicinae never touches. They select the `dotfiles` theme and the system UI font.
- **Theme:** the `35-vicinae` theme hook installs the palette as `~/.local/share/vicinae/themes/dotfiles.toml`.
- **Capability:** the package gives its input helper `cap_dac_override`, which lets it bypass every file permission. This user is in the `input` group, which is all the helper needs, so the pacman hook removes the capability after every install and upgrade.

## Backups

The desktop backs up `~` to [BorgBase](https://www.borgbase.com) every hour with borgmatic, as a `systemd --user` timer. The `borgmatic` package holds the configuration and units, and `nix/hosts/desktop.nix` provides borgmatic and borg. The repository is `desktop` (`ssh://w0dtrp32@w0dtrp32.repo.borgbase.com/./repo`), encrypted with `repokey-blake2`; its server host keys are pinned in `borgmatic/.config/borgmatic/known_hosts`.

- **What's included:** all of `~` except what can be rebuilt or downloaded again: caches, package stores and toolchains, editor plugins, project dependencies and build output, apps whose state lives on their servers, `~/Downloads`, and database dumps. The list is `exclude_patterns` in `config.yaml`. To skip one directory without editing it, create a `.nobackup` file in it.
- **Git repositories** are backed up with their `.git`. Stashes, unpushed branches, uncommitted changes, and ignored `.env` files exist only on this disk, so a remote is not a backup of them. After a restore, reinstall dependencies (`pnpm install`, `uv sync`).
- **Retention:** 24 hourly, 7 daily, 4 weekly, and 12 monthly `home-*` archives.
- **Root-only material** goes into `system-*` archives with `backup-system`, which asks for authorisation through polkit: `/etc` (including `/etc/kernel/keys`), `/var/lib/sbctl`, and `/root/recovery` (a LUKS header backup it refreshes on each run, plus the factory Secure Boot keys). It isn't on the timer. Run it after changing `/etc`, the Secure Boot keys, or the LUKS key slots, such as a TPM re-enrollment.

Two things on each machine stay out of this repository:

- `~/.config/borgmatic/passphrase` (mode 0600). It and the exported repository key are also in Proton Pass, in the note **BorgBase desktop repository**.
- `~/.ssh/borgbase-desktop`, the BorgBase key with append-only access. A compromised desktop can add archives but not destroy old ones. Pruning only marks archives as deleted; to free space, use **More > Compact repo** in BorgBase.

BorgBase alerts by email when no backup has arrived for two days. The timer only runs while you're logged in (no lingering) and catches up on the next login. A failed run shows a desktop notification.

Setting up a machine, after adding its key to BorgBase:

```bash
ssh-keygen -t ed25519 -N '' -C desktop-backup@borgbase -f ~/.ssh/borgbase-desktop
stow --no-folding --target="$HOME" borgmatic
# Write the passphrase from Proton Pass to ~/.config/borgmatic/passphrase (mode 0600).
systemctl --user daemon-reload
systemctl --user enable --now borgmatic.timer
```

Restoring:

```bash
borgmatic list                                   # home-* archives
borgmatic mount --archive latest --mount-point ~/mnt/backup
borgmatic extract --archive latest --path home/ian/dev/some-repo --destination /tmp/restore
borgmatic -c ~/.config/borgmatic/system.yaml list   # system-* archives
```

## Agents

pi, Claude Code, and codex all run from the Nix profile; their self-updaters don't apply.

- **Instructions:** `~/AGENTS.md` (from `agents/AGENTS.md`).
- **Skills:** `~/.agents/skills` is `agents/.agents/skills`, the installed set. My own skills (preferences and workflows) are written in `skills/` and linked in from there (`ian-reviewer -> ../../../skills/ian-reviewer`), so edits take effect immediately. Elsewhere, `pnpx skills add ianseddon/dotfiles` installs them, and only them: the CLI stops at `skills/` and never reaches the third-party copies. Skills a Nix package ships (herdr, Hunk, worktrunk, gh-stack) are links into `~/.nix-profile/share/skills`, so they move with the package. The other third-party skills are copies, and `agents/.agents/.skill-lock.json` records where they came from. A skill that needs a herdr plugin ships it in its own directory and links it on first use (`herdr-secret-input`).
- **pi:** `pi/.pi/agent/settings.json` holds the shared settings and packages (`pi update --extensions` installs them). `pi-web-access` reads `web-search.json` from `~/.config/pi` when `XDG_CONFIG_HOME` is set and from `~/.pi/agent` when it isn't, so the file is linked into both. It routes `web_search` through Kagi (v1 API, funded balance), then keyless Exa, and reads `$KAGI_API_KEY` from the environment. The default provider is `cpa`, the self-hosted [CLIProxyAPI](https://cliproxyapi.ians.cloud) (`@hank-warren/pi-cliproxyapi-provider`, configured in `pi-cliproxyapi-provider/config.json`); `extensions/cliproxyapi-kimi.ts` adapts Kimi's message roles to it. Project-local `.pi` files are trusted without asking (`defaultProjectTrust: "always"`), so new worktrees don't stop firstmate workers at a trust prompt; install telemetry is off; and `pi update` refuses to self-update, pointing at the pinned tag in `nix/flake.nix` instead. `@nicknisi/pi-session-name` names each session from its first prompt (`configs/session-name.json`), `keybindings.json` adds alt+m for the model picker because herdr's navigation takes ctrl+l, and on the M75q `PI_CLIPBOARD_OSC52` sends pi's copies to the attached desktop.
- **Claude Code:** `claude/.claude/settings.json`, including the plugin marketplaces it installs from. It talks to CLIProxyAPI (`ANTHROPIC_BASE_URL`), and its `apiKeyHelper` fetches the key from Infisical (see [Secrets](#secrets)). Auto memory is off (`autoMemoryEnabled: false`), so durable notes belong in this repository or a project's `AGENTS.md`, not in `~/.claude/projects/*/memory`.
- **codex:** its `config.toml` is machine state (project trust, hook hashes), so it isn't tracked; add its plugins with `codex plugin add`.

### agent-skills commands in pi

`npx skills add addyosmani/agent-skills` installs only the skills. In Claude Code, the agent-skills plugin also provides one command per lifecycle phase (`/spec`, `/plan`, `/build`, `/test`, `/review`, `/code-simplify`, `/ship`, `/webperf`, `/constraints`), the reviewer personas that `/ship` and `/webperf` run, and the shared `references/` the skills link to. `agent-skills-pi` gives pi the same set. It fetches upstream at the commit in `agents/.agents/.skill-lock.json` and generates:

- the commands as prompt templates in `pi/.pi/agent/prompts/`, with short notes that map Claude Code terms to pi;
- the personas as [pi-subagents](https://github.com/nicobailon/pi-subagents) agents in `pi/.pi/agent/agents/`, so `/ship` runs them in parallel as Claude Code does;
- the references in `agents/.agents/references/`, which is where the skills' `../../references/` links point.

The generated files are marked and must not be edited by hand. After updating the skills, regenerate and link any new files:

```bash
npx skills update
agent-skills-pi
stow --no-folding --target="$HOME" pi
```

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
# pi reports its own state to herdr, and herdr reopens pi sessions after a restart.
herdr integration install pi
```

Notifications go through the terminal (`[ui.toast] delivery = "terminal"`), so Ghostty raises them for local and remote workspaces alike.

### Dev servers over Tailscale (M75q)

The M75q has no browser of its own, so `m75q/.config/fish/conf.d/portless.fish` sets `PORTLESS_TAILSCALE=1`. [portless](https://portless.sh/commands#share-on-tailscale) then shares every app it runs through `tailscale serve`, beside its `https://*.localhost` URL, and removes the share when the app stops. The first app gets `https://m75q.hawk-monster.ts.net`, and each app after it gets the next free port from 8443. `pnpm dev` prints each tailnet URL, and `portless list` prints them again. Browsers keep cookies per host, not per port, so apps that share the host also share cookies: run one Nova at a time when you test it this way.

In workforce-monorepo, Nova accepts sign-in on both URLs. Its Keycloak must also be reachable from other devices. The same file sets `KC_HOSTNAME`, the URL that the compose Keycloak serves its pages at and issues tokens for. Publish Keycloak at that URL once, then recreate the container:

```bash
tailscale serve --bg --https=8080 http://127.0.0.1:8080
pnpm docker:up   # from a workforce-monorepo checkout that reads KC_HOSTNAME
```

`tailscale serve` runs unprivileged only when this user is Tailscale's operator (`sudo tailscale set --operator=$USER`). A checkout from before `KC_HOSTNAME` existed expects the issuer `http://localhost:8080/realms/pool`, so sign-in fails there until it is rebased. Running `pnpm docker:up` from such a checkout also moves Keycloak back to localhost.

### Browser dashboard: agent-browser (M75q)

agent-browser's dashboard (live view of the agents' browser sessions) runs as `agent-browser-dashboard.service` on `127.0.0.1:4848` and is published as its own Tailscale Service, because it has no base-path support and can't live under a path of the root host:

```bash
systemctl --user enable --now agent-browser-dashboard.service
tailscale serve --service=svc:agent-browser --https=443 http://127.0.0.1:4848
```

Open `https://agent-browser.hawk-monster.ts.net` (`https://m75q.hawk-monster.ts.net:4848` also still works). Through a proxy it always asks for its token link, which changes on every restart: `journalctl --user -u agent-browser-dashboard -n 20`. Test-account logins for its sessions live in agent-browser's own vault (`agent-browser auth save <name> ... --password-stdin`), not in this repository.

## Secrets

None are in this repository. The agents' API keys (`KAGI_API_KEY`, `OPENCODE_API_KEY`, `CLIPROXYAPI_API_KEY`) live in the `agents` project of the self-hosted [Infisical](https://infisical.ians.cloud), environment `prod`. Each machine reads it as its own Universal Auth machine identity (`desktop`, `m75q`) with the project's Viewer role, so either can be revoked alone.

```bash
agent-secrets-login    # once per machine: project ID, client ID, client secret
```

That writes `~/.config/infisical/agents.env` (mode 0600), the machine's one local secret. `with-agent-secrets <command>` signs in with it, caches Infisical's token on tmpfs for an hour, and starts the command with the project's secrets added to its environment; Infisical's token itself never reaches the command. The `pi` fish function runs pi that way. To add a key, add it to the project; nothing here changes.

Tools that ask for their key on each request use `agent-secret <NAME>`, which prints one key; the project's values are kept on tmpfs for five minutes so that isn't an Infisical call every time. Claude Code's `apiKeyHelper` is `fish -c 'agent-secret CLIPROXYAPI_API_KEY'`. pi's `auth.json` isn't tracked, so set its `cpa` key once per machine; this also covers pi started without the fish function, such as firstmate's workers:

```bash
jq '.cpa = {type: "api_key", key: "!fish -c '\''agent-secret CLIPROXYAPI_API_KEY'\''"}' ~/.pi/agent/auth.json > /tmp/auth.json \
  && install -m 600 /tmp/auth.json ~/.pi/agent/auth.json && rm /tmp/auth.json
```

SSH keys live in Proton Pass, vault `SSH`, and only the desktop serves them: `proton-pass-agent.service` runs `pass-cli ssh-agent` on `$XDG_RUNTIME_DIR/proton-pass-agent.sock`, and `~/.ssh/config` (not tracked) points `IdentityAgent` there and names each host's key by its `.pub` file with `IdentitiesOnly yes`. New or rotated keys appear within 30 seconds of being saved to the vault. The CLI is never signed in on M75q, where agents run unattended. Keys must be stored without a passphrase (the vault encrypts them); the agent skips passphrase-protected ones. The CLI signs in with a personal access token that can only view the `SSH` vault, not the whole account, so the session stored on the desktop can't read the other vaults. Tokens last at most a year: renew with `pass-cli personal-access-token renew` (from a full `pass-cli login`, then switch back). New keys are added in the Proton Pass app.

pass-cli encrypts its stored session with a key that it keeps in GNOME Keyring. `environment.d/50-proton-pass.conf` sets `PROTON_PASS_LINUX_KEYRING=dbus` for the systemd user units and the whole Hyprland session. `pam/greetd` unlocks the `login` keyring with the login password. The agent starts with `graphical-session.target`, after that unlock. pass-cli's default kernel keyring is cleared on reboot, and pass-cli then deletes the session (see [Troubleshooting](#the-ssh-agent-is-logged-out-after-a-reboot)). Setting up a machine:

```bash
sudo pacman -S --needed gnome-keyring
sudo install -m 0644 pam/greetd /etc/pam.d/greetd
stow --no-folding --target="$HOME" proton-pass
# Log out and back in: PAM creates the login keyring and the session gets the environment.
pass-cli login    # full account, once, to create the token
pass-cli personal-access-token create --name <machine>-ssh-agent --expiration 1y
pass-cli personal-access-token access grant --personal-access-token-name <machine>-ssh-agent --vault-name SSH --role viewer
pass-cli logout
read -s -P 'token: ' pat; pass-cli login --pat $pat; set -e pat
systemctl --user enable --now proton-pass-agent.service
```

Use `enable`, never `reenable`, for this unit: it is a link into the dotfiles, and `disable` deletes that link. Re-stow if it goes missing.

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

### The SSH agent is logged out after a reboot

`journalctl --user -u proton-pass-agent` shows `Local encryption key not found but local data exists. Forcing logout`, then `This operation requires an authenticated client` every 10 seconds. pass-cli could not read its session key, so it deleted the session. Common causes:

- `PROTON_PASS_LINUX_KEYRING` is not `dbus` for that run. Check `systemctl --user show-environment` and `echo $PROTON_PASS_LINUX_KEYRING`. A single `pass-cli` command without it looks in the kernel keyring and logs out.
- The `login` keyring is locked or missing. Its password must match the login password, and `/etc/pam.d/greetd` must contain the `pam_gnome_keyring` lines from `pam/greetd`. Check with `busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked`.

Fix the cause, then sign in again with the token (see [Secrets](#secrets)) and run `systemctl --user restart proton-pass-agent`.
