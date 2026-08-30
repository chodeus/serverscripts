#!/bin/bash
# Off-box backup of the Proxmox HOST config (PBS backs up GUESTS, not the host itself).
# Tars the key host paths to the Unraid share (self-managed mount), keeps last 14.
# Fails closed if the Unraid mount is absent.
# NOTE: contains secrets (/etc/pve/priv tokens, /etc/shadow, the CIFS credential) ->
#       it lives on the private Unraid share; treat the tarball as sensitive.
# Requires: tar, findmnt; a CIFS mount of the NAS backup share at /mnt/unraid-backup (via /etc/fstab)
set -uo pipefail
MNT=/mnt/unraid-backup
DST="$MNT/pve-host-config"
KEEP=14
LOG=/var/log/pve-host-backup.log
HOST=$(hostname)
STAMP=$(date +%Y_%m_%dT%H_%M)
OUT="$DST/${HOST}-hostconfig-${STAMP}.tar.gz"
TMP="$DST/.${HOST}-hostconfig-${STAMP}.tar.gz.tmp"
exec >>"$LOG" 2>&1
echo "=== $(date) start ==="
if ! findmnt -n "$MNT" >/dev/null 2>&1; then mount "$MNT" 2>/dev/null || true; fi
if ! findmnt -n "$MNT" >/dev/null 2>&1; then echo "ABORT: $MNT not mounted"; exit 1; fi
mkdir -p "$DST"
# /etc covers /etc/pve (fuse), network, fstab, cron.d, apt, systemd units, passwd/shadow.
# Plus root's home and our custom scripts under /usr/local/sbin.
tar -czf "$TMP" --absolute-names --warning=no-file-changed --ignore-failed-read \
    /etc /root /usr/local/sbin
rc=$?
if [ -s "$TMP" ] && [ "$rc" -le 1 ]; then
  mv -f "$TMP" "$OUT"
  echo "wrote $OUT ($(du -h "$OUT" | cut -f1)) rc=$rc"
else
  echo "tar FAILED rc=$rc"; rm -f "$TMP"; exit 1
fi
ls -1t "$DST"/${HOST}-hostconfig-*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | while read -r old; do
  echo "prune $(basename "$old")"; rm -f "$old"
done
echo "=== $(date) done; copies: ==="
ls -la "$DST"/${HOST}-hostconfig-*.tar.gz 2>/dev/null | tail -5
