#!/usr/bin/env bash
# Snapshot explicitly installed packages into packages/.
set -euo pipefail
cd "$(dirname "$0")/.."
pacman -Qqen > packages/pacman.txt
pacman -Qqem > packages/aur.txt
git --no-pager diff --stat -- packages/
