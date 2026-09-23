#!/usr/bin/env bash
# Set up a machine from this repo: packages, then system files, then dotfiles.
set -euo pipefail
cd "$(dirname "$0")"
repo=$PWD

sudo pacman -S --needed chezmoi git
pkgs="hosts/$(cat /etc/hostname)/packages"
[[ -d $pkgs ]] || { echo "no $pkgs; copy another host's list there first"; exit 1; }
sudo pacman -S --needed - < "$pkgs/pacman.txt"
if [[ -s "$pkgs/aur.txt" ]]; then
  command -v yay >/dev/null || { echo "install yay first for AUR packages"; exit 1; }
  yay -S --needed - < "$pkgs/aur.txt"
fi

./scripts/apply-system.sh

git config core.hooksPath .githooks   # secret-scan pre-commit hook
chezmoi init --source "$repo"
chezmoi apply -v

# Standalone projects with their own installers.
tb=~/Projects/trackball-helper
[[ -d $tb ]] || git clone https://github.com/code-wolf-byte/trackball-switch.git "$tb"
"$tb/install.sh"
