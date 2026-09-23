# system-config

Personal CachyOS (Arch) config repo. See README.md for layout.

- `home/` is the chezmoi source root (via `.chezmoiroot`). Use chezmoi naming
  (`dot_`, `executable_`, `.tmpl`). Never edit files in `~` without mirroring them
  here — prefer `chezmoi edit` / `chezmoi re-add`.
- `system/` mirrors `/`. Files are installed 0644 by `scripts/apply-system.sh`; add
  reload logic there if a new kind of file needs one.
- Package lists are generated (`scripts/save-packages.sh`); don't hand-edit ordering.
- Anything needing sudo must be run by the user, not assumed to have happened.
