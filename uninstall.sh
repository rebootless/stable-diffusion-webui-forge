#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -eq 0 ]]; then
    echo "Please run this script as a regular user, not root."
    exit 1
fi

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if [[ ! -f webui.sh ]]; then
    echo "Error: webui.sh not found. Run this script inside the Forge repository."
    exit 1
fi

echo ""
echo "==> Uninstalling Forge environment"

pkill -f "$PWD/venv/bin/python" 2>/dev/null || true

REMOVED=0

for TARGET in venv repositories tmp config_states config.json ui-config.json cache.json params.txt; do
    if [[ -e "$TARGET" ]]; then
        rm -rf -- "$TARGET"
        echo "Removed: $TARGET"
        REMOVED=$((REMOVED + 1))
    fi
done

echo ""
echo "==> Summary"

if [[ $REMOVED -eq 0 ]]; then
    echo "Nothing to remove."
else
    echo "Forge environment removed. Repository, models and outputs are untouched."
fi
