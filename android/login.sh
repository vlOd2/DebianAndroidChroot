#!/bin/bash
set -e
source ./common.sh

USER="root"
if [ -n "$1" ]; then
	USER="$1"
fi

if ! is_mounted_dir "${ROOTFS_MOUNT_DIR}"; then
	log_error "The rootfs is not mounted"
	exit 1
fi

log_info "Logging in as ${USER}"
exec busybox chroot "${ROOTFS_MOUNT_DIR}/" /bin/env -i TERM=$TERM /bin/su -l "${USER}"