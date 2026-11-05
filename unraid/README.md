# Unraid

| File | What it does | Deploys to | Runs |
|---|---|---|---|
| `user-scripts/cache-watchdog.sh` | Starts the Mover Tuning mover when the cache pool crosses 90% | `/boot/config/plugins/user.scripts/scripts/cache-watchdog/script` | `*/5 * * * *` |
| `user-scripts/mousehole-qbit-watchdog.sh` | Restarts Mousehole when qBittorrent restarts | `…/user.scripts/scripts/mousehole_qbit_watchdog/script` | At array start |
| `user-scripts/seedbox-mover.sh` | One combined move-then-delete pass of [seedbox-mover](https://github.com/chodeus/seedbox-mover) | `…/user.scripts/scripts/seedbox-mover/script` | Manual |
| `user-scripts/hba-card-temp.sh` | Prints the HBA controller temperature | `…/user.scripts/scripts/HBA Card Temp/script` | Manual |
| `qbt-mover/mover-tuning-start.sh` | Pauses torrents so the mover can relocate their files | `/mnt/user/appdata/qbt-mover/` | ca.mover.tuning before-script |
| `qbt-mover/mover-tuning-end.sh` | Resumes torrents, then runs the duplicate finder | `/mnt/user/appdata/qbt-mover/` | ca.mover.tuning after-script |
| `qbt-mover/fclones.sh` | The duplicate finder: replaces duplicate copies with hardlinks | `/mnt/user/appdata/qbt-mover/` | Run by `mover-tuning-end.sh` |
| `qbt-mover/mover-tuning.cfg.example` | Config all three mover scripts source | `/mnt/user/appdata/qbt-mover/mover-tuning.cfg` | — |

## qbt-mover

By **BZ**, published via
[TRaSH-Guides](https://github.com/TRaSH-Guides/Guides) (`includes/downloaders/`),
for the **ca.mover.tuning** plugin by **masterwishx**. `fclones.sh` is from
[BZ's gist](https://gist.github.com/BaukeZwart/b570ce6b6165c4f0b64c5b98d9d3af1e).

Local changes:

- The resume step completes even if the browser disconnects mid-run.
- The qBittorrent library upgrades when a newer version is available.
- A failed qBittorrent instance no longer ends the run early.
- Each qBittorrent instance writes to its own log file.
- The Docker container list is an empty list, not a list with one blank entry.
- The duplicate finder runs after the resume and cannot stop it.
- The end script no longer checks for the cache pool, which it does not use.
- qBittorrent can authenticate with a WebUI API key instead of a username and password.
- Every torrent older than three days with files on the cache is paused, not only those up to ten days old.
- The duplicate finder also checks `.m4v`, `.mov` and `.m2ts` files.
- `fclones.sh` checks the latest published version for updates.
- `fclones.sh` checks every hardlink after linking and lists files that were not linked as errors.
- `fclones.sh` keeps the fclones cache in `CACHE_PATH`.
- `fclones.sh` shows space saved to two decimal places (1.05GB).
- `fclones.sh` keeps report paths that contain fclones log words.

Version numbers left unchanged from upstream script at point in time.
