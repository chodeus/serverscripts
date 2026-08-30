#!/bin/bash
# Mousehole/qbittorrent network watchdog
# Requires: docker, Unraid user.scripts plugin (schedule: At Startup of Array)
#
# Mousehole runs with --net=container:qbittorrent. When qbittorrent
# restarts, its network namespace is rebuilt and Mousehole is left
# attached to the dead one, so it must be restarted to rejoin.
#
# If qbittorrent is RECREATED (Apply/Update in the Docker tab) the
# container ID changes and Mousehole's pinned reference is stale --
# a restart cannot fix that, so we send a notification instead.

docker events --filter 'container=qbittorrent' --filter 'event=start' --format '{{.Actor.ID}}' | while read -r qbid; do
    sleep 10   # let qbittorrent's VPN come up before bouncing Mousehole

    netmode=$(docker inspect -f '{{.HostConfig.NetworkMode}}' Mousehole 2>/dev/null)

    if [ "$netmode" = "container:$qbid" ]; then
        echo "$(date) qbittorrent restarted - restarting Mousehole"
        docker restart Mousehole
    else
        # qbittorrent was recreated. The Unraid Docker page usually rebuilds
        # network-children itself moments later (rebuildAll), so give it a
        # minute and only notify if Mousehole is still pinned to the dead ID.
        echo "$(date) qbittorrent was recreated - waiting 60s to see if Unraid rebuilds Mousehole"
        sleep 60
        netmode=$(docker inspect -f '{{.HostConfig.NetworkMode}}' Mousehole 2>/dev/null)
        qbid_now=$(docker inspect -f '{{.Id}}' qbittorrent 2>/dev/null)
        if [ -n "$qbid_now" ] && [ "$netmode" = "container:$qbid_now" ]; then
            echo "$(date) Mousehole was rebuilt automatically - no action needed"
        else
            echo "$(date) Mousehole still stale - notifying"
            /usr/local/emhttp/webGui/scripts/notify \
                -s "Mousehole" \
                -d "qbittorrent was recreated. Re-apply Mousehole from the Docker tab to rejoin its network." \
                -i warning
        fi
    fi
done
