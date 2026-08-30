# serverscripts

Backup of the scripts I run on my servers — the ones written for, or modified to
suit, these machines.

- [`unraid/`](unraid/) — Unraid NAS
- [`proxmox/`](proxmox/) — Proxmox VE host

Each folder's README lists what every script does, where it deploys, and when it
runs. Dependencies are in a `# Requires:` line at the top of each script.
Anything needing credentials ships as an `.example` — copy it, fill it in, keep
the real file `0600`. Hostnames and addresses are environment-specific; set them
before deploying.
