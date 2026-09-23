# system-config

Configuration for my CachyOS machine(s) — dotfiles, system files, and package lists
in one repo, loosely modelled on
[benjuntilla/guix-config](https://github.com/benjuntilla/guix-config).

| Path | Goes to | Applied by |
|---|---|---|
| `home/` | `~` | [chezmoi](https://chezmoi.io) (`.chezmoiroot` points here) |
| `system/` | `/` | `scripts/apply-system.sh` (sudo) |
| `hosts/<hostname>/system/` | `/`, only on that host | `scripts/apply-system.sh` |
| `hosts/<hostname>/packages/{pacman,aur}.txt` | installed packages | `bootstrap.sh` |

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

./scripts/apply-system.sh                    # system/ -> /
./scripts/save-packages.sh                   # refresh this host's package lists
```

Commits run `.githooks/pre-commit`, which blocks likely secrets (tokens, keys, long opaque IDs,
`.env`/key files). Keep secrets in untracked files under `~/.config/` and read them at runtime.

chezmoi naming: `dot_config` → `.config`, `executable_` sets +x, `*.tmpl` files are
templates (use `{{ .chezmoi.hostname }}` for per-machine differences).

## Related repos

- [trackball-switch](https://github.com/code-wolf-byte/trackball-switch) — Alt + trackball
  scrolling and connect/disconnect notifications for the Kensington Orbit. `bootstrap.sh`
  clones it to `~/Projects/trackball-helper` (if not already there) and runs its `install.sh`.
