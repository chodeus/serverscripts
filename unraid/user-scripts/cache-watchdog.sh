#!/bin/bash
#arrayStarted=true
#clearLog=true
#description=Safety net: starts the Mover Tuning mover when the cache pool fills between scheduled runs.
#
# Requires: Unraid user.scripts plugin (cron */5 * * * *), ZFS cache pool, ca.mover.tuning plugin
#
# Cache Watchdog - catches abnormal fill bursts between the nightly Mover
# Tuning runs. At/above TRIGGER_PCT it starts the MOVER TUNING plugin mover,
# so all plugin filters apply (>=90% engages its Move-All rule).
# Below the trigger it exits in a few ms.

POOL="cache"
TRIGGER_PCT=90
COOLDOWN_MIN=60
MOVER="/usr/local/emhttp/plugins/ca.mover.tuning/mover"   # plugin mover, NOT /usr/local/sbin/mover
LOCKFILE="/tmp/cache-watchdog.lock"
STAMP="/tmp/cache-watchdog.last-trigger"

exec 9>"$LOCKFILE" || exit 1
flock -n 9 || exit 0    # a previous tick is still mid-move

read -r used avail < <(zfs list -Hp -o used,available "$POOL" 2>/dev/null)
if [ -z "$used" ] || [ -z "$avail" ]; then
    echo "Pool $POOL not available (array stopped?) - nothing to do"
    exit 0
fi
pct=$(( used * 100 / (used + avail) ))

if [ "$pct" -lt "$TRIGGER_PCT" ]; then
    echo "$POOL at ${pct}% (trigger ${TRIGGER_PCT}%) - nothing to do"
    exit 0
fi

if [ -f /var/run/mover.pid ] && ps -p "$(cat /var/run/mover.pid 2>/dev/null)" >/dev/null 2>&1; then
    echo "$POOL at ${pct}% but a mover is already running - skipping"
    exit 0
fi
if pgrep -f "ca.mover.tuning/age_mover" >/dev/null 2>&1; then
    echo "$POOL at ${pct}% but age_mover is already active - skipping"
    exit 0
fi

now=$(date +%s)
last=$(stat -c %Y "$STAMP" 2>/dev/null || echo 0)
if [ $(( now - last )) -lt $(( COOLDOWN_MIN * 60 )) ]; then
    echo "$POOL at ${pct}% but inside the ${COOLDOWN_MIN}-minute cooldown - skipping"
    exit 0
fi

touch "$STAMP"
logger -t cache-watchdog "$POOL at ${pct}% (>= ${TRIGGER_PCT}%) - starting Mover Tuning mover"
/usr/local/emhttp/webGui/scripts/notify -e "Cache Watchdog" -s "Cache at ${pct}% - auto-starting mover" \
    -d "Pool '$POOL' crossed ${TRIGGER_PCT}% between scheduled runs. Mover Tuning mover started (plugin filters apply)." \
    -i warning
"$MOVER" start 2>&1
logger -t cache-watchdog "Mover Tuning run finished ($POOL was ${pct}% at trigger)"
