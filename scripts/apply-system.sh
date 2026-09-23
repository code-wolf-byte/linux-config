#!/usr/bin/env bash
# Install everything under system/ (and hosts/<hostname>/system/, if present) into /.
# Only changed files are copied; udev/systemd are reloaded when their files change.
set -euo pipefail
cd "$(dirname "$0")/.."

roots=()
[[ -d system ]] && roots+=(system)
host_root="hosts/$(cat /etc/hostname)/system"
[[ -d $host_root ]] && roots+=("$host_root")

changed=()
for root in "${roots[@]+"${roots[@]}"}"; do
  while IFS= read -r -d '' src; do
    dst="/${src#"$root"/}"
    if ! sudo cmp -s "$src" "$dst" 2>/dev/null; then
      sudo install -Dm644 "$src" "$dst"
      changed+=("$dst")
      echo "installed $dst"
    fi
  done < <(find "$root" -type f -print0)
done

[[ ${#changed[@]} -eq 0 ]] && { echo "system files up to date"; exit 0; }

if printf '%s\n' "${changed[@]}" | grep -q '^/etc/udev/'; then
  sudo udevadm control --reload
  sudo udevadm trigger
fi
if printf '%s\n' "${changed[@]}" | grep -q '^/etc/systemd/'; then
  sudo systemctl daemon-reload
fi
