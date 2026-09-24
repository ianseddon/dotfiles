# M75q: headless Arch development host

A targeted installation guide for Ian's Lenovo M75q Gen 2: Arch owns the machine; Nix supplies the development tools. This is a manual installation, not a script to run wholesale.

For a named configuration-file block, create or edit that file with `nano` and copy the block into it. Run shell-command blocks one stage at a time, checking errors before continuing. Do not paste the whole guide into a terminal.

**Destructive scope:** this is a single-OS installation that erases the selected internal SSD, including any Windows/recovery partitions. Back up anything worth keeping first. Do not run disk commands on the existing Arch workstation or the Proxmox host.

## Target configuration

| Component | Choice |
| --- | --- |
| Hostname / account | `m75q-dev` / `ian` |
| Firmware / boot | UEFI, systemd-boot, signed unified kernel images (UKIs), Secure Boot |
| Kernel | `linux-lts`, AMD microcode |
| Storage | GPT; 2 GiB FAT32 EFI system partition at `/efi`; remainder LUKS2 with ext4 at `/` |
| Encryption | TPM2 automatic unlock, no boot PIN, retained recovery key/passphrase |
| Boot trust | Secure Boot plus signed PCR11 policies; no fixed kernel-version PCR11 binding |
| Memory | zram up to half of RAM, capped at 8 GiB; no hibernation |
| Network | Wired Ethernet, DHCP, systemd-networkd and systemd-resolved |
| Remote access | Tailscale SSH; no public SSH port or enabled OpenSSH server |
| Login shell | Arch's `/bin/bash`; Nix Fish is optional, launched after login |
| Locale / time | `en_US.UTF-8`, US console keymap, `America/Montreal` |
| Development | The adjacent `nix/` flake, including rootless Docker as a user service; no desktop, Home Manager, or copied agent state |

The timezone/locale match the current workstation. Change them if desired. `/home`, `/nix`, and the ordinary `/boot` directory live inside the encrypted root filesystem. Only signed boot artifacts are placed on the unencrypted ESP. A 2 GiB ESP leaves room for normal and fallback UKIs without dividing the rest of the SSD into fixed-size partitions.

TPM unlock protects a removed SSD and checks the boot environment. It does not protect data from a compromised running system. Firmware/key-policy changes or a failed TPM can still require a local recovery unlock. Keep the monitor and keyboard connected until the acceptance checks pass.

## 1. Prepare the machine and installation USB

**On the existing workstation:**

