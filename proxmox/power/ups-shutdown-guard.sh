#!/bin/sh
# upsmon SHUTDOWNCMD wrapper. Re-probes the UPS before powering off, to survive a
# stale CAL/OB flag + transient comms loss (Debian #1138630, fixed upstream in NUT 2.8.2).
# Fails CLOSED: shuts down unless the UPS positively reports mains power.
# Requires: NUT client (upsc), systemd; referenced as SHUTDOWNCMD in /etc/nut/upsmon.conf
UPS="myups@192.168.1.5"   # <ups-name>@<nut-server>
WINDOW=60
STEP=5
TAG=ups-shutdown-guard

elapsed=0
while [ "$elapsed" -lt "$WINDOW" ]; do
    st=$(timeout 5 upsc "$UPS" ups.status 2>/dev/null)
    if [ -n "$st" ]; then
        case " $st " in
            *" OB "*|*" LB "*)
                logger -t "$TAG" "UPS reports '$st' - genuine power event, shutting down"
                exec /sbin/shutdown -h +0
                ;;
            *" OL "*)
                logger -t "$TAG" "UPS reachable and reports '$st' (on mains) after ${elapsed}s - ABORTING shutdown, false FSD"
                systemd-run --quiet --on-active=20 --unit=nut-monitor-guard-restart \
                    /usr/bin/systemctl restart nut-monitor 2>/dev/null \
                    || systemctl --no-block restart nut-monitor
                exit 0
                ;;
        esac
    fi
    sleep "$STEP"
    elapsed=$((elapsed + STEP))
done

logger -t "$TAG" "UPS unreachable for ${WINDOW}s - cannot confirm mains, shutting down"
exec /sbin/shutdown -h +0
