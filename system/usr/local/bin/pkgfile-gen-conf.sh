#!/bin/sh
# Regenerate a pacman.conf copy for pkgfile that omits repos with no .files db.
set -e
awk '
/^\[/{ if ($0=="[ogc]") { skip=1 } else { skip=0 } }
!skip
' /etc/pacman.conf > /etc/pkgfile.pacman.conf.tmp
mv /etc/pkgfile.pacman.conf.tmp /etc/pkgfile.pacman.conf