1. Download the current ISO and its signature from [Arch's official download page](https://archlinux.org/download/).
2. Verify the signature using the instructions there. On an existing Arch system, `pacman-key -v archlinux-<version>-x86_64.iso.sig` is available; use the actual downloaded filename.
3. Write the verified ISO to a USB using the [Arch USB installation instructions](https://wiki.archlinux.org/title/USB_flash_installation_medium). This overwrites the USB, not the M75q's SSD. Check the USB's model/serial before writing it.
4. Keep this guide available on another device. Attach Ethernet, a monitor, and a USB keyboard to the M75q. Disconnect unrelated external disks.

**In the M75q firmware:**

- Use UEFI boot, not Legacy/CSM.
- Enable the TPM 2.0/security device. Do not clear an existing TPM casually: it can hold keys for the old installation.
- Temporarily disable Secure Boot because the official Arch ISO does not support it. We re-enable it after signing the installed boot chain.
- If a firmware update is planned, do it before TPM enrollment. Keep AC power connected.
- For automatic recovery after a power outage, select the firmware's power-on-after-AC-loss option if available. Firmware menu labels vary; do not guess at a similarly named security setting.

Boot the USB's UEFI entry. The live environment normally starts as root in Zsh. Start Bash so the commands below have consistent syntax:

```bash
bash
loadkeys us
cat /sys/firmware/efi/fw_platform_size
ip -br link
ping -c 3 ping.archlinux.org
timedatectl
```

Require `64` for UEFI bitness, a working wired connection, and a synchronized clock. If the clock is not synchronized, enable it with `timedatectl set-ntp true` and check again before installing packages.

Check the actual hardware, not only the seller's listing:

```bash
lscpu
lsblk -d -o PATH,SIZE,MODEL,SERIAL,TRAN
systemd-cryptenroll --tpm2-device=list
```

**Stop if no TPM2 device is listed.** Resolve firmware support before erasing the disk if automatic encrypted boot is a requirement. If the live image lacks TPM support tools, check the firmware first and complete the installed-system TPM check before enrolling any key; absence of the utility itself is not proof of absent hardware.

## 2. Partition, encrypt, and mount the SSD

**Where:** M75q live USB, root Bash. These commands are destructive.

Choose the internal SSD by its model, serial, and size. Do not assume it is `nvme0n1`; do not choose the installation USB.

```bash
read -r -p 'Full device path of the SSD to ERASE: ' DISK
lsblk -o PATH,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS "$DISK"
```

After checking that output and the backup, open a blank partition table in the interactive editor:

```bash
cfdisk --zero "$DISK"
```

Choose **GPT** if asked. Create:

1. A **2 GiB** first partition, type **EFI System**.
2. A second partition using the remaining space, type **Linux filesystem**.

Select **Write**, confirm deliberately, then **Quit**. This is not a dual-boot layout.

Inspect the new partition paths, then enter them explicitly:

```bash
lsblk -o PATH,SIZE,TYPE,FSTYPE "$DISK"
read -r -p 'EFI partition path, for example /dev/nvme0n1p1: ' ESP
read -r -p 'Encrypted-root partition path, for example /dev/nvme0n1p2: ' ROOT
lsblk -o PATH,SIZE,TYPE,FSTYPE "$ESP" "$ROOT"
```

Require two different partitions on the intended SSD. The next block formats both. Choose a strong initial LUKS passphrase and save it securely outside this machine; it remains a recovery route even after TPM enrollment.

```bash
mkfs.fat -F 32 -n M75Q_EFI "$ESP"
cryptsetup luksFormat --type luks2 --label m75q-root "$ROOT"
cryptsetup open "$ROOT" cryptroot
mkfs.ext4 -L m75q-rootfs /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
mount --mkdir -o umask=0077 "$ESP" /mnt/efi
findmnt -R /mnt
```

Expected: `/mnt` is ext4 on `/dev/mapper/cryptroot`; `/mnt/efi` is FAT32 on the EFI partition. **There is no separate `/mnt/boot` mount.**

## 3. Install the host packages

**Where:** still the live USB.

```bash
pacstrap -K /mnt \
  base linux-lts linux-firmware amd-ucode \
  mkinitcpio cryptsetup e2fsprogs dosfstools \
  sudo nano man-db man-pages \
  systemd-ukify sbctl tpm2-tss openssl jq efitools \
  zram-generator openssh git tailscale nix

genfstab -U /mnt > /mnt/etc/fstab
cat /mnt/etc/fstab
arch-chroot -S /mnt
```

`>` is intentional on this fresh installation: repeating `genfstab` should not append duplicate entries. Check the root and ESP entries, including restrictive ESP permissions. `arch-chroot -S` lets `bootctl` create the firmware boot entry; use a current installation ISO that supports it.

The remaining commands through the first reboot run **inside the chroot as root**, unless stated otherwise. Do not use `--now` when enabling services inside the chroot.

## 4. Configure identity and the administrator account

```bash
ln -sf /usr/share/zoneinfo/America/Montreal /etc/localtime
hwclock --systohc
nano /etc/locale.gen
```

Uncomment `en_US.UTF-8 UTF-8`, save, then:

```bash
locale-gen
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf
printf 'KEYMAP=us\n' > /etc/vconsole.conf
printf 'm75q-dev\n' > /etc/hostname

passwd
useradd --create-home --groups wheel --shell /bin/bash ian
passwd ian
EDITOR=nano visudo -f /etc/sudoers.d/10-wheel
```

Put this single line in the sudoers file:

```sudoers
%wheel ALL=(ALL:ALL) ALL
```

Then validate it:

```bash
chmod 0440 /etc/sudoers.d/10-wheel
visudo -c
```

Do not disable sudo password checks. Keep Bash as the login shell: recovery and SSH login must not depend on a Nix profile generation. Do not run the desktop `install.sh` or its `chsh` instructions on this host.

## 5. Configure networking, time, and headless operation

Create `/etc/systemd/network/20-wired.network`:

```ini
[Match]
Type=ether
Kind=!*

[Network]
DHCP=yes
```

This matches physical Ethernet, not Tailscale, bridges, or virtual Ethernet interfaces. The LAN router supplies the address, gateway, and DNS. Do not enable NetworkManager or a second DHCP client alongside it.

Create `/etc/systemd/zram-generator.conf`:

```ini
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
```

This is compressed RAM swap, not an extra 8 GiB of physical memory. No zram service needs enabling; the generator handles it. We disable zswap in the signed kernel command line below to avoid double compression.

```bash
systemctl enable systemd-networkd.service systemd-resolved.service
systemctl enable systemd-timesyncd.service tailscaled.service nix-daemon.service
systemctl enable fstrim.timer
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
```

Do not enable `sshd.service`. The `openssh` package provides the client/SFTP tools; Tailscale SSH will provide remote login after enrollment.

The installer/chroot may bind-mount `/etc/resolv.conf`. We replace it with the systemd-resolved stub symlink **after exiting the chroot**, immediately before reboot, rather than breaking package downloads mid-install.

## 6. Configure encrypted-root UKIs

**Where:** chroot, root. Variables from the live shell may not have survived the chroot. Identify and re-enter the LUKS partition:

```bash
lsblk -s -o PATH,SIZE,TYPE,FSTYPE /dev/mapper/cryptroot
read -r -p 'Full LUKS partition path: ' ROOT
LUKS_UUID=$(cryptsetup luksUUID "$ROOT")
printf 'LUKS UUID: %s\n' "$LUKS_UUID"
```

Require a nonempty UUID for the encrypted partition, not the ext4 filesystem's UUID.

In `/etc/mkinitcpio.conf`, replace the existing `HOOKS=(...)` line with:

```bash
HOOKS=(base systemd keyboard autodetect microcode modconf sd-vconsole block sd-encrypt filesystems fsck)
```

Keep `MODULES`, `BINARIES`, and `FILES` at their defaults. `keyboard` precedes `autodetect` so a recovery keyboard still works after an image is rebuilt headlessly. `microcode` includes AMD microcode. No LVM or desktop early-KMS hook is needed for this layout.

Create the embedded command line:

```bash
install -d /etc/kernel
printf 'rd.luks.name=%s=cryptroot rd.luks.options=%s=tpm2-device=auto,tpm2-measure-pcr=yes,discard root=/dev/mapper/cryptroot rw zswap.enabled=0\n' \
  "$LUKS_UUID" "$LUKS_UUID" > /etc/kernel/cmdline
cat /etc/kernel/cmdline
```

- `tpm2-device=auto` will try the enrolled TPM key once one exists, otherwise prompt for a passphrase.
- `tpm2-measure-pcr=yes` changes PCR15 after unlocking the root volume. This is required by the TPM policy in stage 9.
- `discard` permits SSD TRIM through LUKS. It exposes allocation patterns, not file contents. This guide accepts that tradeoff for a development SSD.
- The UKI embeds this command line. With Secure Boot active, arbitrary boot-menu overrides are ignored.
- Do not add a second root-unlock configuration in `/etc/crypttab` or `/etc/crypttab.initramfs`.

Replace `/etc/mkinitcpio.d/linux-lts.preset` with:

```bash
ALL_kver="/boot/vmlinuz-linux-lts"
PRESETS=('default' 'fallback')
default_uki="/efi/EFI/Linux/arch-linux-lts.efi"
fallback_uki="/efi/EFI/Linux/arch-linux-lts-fallback.efi"
fallback_options="-S autodetect"
```

The fallback includes a broader driver set. It is the **same kernel version**, not an old-kernel rollback image.

## 7. Create signing keys and install the signed boot chain

**Where:** chroot, root. Generate these keys once, not on each upgrade:

```bash
sbctl create-keys
install -d -m 0700 /etc/kernel/keys
umask 077
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
  -out /etc/kernel/keys/pcr-private.pem
openssl pkey -in /etc/kernel/keys/pcr-private.pem -pubout \
  -out /etc/kernel/keys/pcr-public.pem
```

There are two separate purposes:

- **sbctl's keys** authorize boot images under Secure Boot.
- **The PCR key pair** signs the expected PCR11 measurement for each rebuilt UKI. The TPM trusts that public key rather than one immutable kernel version.

Create `/etc/kernel/uki.conf`:

```ini
[UKI]
PCRBanks=sha256
PCRPKey=/etc/kernel/keys/pcr-public.pem

[PCRSignature:root]
Phases=enter-initrd
PCRPrivateKey=/etc/kernel/keys/pcr-private.pem
PCRPublicKey=/etc/kernel/keys/pcr-public.pem
```

Keep signing ownership simple: **ukify generates the TPM policy signatures; sbctl's packaged mkinitcpio post-hook signs the UKI for Secure Boot.** Do not add a second Secure Boot signing configuration to `uki.conf`. Do not remove `systemd-ukify`: mkinitcpio's internal UKI builder does not provide this PCR-signing setup.

Private keys stay on encrypted root, readable only by root. Never add them to mkinitcpio `FILES`, put them on the ESP, or copy them into Git/Nix. Public keys and signatures are deliberately embedded in the UKI.

Build both UKIs and sign the bootloader source before installing it:

```bash
mkdir -p /efi/EFI/Linux
mkinitcpio -P
sbctl sign --save \
  --output /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed \
  /usr/lib/systemd/boot/efi/systemd-bootx64.efi
bootctl --esp-path=/efi install
```

The saved bootloader signing registration lets sbctl's pacman hook re-sign future versions. [`bootctl` explicitly prefers the `.efi.signed` source](https://www.freedesktop.org/software/systemd/man/latest/bootctl.html#Signed%20.efi%20files). Do not register or sign a separate raw `/boot/vmlinuz-linux-lts` as a boot entry.

Create `/efi/loader/loader.conf`:

```ini
default arch-linux-lts.efi
timeout 3
editor no
```

UKIs under `/efi/EFI/Linux/` are discovered automatically; no `loader/entries/*.conf` file is needed.

```bash
ukify inspect /efi/EFI/Linux/arch-linux-lts.efi
sbctl verify
bootctl --esp-path=/efi list
```

Require:

- `mkinitcpio -P` completed successfully, including the sbctl post-hooks.
- UKI sections include `.linux`, `.initrd`, `.cmdline`, `.pcrpkey`, and `.pcrsig`.
- Both UKIs and the bootloader copies on the ESP are signed.
- The default and fallback entries are listed.

Missing-firmware warnings for unrelated fallback drivers are not necessarily fatal. A missing M75q storage/TPM driver, failed build, or failed signing operation **is a stop condition**. Do not enable Secure Boot until the checks pass.

## 8. First boot, recovery material, and Secure Boot

**Exit the chroot back to the live USB:**

```bash
exit
ln -sf /run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
readlink /mnt/etc/resolv.conf
umount -R /mnt
cryptsetup close cryptroot
reboot
```

Remove the USB. Boot the installed system, enter the initial LUKS passphrase, then log in as `ian`. **This first manual unlock is intentional; automatic unlock is not enrolled yet.**

**Where:** installed M75q, Bash as `ian`.

```bash
sudo -v
findmnt /
findmnt /efi
networkctl status
resolvectl query archlinux.org
timedatectl
swapon --show
systemctl --failed
sudo systemd-analyze has-tpm2
sudo systemd-cryptenroll --tpm2-device=list
```

Resolve failed networking, TPM detection, or boot errors before proceeding.

### Save and test recovery material

```bash
lsblk -s -o PATH,SIZE,TYPE,FSTYPE /dev/mapper/cryptroot
read -r -p 'Full LUKS partition path: ' ROOT
sudo systemd-cryptenroll --recovery-key "$ROOT"
sudo systemd-cryptenroll "$ROOT"
```

Store the generated recovery key in a password manager or encrypted backup accessible from another machine. Do not put it in this repository or keep the only copy on the M75q.

From the displayed slot table, identify the `recovery` slot, then test that key without opening another mapping:

```bash
read -r -p 'Number of the recovery keyslot: ' RECOVERY_SLOT
sudo cryptsetup open --test-passphrase --key-slot "$RECOVERY_SLOT" "$ROOT"
```

Enter the **recovery key**, not the initial passphrase. Require success. Retain the original passphrase slot too.

Back up the current firmware certificates before changing them:

```bash
sudo install -d -m 0700 /root/firmware-key-backup
for var in PK KEK db dbx; do
  sudo efi-readvar -v "$var" -o "/root/firmware-key-backup/$var.esl"
done
```

A variable may already be absent; note that explicitly. Back up `/root/firmware-key-backup`, `/var/lib/sbctl`, and `/etc/kernel/keys` to your encrypted backup storage. The last two contain **private signing keys**. Confirm the firmware has a way to restore factory Secure Boot keys before modifying it.

### Enroll Secure Boot owner keys

1. Enter the firmware settings using the local keyboard: shut down with `sudo systemctl poweroff`, power on, and repeatedly press **F1** at the Lenovo logo (**Fn+F1** if your keyboard requires it). If a Startup Interrupt Menu appears, select its BIOS/setup option. `sudo systemctl reboot --firmware-setup` is an optional shortcut, not a prerequisite: if it reboots normally or reports that booting into firmware is unsupported, use the keyboard procedure instead.
2. In firmware, enter **Secure Boot Setup Mode**, normally by deleting the Platform Key (PK) or using an explicit reset-to-Setup-Mode action. Merely disabling Secure Boot is not the same thing. Menu labels are firmware-specific.
3. **Do not clear the TPM.** Do not select arbitrary key-reset actions if their effect is unclear.
4. Boot the installed Arch system again, manually unlock it, and check:

```bash
sudo sbctl status
```

Require **Setup Mode enabled** before enrollment:

```bash
sudo sbctl enroll-keys -m -f
```

This enrolls your keys while including Microsoft's and the firmware's built-in certificates, needed by some firmware/option ROMs. If sbctl reports missing firmware certificates, an option-ROM risk, or an enrollment error, **stop**. Do not use a force/\"might brick my machine\" bypass. Resolve the M75q's firmware-specific issue while local recovery is available.

Return to firmware if necessary, enable Secure Boot, and boot the installed system once more using the passphrase:

```bash
sudo sbctl status
sudo sbctl verify
sudo bootctl status
```

Require **Secure Boot enabled, Setup Mode disabled / user mode**, and booting through the signed `arch-linux-lts.efi`. Only then enroll the TPM.

## 9. Enable TPM automatic unlock

**Where:** the installed system booted normally through its signed UKI with Secure Boot active, not an ISO/chroot.

Re-enter `ROOT` after the reboots:

```bash
lsblk -s -o PATH,SIZE,TYPE,FSTYPE /dev/mapper/cryptroot
read -r -p 'Full LUKS partition path: ' ROOT
sudo systemd-analyze pcrs
```

Require the SHA256 PCR bank. Enroll:

```bash
sudo systemd-cryptenroll \
  --wipe-slot=tpm2 \
  --tpm2-device=auto \
  --tpm2-with-pin=no \
  --tpm2-pcrs=7:sha256+15:sha256=0000000000000000000000000000000000000000000000000000000000000000 \
  --tpm2-public-key=/etc/kernel/keys/pcr-public.pem \
  --tpm2-public-key-pcrs=11 \
  "$ROOT"

sudo systemd-cryptenroll "$ROOT"
sudo cryptsetup luksDump "$ROOT"
```

The slot table must still contain the password/recovery slots plus a TPM2 slot. Its signed-policy PCR selection must be `11`.

Why these settings:

- **PCR7** binds to the Secure Boot policy in this installed boot environment.
- **Signed PCR11** admits the UKIs signed by our PCR key, including newly rebuilt kernels.
- **PCR15 initially zero** permits unlocking before root activation. The root-key measurement then changes PCR15, closing later re-use in the same boot.
- `Phases=enter-initrd` limits our PCR signatures to the early-boot unlock phase.
- No PIN means an ordinary reboot requires no human input.

Do not add a fixed PCR11 value to `--tpm2-pcrs`. No `--tpm2-signature` argument is needed here: enrollment targets the early-boot policy, not the running system's post-boot state.

**Enrollment success is not an unlock test.** In the tested systemd 261.3 implementation, the explicit PCR15 value makes enrollment skip its immediate unseal check, even if a signature file is supplied. Keep the recovery slots and verify the real boot below.

```bash
sudo reboot
```

**Do not type a disk password.** Require the machine to reach its login prompt by itself. If it prompts, unlock with the recovery key, inspect the cryptsetup journal, and fix the cause before declaring the machine headless-ready.

After successful automatic boot:

```bash
sudo journalctl -b -u systemd-cryptsetup@cryptroot.service
sudo systemd-analyze pcrs
```

Check that root unlocked and PCR15 is nonzero. A second TPM-unlock attempt from the already-running OS is not a useful success test: this policy intentionally prevents that.

Back up the final LUKS header:

```bash
read -r -p 'Full LUKS partition path: ' ROOT
sudo cryptsetup luksHeaderBackup "$ROOT" --header-backup-file /root/m75q-luks-header.img
```

Move a copy to encrypted backup storage outside this machine. Header backups are sensitive and do not replace data backups.

## 10. Join Tailscale and prove remote access

**Where:** installed M75q, as `ian`.

```bash
sudo tailscale up
sudo tailscale set --ssh
tailscale status
tailscale ip -4
resolvectl status
```

Open the displayed authentication URL on the existing workstation and join the intended tailnet. No auth key needs to be embedded in files or shell history.

In the [Tailscale admin console](https://login.tailscale.com/admin/machines):

- Confirm this is the intended `m75q-dev` device and account.
- Check that existing network grants allow your workstation to reach this host's port 22, and that the tailnet's **SSH policy** permits your identity to log in as local user `ian`. Do not broaden all members' access or enable root SSH just to pass the test.
- Check-mode SSH may require browser re-authentication. That is user-login authentication, not disk unlocking; it does not stop the machine booting.
- Review **device key expiry**. If work policy permits, disable expiry for this always-on node; otherwise document and schedule re-authentication before expiry. This is separate from any enrollment auth-key expiry. Disabling expiry makes explicit device revocation important.

**On the existing workstation:**

```bash
tailscale ping m75q-dev
tailscale ssh ian@m75q-dev
```

Use the host's Tailscale IP if name resolution is not yet working. Inside the SSH session, check `hostname`, `whoami`, and `sudo -v`. Leave the local console available until a remote reboot also succeeds.

Do not open router ports or enable a public/LAN OpenSSH server.

## 11. Install the Nix development profile

The Nix package/daemon are already installed. Run profile commands as `ian`, **without sudo**.

### Get the configuration onto the host

Use the version of the dotfiles checkout containing this guide and `nix/flake.lock`. A clone of an older published branch is not sufficient.

While these changes remain local/uncommitted, transfer only the reviewed configuration. **On the existing workstation:**

```bash
tar -C ~/dotfiles-worktrees/nix-dev-env \
  -czf /tmp/m75q-dev-env.tar.gz nix README.md M75Q-ARCH-INSTALL.md
scp /tmp/m75q-dev-env.tar.gz ian@m75q-dev:/tmp/
```

**On the M75q:**

```bash
mkdir -p ~/dotfiles
tar -xzf /tmp/m75q-dev-env.tar.gz -C ~/dotfiles
cd ~/dotfiles
```

This file-copy bootstrap carries no Git history. Once the change is published, use a proper checkout containing it at the same path instead. Do not copy the workstation's home directory, secrets, or Bridge Commander state.

### Install and check

```bash
source /etc/profile.d/nix-daemon.sh
test -f nix/flake.lock
nix --extra-experimental-features 'nix-command flakes' profile add path:./nix#dev
export PATH="$HOME/.nix-profile/bin:$PATH"
stow --target="$HOME" nix
sudo loginctl enable-linger "$USER"
systemctl --user daemon-reload
systemctl --user enable --now docker.service

readlink "$HOME/.nix-profile"
nix profile list
node --version
corepack --version
bun --version
python --version
uv --version
omp --version
docker compose version
DOCKER_HOST="unix:///run/user/$(id -u)/docker.sock" docker run --rm hello-world
fish
```

Current Arch Nix creates `~/.nix-profile` pointing to the user's profile during `profile add`; no installer-created link is assumed. That exact flow has been exercised as a fresh unprivileged Arch user. The stowed Fish snippet handles PATH; Arch's Bash login startup handles future Bash logins.

Keep `~/dotfiles` at the same path. Do not run `stow */`, the desktop installer, `corepack enable`, or `chsh` to a Nix store path. Exit Fish to return to Bash.

Authenticate separately with `gh auth login` and omp's `/login`. Use project-pinned package managers, for example `corepack pnpm install --frozen-lockfile` in a Node repository or `uv sync --locked` in a Python repository. The global profile does not replace project lockfiles or install browser/database dependencies.

For profile updates, rollback, and temporary `nix develop` shells, see the [headless Nix README section](README.md#headless-arch-development-host-nix).

## 12. Acceptance checks before removing the console

Do these while physical recovery remains easy:

- [ ] Recovery key is stored off-machine and its specific LUKS slot has been tested.
- [ ] Secure Boot reports enabled/user mode; both UKIs and bootloader are signed.
- [ ] A normal reboot and a cold power-on reach the login prompt without a disk password.
- [ ] Tailscale SSH works from the workstation after each boot.
- [ ] A new remote login finds `node`, `corepack`, `bun`, `uv`, and `omp`.
- [ ] `systemctl --failed` has no unexplained failures; networking, DNS, NTP, and zram work.
- [ ] The fallback UKI can boot and auto-unlock; afterward select the normal entry again.
- [ ] `sudo mkinitcpio -P` rebuilds and signs both images without regenerating the PCR key, and a subsequent reboot still auto-unlocks.
- [ ] Recovery key, signing keys, firmware-key backup, and LUKS-header backup exist outside the M75q in protected storage.
- [ ] Device-key expiry and a console-recovery plan are documented.

The rebuild/reboot check tests the update mechanism, not every future firmware/kernel release. A kernel regression can still require the installation USB. TPM auto-unlock is not a substitute for backups or out-of-band access.

## Maintenance and recovery

### Host updates

Read [Arch news](https://archlinux.org/news/) before a full system update. Schedule the first update while a console is available:

```bash
sudo pacman -Syu
# Only continue if the transaction and all UKI/signing hooks succeeded.
sudo sbctl sign-all
sudo bootctl --esp-path=/efi update
sudo sbctl verify
sudo bootctl list
sudo reboot
```

UKI builds use the existing PCR signing key to authorize new measurements; no routine TPM re-enrollment is needed. `bootctl update` after signing explicitly installs the signed bootloader, rather than depending on the timing of automatic bootloader updates.

Do not enable unattended package upgrades/reboots yet. Firmware updates, Secure Boot certificate changes, TPM resets, or changes to systemd's measured-boot policy can require a recovery unlock and re-enrollment. Major systemd release notes matter here; for example, v261 introduced additional early-boot PCR separator measurements.

### If TPM unlock stops working

1. Use the retained passphrase or recovery key at the local console.
2. Confirm Secure Boot is still enabled and you booted the intended signed UKI.
3. Inspect `sudo journalctl -b -u systemd-cryptsetup@cryptroot.service`, `sudo sbctl status`, and `sudo systemd-analyze pcrs`.
4. If the change was intentional and trusted, repeat **stage 9's enrollment command** from the normally booted installed system. `--wipe-slot=tpm2` replaces TPM slots, not password/recovery slots.
5. Reboot and prove automatic unlock again.

Do not enroll while booted from the ISO, while Secure Boot is disabled, or merely to accept unexplained boot-state changes.

### If the installed system will not boot

Use the Arch USB locally. Temporarily disable Secure Boot to boot the official ISO, then **unlock, do not format**:

```bash
bash
lsblk -o PATH,SIZE,FSTYPE,LABEL
read -r -p 'Existing LUKS root partition: ' ROOT
read -r -p 'Existing EFI partition: ' ESP
cryptsetup open "$ROOT" cryptroot
mount /dev/mapper/cryptroot /mnt
mount --mkdir "$ESP" /mnt/efi
arch-chroot -S /mnt
```

Repair the actual cause. For a corrected initramfs configuration, rebuild with `mkinitcpio -P`, sign with `sbctl sign-all`, and update the bootloader with `bootctl --esp-path=/efi update`. A bad kernel may require reinstalling a known-good cached `linux-lts` package before rebuilding; the fallback UKI is not an older kernel.

Do not regenerate the signing keys or run `luksFormat`. Exit the chroot, unmount, close `cryptroot`, and reboot. Restore Secure Boot before judging or re-enrolling TPM unlock; use the recovery key if necessary.

### Operational boundaries

- Keep development servers bound to loopback unless deliberately exposing them through Tailscale.
- Nix does not capture credentials, project data, or service state. Back those up separately under the appropriate work policy.
- Bridge Commander remains a separate migration. Do not start a second authoritative writer on this host.
- This host uses ordinary Arch host administration, not NixOS. The M720q Proxmox homelab is unchanged.

## Sources and verification scope

Primary references:

- [Arch installation guide](https://wiki.archlinux.org/title/Installation_guide)
- [Arch encrypted-root configuration](https://wiki.archlinux.org/title/Dm-crypt/System_configuration)
- [Arch unified kernel images](https://wiki.archlinux.org/title/Unified_kernel_image)
- [Arch systemd-cryptenroll](https://wiki.archlinux.org/title/Systemd-cryptenroll)
- [Arch Secure Boot](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot)
- [Arch systemd-boot](https://wiki.archlinux.org/title/Systemd-boot)
- [systemd-cryptenroll policy reference](https://www.freedesktop.org/software/systemd/man/latest/systemd-cryptenroll.html)
- [systemd 261.3 enrollment implementation](https://github.com/systemd/systemd/blob/v261.3/src/cryptenroll/cryptenroll-tpm2.c)
- [Arch systemd-networkd](https://wiki.archlinux.org/title/Systemd-networkd) and [zram](https://wiki.archlinux.org/title/Zram)
- [Tailscale SSH](https://tailscale.com/docs/features/tailscale-ssh) and [device key expiry](https://tailscale.com/docs/features/access-control/key-expiry)

This guide is for a manual installation on the M75q. Container/software-TPM checks are not a hardware boot test. Firmware enrollment, the physical TPM, networking on that machine, and the acceptance reboots must be verified locally before unattended use.

Checked in disposable Arch containers: the fresh unprivileged-user Nix bootstrap; default/fallback UKI builds; Secure Boot signature verification for both UKIs and systemd-boot; cryptographic verification of the embedded PCR11 policy signatures; and inclusion of the TPM initramfs dependencies without private signing keys. All 38 Bash blocks passed syntax checks without executing the installation stages.

Additional checks with systemd 261.3:

- `bootctl install` copied the `.efi.signed` source byte-for-byte to both the normal and fallback bootloader paths. Both installed copies passed signature verification. This used a temporary ESP directory with relaxed filesystem checks and firmware-variable writes disabled, not physical firmware.
- The guide's TPM enrollment command succeeded against a throwaway LUKS file and software TPM with a genuine UKI `enter-initrd` signature at `/run/systemd/tpm2-pcr-signature.json`, PCR11 advanced through the later boot phases, and PCR15 nonzero.
- A diagnostic control enabling immediate unseal verification succeeded at the simulated `enter-initrd` phase and rejected the later PCR11 state because no signature authorized it. The guide's explicit PCR15-zero enrollment skips that immediate check; adding `--tpm2-signature` did not change this.

These checks do not claim a physical boot or end-to-end TPM auto-unlock on the M75q.
