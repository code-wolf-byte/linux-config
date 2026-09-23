# system-config

Configuration for my CachyOS machine(s) — dotfiles, system files, and package lists
in one repo, loosely modelled on
[benjuntilla/guix-config](https://github.com/benjuntilla/guix-config).

| Path | Goes to | Applied by |
|---|---|---|
| `home/` | `~` | [chezmoi](https://chezmoi.io) (`.chezmoiroot` points here) |
| `system/` | `/` | `scripts/apply-system.sh` (sudo) |
| `hosts/<hostname>/system/` | `/`, only on that host | `scripts/apply-system.sh` |
| `hosts/<hostname>/enable-units.txt` | systemd units to enable on that host | `scripts/apply-system.sh` |
| `packages/pacman.txt`, `packages/aur.txt` | installed packages | `bootstrap.sh` |

## New machine

```sh
git clone https://github.com/code-wolf-byte/linux-config.git ~/Projects/system-config
~/Projects/system-config/bootstrap.sh
```

## Day to day

```sh
chezmoi edit ~/.config/fish/config.fish      # edit a dotfile in the repo
chezmoi re-add                               # or: pull edits made directly in ~ back in
chezmoi diff && chezmoi apply                # repo -> ~
chezmoi add ~/.config/foo                    # start tracking a new dotfile

./scripts/apply-system.sh --dry-run          # what would change in /
./scripts/apply-system.sh                    # system/ + hosts/$(hostname)/system/ -> /
./scripts/save-packages.sh                   # refresh package lists
```

chezmoi naming: `dot_config` → `.config`, `executable_` sets +x, `private_` sets 0600,
`empty_` keeps an empty file, `*.tmpl` files are templates (use `{{ .chezmoi.hostname }}`
for per-machine differences).

## What's tracked

**Dotfiles (`home/`)**
- Shell: fish (`config.fish`, `conf.d/`, `functions/`), `.gitconfig`
- Desktop: Hyprland (Lua config + `scripts/`), COSMIC (shortcuts, panel/dock,
  compositor/input — theme and window rules are still defaults), GTK 3/4, qt5ct/qt6ct,
  autostart entries
- Apps: kitty, alacritty, btop, micro, default apps (`mimeapps.list`)

**System, all machines (`system/`)**
- `logind.conf.d/power-button.conf` — power button does nothing
- `pkgfile-update.service.d/override.conf` + `/usr/local/bin/pkgfile-gen-conf.sh` — pkgfile
  uses a pacman.conf without the `[ogc]` repo (which has no `.files` db)

**System, `flow` only (`hosts/flow/`)** — ASUS ROG Flow Z13
- z13ctl udev rule + `z13ctl-perms.service` (enabled) — sysfs permissions for z13ctl
- asusd (fan curves, keyboard lighting), supergfxd (GPU mode, nvidia modprobe options)
- snapper root config, limine + `sd-btrfs-overlayfs` mkinitcpio hook (bootable snapshots)

Deliberately **not** tracked: SSH host keys, passwd/shadow/group, fstab/crypttab,
mirrorlists, generated files (`/etc/pkgfile.pacman.conf`), app data/caches, and
`fish_variables`.

## Related repos

- [trackball-switch](https://github.com/code-wolf-byte/trackball-switch) — Alt + trackball
  scrolling and connect/disconnect notifications for the Kensington Orbit. `bootstrap.sh`
  clones it to `~/Projects/trackball-helper` (if not already there) and runs its `install.sh`.
