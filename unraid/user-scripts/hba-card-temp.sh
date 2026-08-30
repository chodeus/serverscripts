#!/bin/bash
# Requires: Broadcom storcli64 binary (from broadcom.com support downloads)
# Re-assert exec bit (SMB copies / backups can strip it, breaking the run)
chmod +x /mnt/user/data/scripts/hbacard/storcli64
/mnt/user/data/scripts/hbacard/storcli64 /c0 show temperature
