#!/usr/bin/env bash
# Install everything under system/ (and hosts/<hostname>/system/, if present) into /.
# Only changed files are copied (executables keep 0755, everything else 0644), units in
# hosts/<hostname>/enable-units.txt are enabled, and udev/systemd are reloaded as needed.
#
#   --dry-run   list what would change, without sudo
set -euo pipefail
cd "$(dirname "$0")/.."

dry_run=false
[[ ${1-} == --dry-run ]] && dry_run=true

host="hosts/$(cat /etc/hostname)"
roots=()
[[ -d system ]] && roots+=(system)
[[ -d $host/system ]] && roots+=("$host/system")

changed=()
for root in "${roots[@]+"${roots[@]}"}"; do
  while IFS= read -r -d '' src; do
    dst="/${src#"$root"/}"
    mode=644
    [[ -x $src ]] && mode=755
    if cmp -s "$src" "$dst" 2>/dev/null && [[ $(stat -c %a "$dst") == "$mode" ]]; then
      continue
    fi
    changed+=("$dst")
    if $dry_run; then
      echo "would install $dst"
    else
      sudo install -Dm"$mode" "$src" "$dst"
      echo "installed $dst"
    fi
  done < <(find "$root" -type f -print0)
done

units=()
[[ -f $host/enable-units.txt ]] && mapfile -t units < <(grep -v '^\s*\(#\|$\)' "$host/enable-units.txt")
for unit in "${units[@]+"${units[@]}"}"; do
  systemctl is-enabled -q "$unit" 2>/dev/null && continue
  $dry_run && { echo "would enable $unit"; continue; }
  changed_units=true
done

$dry_run && exit 0

if printf '%s\n' "${changed[@]+"${changed[@]}"}" | grep -q '^/etc/udev/'; then
  sudo udevadm control --reload
  sudo udevadm trigger
fi
if printf '%s\n' "${changed[@]+"${changed[@]}"}" | grep -q '^/etc/systemd/' || [[ -n ${changed_units-} ]]; then
  sudo systemctl daemon-reload
fi
[[ -n ${changed_units-} ]] && sudo systemctl enable "${units[@]}"

# Changes that only take effect after a rebuild/reboot — remind rather than run.
if printf '%s\n' "${changed[@]+"${changed[@]}"}" | grep -q '^/etc/\(mkinitcpio\|default/limine\)'; then
  echo "note: initramfs/bootloader config changed — run 'sudo limine-mkinitcpio' (or mkinitcpio -P)"
fi
if printf '%s\n' "${changed[@]+"${changed[@]}"}" | grep -q '^/etc/modprobe.d/\|^/etc/systemd/logind'; then
  echo "note: modprobe/logind config changed — takes effect after reboot"
fi

[[ ${#changed[@]} -eq 0 && -z ${changed_units-} ]] && echo "system files up to date"
exit 0
