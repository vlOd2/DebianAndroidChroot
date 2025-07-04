#!/bin/bash
source ./common.sh

# Rootfs image
log_info "Mounting rootfs"
mkdir -p "${ROOTFS_MOUNT_DIR}"
busybox mount "${ROOTFS_IMAGE}" "${ROOTFS_MOUNT_DIR}"

# Systemfs aka /dev, /proc, /sys
log_info "Mounting systemfs"
mkdir -p "${ROOTFS_MOUNT_DIR}/dev"
mkdir -p "${ROOTFS_MOUNT_DIR}/proc"
mkdir -p "${ROOTFS_MOUNT_DIR}/sys"
busybox mount -t proc none "${ROOTFS_MOUNT_DIR}/proc"
busybox mount -t sysfs none "${ROOTFS_MOUNT_DIR}/sys"
busybox mount -t devtmpfs none "${ROOTFS_MOUNT_DIR}/dev"

# Shared memory (/dev/shm, needed by chromium apps)
log_info "Mounting shared memory"
mkdir -p "${ROOTFS_MOUNT_DIR}/dev/shm"
busybox mount -o size=512M -t tmpfs none "${ROOTFS_MOUNT_DIR}/dev/shm"

# Shared temp (needed for X11, pulse, etc)
mkdir -p "${ROOTFS_MOUNT_DIR}/tmp"
log_info "Mounting shared temp"
if [[ -n "${ROOTFS_TEMP}" ]]; then
	# Shared temp (bind)
	busybox mount --bind "${ROOTFS_TEMP}" "${ROOTFS_MOUNT_DIR}/tmp"
	busybox chmod 1777 "${ROOTFS_MOUNT_DIR}/tmp"
	busybox find "${ROOTFS_MOUNT_DIR}/tmp" -type f -exec busybox chmod u=rw,g=,o= {}
	busybox find "${ROOTFS_MOUNT_DIR}/tmp" -type d -exec busybox chmod u=rwx,g=,o= {}
else
	# Shared temp (fallback, no TMPDIR)
	log_warn "TMPDIR is not set, shared temp unavailable"
	log_warn "Using tmpfs as a fallback, X11 and related services will not work properly"
	busybox mount -o size=512M -t tmpfs none "${ROOTFS_MOUNT_DIR}/tmp"
fi

# Swap file
if [[ -e "${ROOTFS_MOUNT_DIR}/swapfile" ]]; then
	log_info "Enabling swap"
	busybox swapon "${ROOTFS_MOUNT_DIR}/swapfile"
	print_swap_info
fi

log_info "Mounted locations:"
busybox mount | grep -s "${ROOTFS_MOUNT_DIR}"