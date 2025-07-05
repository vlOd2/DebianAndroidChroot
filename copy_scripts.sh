#!/bin/bash
set -e
source ./common.sh

ADB_EXE="${ADB_EXE:-adb}"
SCRIPTS_PATH="android"
CHROOT_PATH="/data/chroot"

echo "ADB_EXE: ${ADB_EXE}"
echo "CHROOT_PATH: ${CHROOT_PATH}"

print_wsl2_warn() {
	log_warn "If you are using WSL2, you need to set the ADB_EXE env variable"
	log_warn "to the full path of the Windows version of adb (example: /mnt/c/android_platform_tools/adb.exe)"
}

log_info "Checking devices (make sure to only have one device plugged in)"
if ! command -v "${ADB_EXE}" >/dev/null 2>&1; then
	log_error "Cannot find adb"
	print_wsl2_warn
	exit
fi

if ! $ADB_EXE get-state >/dev/null 2>&1; then
	log_error "No adb devices are available"
	print_wsl2_warn
	exit 1
fi

log_info "Restarting adb as root"
if ! $ADB_EXE root >/dev/null 2>&1; then
	log_error "Failed to restart adb as root"
	exit 1
fi

log_info "Validating environment"
if ! $ADB_EXE shell busybox >/dev/null 2>&1; then
	log_error "Could not find or execute busybox"
	log_error "Make sure it is installed and is available in the adb shell path"
	exit 1
fi

if ! $ADB_EXE shell busybox stat "${CHROOT_PATH}" >/dev/null 2>&1; then
	log_error "Could not find ${CHROOT_PATH}"
	log_error "Create the directory, copy out/rootfs.img and try again"
	exit 1
fi

push_file() {
	log_info "Pushing \"$1\" to \"$2\""

	# Need to disable errexit temporarily
	# The command substitution would trigger errexit on a non 0 exit code
	# Also the local is assigned separately because it would eat the exit code
	set +e
	local result
	result=$($ADB_EXE push "$1" "$2" 2>&1)
	local status="$?"
	set -e
	
	if [ "${status}" != "0" ]; then
		log_error "Failed to push \"$1\": ${result}"
		exit 1
	fi
}

push_file "${SCRIPTS_PATH}/common.sh" "${CHROOT_PATH}/"
push_file "${SCRIPTS_PATH}/mount.sh" "${CHROOT_PATH}/"
push_file "${SCRIPTS_PATH}/login.sh" "${CHROOT_PATH}/"
push_file "${SCRIPTS_PATH}/unmount.sh" "${CHROOT_PATH}/"

log_info "Adjusting permissions"
if ! $ADB_EXE shell busybox chmod +x "${CHROOT_PATH}/*.sh" >/dev/null 2>&1; then
	log_error "Could not adjust permissions"
	exit 1
fi