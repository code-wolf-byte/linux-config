#!/usr/bin/env bash
# Set up a machine from this repo: packages, then system files, then dotfiles.
set -euo pipefail
cd "$(dirname "$0")"
repo=$PWD

sudo pacman -S --needed chezmoi git
sudo pacman -S --needed - < packages/pacman.txt
if [[ -s packages/aur.txt ]]; then
  command -v yay >/dev/null || { echo "install yay first for AUR packages"; exit 1; }
  yay -S --needed - < packages/aur.txt
fi

./scripts/apply-system.sh

chezmoi init --source "$repo"
chezmoi apply -v

# Standalone projects with their own installers.
tb=~/Projects/trackball-helper
[[ -d $tb ]] || git clone https://github.com/code-wolf-byte/trackball-switch.git "$tb"
"$tb/install.sh"
