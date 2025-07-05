#!/bin/bash
set -eE
source ./common.sh

# Check if rootfs already mounted
if is_mounted_dir "${ROOTFS_MOUNT_DIR}"; then
	log_error "The rootfs has already been mounted"
	exit 1
fi

err_handler() {
	set +e
    echo "ERR_HANDLER: Error on line $1"
	echo "ERR_HANDLER: If this was unexpected, please make an issue report"
	# Silent cleanup
	if [ -n "${ROOTFS_MOUNT_DIR}" ]; then
		echo "ERR_HANDLER: Force un-unmounting mountpoints"
		busybox umount "${ROOTFS_MOUNT_DIR}/dev/shm" >/dev/null 2>&1
		busybox umount "${ROOTFS_MOUNT_DIR}/proc" >/dev/null 2>&1
		busybox umount "${ROOTFS_MOUNT_DIR}/sys" >/dev/null 2>&1
		busybox umount "${ROOTFS_MOUNT_DIR}/dev" >/dev/null 2>&1
		busybox umount "${ROOTFS_MOUNT_DIR}/tmp" >/dev/null 2>&1
		busybox umount "${ROOTFS_MOUNT_DIR}" >/dev/null 2>&1
		busybox umount -l "${ROOTFS_MOUNT_DIR}/dev/shm" >/dev/null 2>&1
		busybox umount -l "${ROOTFS_MOUNT_DIR}/proc" >/dev/null 2>&1
		busybox umount -l "${ROOTFS_MOUNT_DIR}/sys" >/dev/null 2>&1
		busybox umount -l "${ROOTFS_MOUNT_DIR}/dev" >/dev/null 2>&1
		busybox umount -l "${ROOTFS_MOUNT_DIR}/tmp" >/dev/null 2>&1
		busybox umount -l "${ROOTFS_MOUNT_DIR}" >/dev/null 2>&1
	fi
	exit 1
}
trap 'err_handler $LINENO' ERR

mount_dir() {
	# $1 - what
	# $2 - where
	# $3 - type
	# $4 - type options
	if [ -z "$3" ]; then
		log_info "Mounting \"$1\" to \"$2\""
		busybox mount "$1" "$2"
	elif [ "$3" = "bind" ]; then
		log_info "Bind mounting \"$1\" to \"$2\""
		busybox mount --bind "$1" "$2"
	else
		if [ -z "$4" ]; then
			log_info "Mounting \"$2\" as $3"
			busybox mount -t "$3" none "$2"
		else
			log_info "Mounting \"$2\" as $3 ($4)"
			busybox mount -o "$4" -t "$3" none "$2"
		fi
	fi
}

# Rootfs image
mkdir -p "${ROOTFS_MOUNT_DIR}"
mount_dir "${ROOTFS_IMAGE}" "${ROOTFS_MOUNT_DIR}"

# /proc
mkdir -p "${ROOTFS_MOUNT_DIR}/proc"
mount_dir "-" "${ROOTFS_MOUNT_DIR}/proc" "proc"

# /sys
mkdir -p "${ROOTFS_MOUNT_DIR}/sys"
mount_dir "-" "${ROOTFS_MOUNT_DIR}/sys" "sysfs"

# /dev
mkdir -p "${ROOTFS_MOUNT_DIR}/dev"
if ! mount_dir "-" "${ROOTFS_MOUNT_DIR}/dev" "devtmpfs"; then
	log_warn "Failed to mount dev as devtmpfs, falling back to bind mounting"
	mount_dir "/dev" "${ROOTFS_MOUNT_DIR}/dev" "bind"
fi

# Shared memory (/dev/shm, needed by chromium apps)
mkdir -p "${ROOTFS_MOUNT_DIR}/dev/shm"
mount_dir "-" "${ROOTFS_MOUNT_DIR}/dev/shm" "tmpfs" "size=512M"

# Shared temp (needed for X11, pulse, etc)
mkdir -p "${ROOTFS_MOUNT_DIR}/tmp"
log_info "Mounting shared temp"
if [ -n "${ROOTFS_TEMP}" ]; then
	# Shared temp (bind)
	mount_dir "${ROOTFS_TEMP}" "${ROOTFS_MOUNT_DIR}/tmp" "bind"
	busybox find "${ROOTFS_MOUNT_DIR}/tmp" -type f -exec busybox chmod u=rw,g=,o= {} \;
	busybox find "${ROOTFS_MOUNT_DIR}/tmp" -type d -exec busybox chmod u=rwx,g=,o= {} \;
	busybox chmod 1777 "${ROOTFS_MOUNT_DIR}/tmp"
else
	# Shared temp (fallback, no TMPDIR)
	log_warn "TMPDIR is not set, shared temp unavailable"
	log_warn "Using tmpfs as a fallback, X11 and related services will not work properly"
	mount_dir "-" "${ROOTFS_MOUNT_DIR}/tmp" "tmpfs" "size=512M"
fi

# Swap file (if it exists)
if [ -e "${ROOTFS_MOUNT_DIR}/swapfile" ]; then
	log_info "Enabling swap"
	busybox swapon "${ROOTFS_MOUNT_DIR}/swapfile"
	print_swap_info
fi

log_info "Mounted locations:"
busybox mount | grep -s "${ROOTFS_MOUNT_DIR}" || true