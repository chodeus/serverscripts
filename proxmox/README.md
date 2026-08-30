# Proxmox

| File | What it does | Deploys to | Runs |
|---|---|---|---|
| `backup/pbs-unraid-copy.sh` | Copies the PBS datastore to the NAS as a single tar | `/usr/local/sbin/` | `0 4 * * *` |
| `backup/pve-host-backup.sh` | Tars `/etc`, `/root`, `/usr/local/sbin` to the NAS, keeps 14 | `/usr/local/sbin/` | `30 3 * * *` |
| `backup/unraid-flash-pull.sh` | Pulls the newest Unraid boot-config zip to local storage, keeps 3 | `/usr/local/sbin/` | `30 0 * * 1` |
| `backup/cron.d/*` | Cron entries for the three backup scripts | `/etc/cron.d/` | — |
| `power/ups-shutdown-guard.sh` | Re-probes the UPS before powering off; aborts if mains is back | `/usr/local/sbin/` | upsmon `SHUTDOWNCMD` |
| `power/pve-power-mqtt` | Publishes CPU power, temp and energy to MQTT for Home Assistant | `/usr/local/bin/` | Service, every 30s |
| `power/pve-power-mqtt.service` | Unit for the publisher | `/etc/systemd/system/` | — |
| `power/pve-power-mqtt.env.example` | Broker host, user, password | `/etc/pve-power-mqtt.env` (0600) | — |
| `power/host-tweaks.service` | Sets CPU governor to powersave, re-arms NIC Wake-on-LAN | `/etc/systemd/system/` | Boot |
| `ansible/update.yml` | Updates host and both LXCs, updates Uptime Kuma, posts a Discord digest, pings two Kuma monitors | `/root/ansible/` | 23:00 daily |
| `ansible/inventory.yml` | Host plus both containers, via `proxmox_pct_remote` | `/root/ansible/` | — |
| `ansible/ansible.cfg` | Inventory path and log destination | `/root/ansible/` | — |
| `ansible/group_vars/all.yml.example` | Kuma push URLs and Discord webhook | `/root/ansible/group_vars/all.yml` (0600) | — |
| `ansible/ansible-update.service` | Unit that runs the playbook | `/etc/systemd/system/` | — |
| `ansible/ansible-update.timer` | 23:00 daily, clear of the backup window | `/etc/systemd/system/` | — |

Notes:

- The three backup scripts fail closed if the NAS CIFS mount is absent.
- `pve-host-backup.sh` produces a tarball containing cluster tokens, `/etc/shadow`
  and the CIFS credential — keep it on a private share.
- Set the `UPS` variable in `ups-shutdown-guard.sh`, and replace `pvehost` in
  `pve-power-mqtt` (it forms the MQTT topic and HA entity IDs).
