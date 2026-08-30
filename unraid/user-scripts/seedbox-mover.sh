#!/bin/bash
# Seedbox Mover — moves everything eligible, then deletes what passes the live gates.
# Requires: python3, seedbox-mover.py (github.com/chodeus/seedbox-mover), Unraid user.scripts plugin
# One process, one lock: --max caps the MOVE pass only; the delete pass always considers
# every tagged torrent, and skips itself entirely if the move was cancelled or aborted.
S=/mnt/cache/appdata/seedbox-mover/seedbox-mover.py

python3 "$S" --run --delete --max 9999
