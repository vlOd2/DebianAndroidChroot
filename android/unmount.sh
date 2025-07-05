#!/bin/bash
set -eE
source ./common.sh

err_handler() {
	set +e
    echo "ERR_HANDLER: Error on line $1"
	echo "ERR_HANDLER: If this was unexpected, please make an issue report"
	exit 1
}
trap 'err_handler $LINENO' ERR

log_debug "Current process ID: $$"
log_debug "Current process parent ID: $PPID"

# Iterate /proc and find chroot processes
kill_processes() {
	for raw_pid in /proc/[0-9]*; do
		local pid="${raw_pid#/proc/}"

		# Skip current process or parent process
		if [ "${pid}" = $$ ] || [ "${pid}" = $PPID ]; then
			log_debug "Ignoring ${pid} (current process)"
			continue
		fi
		
		local matched=0
		local proc_exe=$(readlink "/proc/${pid}/exe" 2>/dev/null)
		local proc_root=$(readlink "/proc/${pid}/root" 2>/dev/null)

		if [ "${proc_exe#$CHROOT_PATH}" != "${proc_exe}" ]; then
			log_info "Killing ${pid} (exe: ${proc_exe})"
			matched=1
		elif [ "${proc_root#$CHROOT_PATH}" != "${proc_root}" ]; then
			log_info "Killing ${pid} (root: ${proc_root})"
			matched=1
		fi

		# If nothing matched, skip the process
		if [ "${matched}" = "0" ]; then
			## Match based on libraries or interpreters from the chroot (not very reliable)
			#if grep -q "$CHROOT_PATH" "/proc/${pid}/maps" 2>/dev/null; then
			#	log_debug "Ignoring ${pid} (potential match)"
			#fi
			continue
		fi

		if kill -9 "$pid" >/dev/null 2>&1; then
			log_info "Killed ${pid}"
		else
			log_error "Could not kill ${pid}"
		fi
	done
}

# Try to kill chroot processes
log_info "Killing processes (this may take awhile)"
if [ -e /proc ]; then
	kill_processes
else
	log_error "Cannot kill processes as /proc is unavailable"
fi 

# Swap file (if it exists)
if [ -e "${ROOTFS_MOUNT_DIR}/swapfile" ]; then
	log_info "Disabling swap"
	busybox swapoff "${ROOTFS_MOUNT_DIR}/swapfile"
	print_swap_info
fi

# Helper that un-mounts only when necessary and fallbacks to a lazy un-mount
unmount_dir() {
	if ! is_mounted_dir "$1"; then
		log_warn "Skipping \"$1\", as it's not mounted"
		return
	fi
	log_info "Un-mounting \"$1\""
	if ! busybox umount "$1"; then
		log_warn "Could not un-mount \"$1\", un-mounting lazily"
		busybox umount -l "$1" || true
	fi
}

# Un-mount
unmount_dir "${ROOTFS_MOUNT_DIR}/dev/shm"
unmount_dir "${ROOTFS_MOUNT_DIR}/proc"
unmount_dir "${ROOTFS_MOUNT_DIR}/sys"
unmount_dir "${ROOTFS_MOUNT_DIR}/dev"
unmount_dir "${ROOTFS_MOUNT_DIR}/tmp"
unmount_dir "${ROOTFS_MOUNT_DIR}"

# Remove the mount points
rmdir "${ROOTFS_MOUNT_DIR}/dev/shm" >/dev/null 2>&1 || true
rmdir "${ROOTFS_MOUNT_DIR}/dev" >/dev/null 2>&1 || true
rmdir "${ROOTFS_MOUNT_DIR}/tmp" >/dev/null 2>&1 || true
rmdir "${ROOTFS_MOUNT_DIR}/proc" >/dev/null 2>&1 || true
rmdir "${ROOTFS_MOUNT_DIR}/sys" >/dev/null 2>&1 || true
rmdir "${ROOTFS_MOUNT_DIR}" >/dev/null 2>&1 || true

# Print anything remaining (should be nothing)
log_info "Mounted locations:"
busybox mount | grep -s "${ROOTFS_MOUNT_DIR}" || true