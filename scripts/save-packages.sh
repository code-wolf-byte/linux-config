#!/usr/bin/env bash
# Snapshot explicitly installed packages into hosts/<hostname>/packages/.
set -euo pipefail
cd "$(dirname "$0")/.."
dir="hosts/$(cat /etc/hostname)/packages"
mkdir -p "$dir"
pacman -Qqen > "$dir/pacman.txt"
pacman -Qqem > "$dir/aur.txt"
git --no-pager diff --stat -- "$dir"
