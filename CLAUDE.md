# system-config

Personal CachyOS (Arch) config repo. See README.md for layout.

- `home/` is the chezmoi source root (via `.chezmoiroot`). Use chezmoi naming
  (`private_`, `empty_`, `executable_`, `dot_`, `.tmpl`). Never edit files in `~` without mirroring them
  here — prefer `chezmoi edit` / `chezmoi re-add`.
- `system/` mirrors `/` on every machine; `hosts/<hostname>/system/` only on that host
  (hardware-specific or containing disk UUIDs). `scripts/apply-system.sh` installs files
  0755 if executable in the repo, else 0644; add reload logic there if a new kind of file
  needs one. Check with `--dry-run` (no sudo).
- Never commit secrets: SSH/host keys, `.env` files, tokens, passwd/shadow. The repo is
  on GitHub.
- Package lists are generated (`scripts/save-packages.sh`); don't hand-edit ordering.
- Anything needing sudo must be run by the user, not assumed to have happened.
