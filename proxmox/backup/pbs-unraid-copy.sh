#!/bin/bash
# Cold off-host copy of the local PBS datastore to the Unraid share, as a single tar.
# Mount is self-managed via /etc/fstab (//NAS-HOST/share_backup -> /mnt/unraid-backup),
# independent of PVE storage. Fails closed if the share can not be mounted.
# Restore: tar -C <newpath> -xf pbs-store1.tar ; then add it back as a PBS datastore.
# Requires: tar, findmnt, flock; a CIFS mount of the NAS backup share at /mnt/unraid-backup (via /etc/fstab)
set -uo pipefail
SRC=/mnt/pbs-store
MNT=/mnt/unraid-backup
DSTDIR="$MNT/pbs-store-copy"
LOG=/var/log/pbs-unraid-copy.log
exec >>"$LOG" 2>&1
echo "=== $(date) start ==="
# Plain findmnt also matches the autofs placeholder, so require a real CIFS mount.
# Touching the path first lets the automount fire.
ls "$MNT" >/dev/null 2>&1 || true
if ! findmnt -n -t cifs "$MNT" >/dev/null 2>&1; then
  mount "$MNT" 2>/dev/null || true
fi
if ! findmnt -n -t cifs "$MNT" >/dev/null 2>&1; then
  echo "ABORT: no CIFS mount at $MNT"; exit 1
fi
mkdir -p "$DSTDIR"
TMP="$DSTDIR/pbs-store1.tar.tmp"
CUR="$DSTDIR/pbs-store1.tar"
PREV="$DSTDIR/pbs-store1.tar.prev"
if flock -n /run/pbs-unraid-copy.lock tar -C "$SRC" -cf "$TMP" . ; then
  [ -f "$CUR" ] && mv -f "$CUR" "$PREV"
  mv -f "$TMP" "$CUR"
  echo "size: $(du -h "$CUR" | cut -f1)"
  echo "=== $(date) done OK ==="
else
  rc=$?; echo "tar FAILED rc=$rc"; rm -f "$TMP"; exit $rc
fi
