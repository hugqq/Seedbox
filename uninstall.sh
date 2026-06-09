#!/usr/bin/env bash

set -o pipefail

SEEDBOX_INSTALLATION_URL="https://raw.githubusercontent.com/hugqq/Seedbox/refs/heads/main/components/seedbox_install.sh"

assume_yes=""

show_help() {
	echo "Usage: sudo ./uninstall.sh [-y]"
	echo ""
	echo "Options:"
	echo "  -y             Assume yes for uninstall confirmation"
	echo "  -h             Show this help message"
}

while getopts "yh" opt; do
	case "$opt" in
		y )
			assume_yes=1
			;;
		h )
			show_help
			exit 0
			;;
		\? )
			show_help
			exit 1
			;;
	esac
done

if [ "$(id -u)" -ne 0 ]; then
	echo "This script needs root permission to run" >&2
	exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
	echo "curl is required to load online components" >&2
	exit 1
fi

if ! source <(curl -fsSL "$SEEDBOX_INSTALLATION_URL"); then
	echo "Component ~Seedbox Components~ failed to load" >&2
	echo "URL: $SEEDBOX_INSTALLATION_URL" >&2
	exit 1
fi

if ! declare -F uninstall_seedbox_ >/dev/null 2>&1; then
	echo "Online component does not provide uninstall_seedbox_ yet" >&2
	echo "Please submit the updated components/seedbox_install.sh first" >&2
	exit 1
fi

uninstall_seedbox_ "" "$assume_yes"
