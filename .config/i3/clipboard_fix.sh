#!/bin/sh
# Restart the VMware user agent (shared clipboard / auto-resize). No-op outside VMware.
command -v vmtoolsd >/dev/null 2>&1 || exit 0
[ "$(systemd-detect-virt 2>/dev/null)" = "vmware" ] || exit 0
pkill -x vmtoolsd 2>/dev/null
exec vmtoolsd -n vmusr
