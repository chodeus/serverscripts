#!/bin/bash
# Off-box copy of the Unraid flash/boot-config backup.
# Unraid Appdata Backup (weekly Sun 23:00) drops a dated boot-config zip into the share
# Proxmox mounts at /mnt/unraid-backup. Pull the newest settled one to local Proxmox storage,
# keep the last 3. Runs Mon 00:30. Fails closed if the share is not mounted.
# Requires: findmnt; CIFS mount at /mnt/unraid-backup; Unraid Appdata Backup plugin writing boot-config zips there
set -uo pipefail
MNT=/mnt/unraid-backup
SRCDIR="$MNT/unraid_appdata_backup"
DST=/var/lib/unraid-flash-backup
KEEP=3
LOG=/var/log/unraid-flash-pull.log
exec >>"$LOG" 2>&1
echo "=== $(date) start ==="
if ! findmnt -n "$MNT" >/dev/null 2>&1; then mount "$MNT" 2>/dev/null || true; fi
if ! findmnt -n "$MNT" >/dev/null 2>&1; then echo "ABORT: $MNT not mounted"; exit 1; fi
mkdir -p "$DST"
latest=$(find "$SRCDIR" -name "*boot-backup*.zip" -mmin +10 -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -1 | cut -d" " -f2-)
if [ -z "$latest" ]; then echo "ABORT: no settled boot-backup zip found under $SRCDIR"; exit 1; fi
base=$(basename "$latest")
if [ -f "$DST/$base" ]; then
  echo "already have $base - nothing to do"
else
  echo "copying $base ($(du -h "$latest" | cut -f1))"
  cp -p "$latest" "$DST/.$base.tmp" && mv -f "$DST/.$base.tmp" "$DST/$base" && echo "copied OK"
fi
ls -1t "$DST"/*boot-backup*.zip 2>/dev/null | tail -n +$((KEEP+1)) | while read -r old; do echo "prune $(basename "$old")"; rm -f "$old"; done
echo "=== $(date) done; local copies: ==="
ls -la "$DST" | grep -E "boot-backup|total"
