#!/bin/bash
export CHROOT_PATH="/data/chroot"
export ROOTFS_MOUNT_DIR="${CHROOT_PATH}/rootfs_mount"
export ROOTFS_IMAGE="${CHROOT_PATH}/rootfs.img"
export ROOTFS_TEMP="/data/data/com.termux/files/usr/tmp"

ANSI_ESCAPE_RESET="\033[0m"
ANSI_ESCAPE_BLACK="\033[0;30m"
ANSI_ESCAPE_RED="\033[0;31m"
ANSI_ESCAPE_GREEN="\033[0;32m"
ANSI_ESCAPE_YELLOW="\033[0;33m"
ANSI_ESCAPE_BLUE="\033[0;34m"
ANSI_ESCAPE_PURPLE="\033[0;35m"
ANSI_ESCAPE_CYAN="\033[0;36m"
ANSI_ESCAPE_WHITE="\033[0;37m"

log_debug() { 
	echo -e "${ANSI_ESCAPE_BLUE}D: $@${ANSI_ESCAPE_RESET}"
}
log_info() { 
	echo -e "${ANSI_ESCAPE_GREEN}I: $@${ANSI_ESCAPE_RESET}"
}
log_warn() { 
	echo -e "${ANSI_ESCAPE_YELLOW}W: $@${ANSI_ESCAPE_RESET}"
}
log_error() { 
	echo -e "${ANSI_ESCAPE_RED}E: $@${ANSI_ESCAPE_RESET}"
}

print_swap_info() {
	local swap_total=$(awk '/SwapTotal/ {print $2 / 1024}' /proc/meminfo)
	local swap_free=$(awk '/SwapFree/ {print $2 / 1024}' /proc/meminfo)
	log_info "swap total: ${swap_total}MB ; swap free: ${swap_free}MB"
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

is_mounted_dir() {
	# Add a space to avoid matching /foo/bar when checking /foo
	grep -qs "$1 " /proc/mounts
}

echo "DebianAndroidChroot"
echo "---------------------"
echo "CHROOT_PATH=${CHROOT_PATH}"
echo "ROOTFS_MOUNT_DIR=${ROOTFS_MOUNT_DIR}"
echo "ROOTFS_IMAGE=${ROOTFS_IMAGE}"
echo "ROOTFS_TEMP=${ROOTFS_TEMP}"
echo ""

if [ $(id -u) != "0" ]; then
	log_error "This script must be run under root"
	exit 1
fi

if [ ! -e "${ROOTFS_TEMP}" ]; then
	log_warn "Cannot find Termux temp, shared temp is unavailable"
	export ROOTFS_TEMP=""
fi

if ! command_exists "busybox"; then
	log_error "Could not find \"busybox\""
	log_error "Make sure to install it and that it is in your path and try again"
	exit 1
fi