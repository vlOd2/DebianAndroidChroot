#!/bin/bash
source ./common.sh

log_debug "Current process ID: $$"
log_debug "Current process parent ID: $PPID"

log_info "Killing processes"
for pid in /proc/[0-9]*; do
    pid="${pid#/proc/}"
	matched=0

	# Try to match by exe path
	# This should match most if not all chroot processes
    exe=$(readlink "/proc/${pid}/exe" 2>/dev/null)
    if [ "${exe#$CHROOT_PATH}" != "${exe}" ]; then
        log_info "Killing ${pid} (exe: ${exe})"
        matched=1
    fi
	
	# If the process didn't match, try to match by the process chroot directory
	# Something has gone wrong if this matches and not the previous method
	if [ "${matched}" = "0" ]; then
		root=$(readlink "/proc/${pid}/root" 2>/dev/null)
		if [ "${root#$CHROOT_PATH}" != "${root}" ]; then
			log_info "Killing ${pid} (root: ${root})"
			matched=1
		fi
	fi

	# If nothing matched, skip the process
	if [ "${matched}" = "0" ]; then
		# As a last resort, try a less reliable matching method that won't kill the process
		# This matches processes using libraries or interpreters from the chroot
		if grep -q "$CHROOT_PATH" "/proc/${pid}/maps" 2>/dev/null; then
			log_debug "Ignoring ${pid} (potential match)"
		fi
		continue
	fi

	# Skip current process or parent process
	if [ "${pid}" = $$ ] || [ "${pid}" = $PPID ]; then
		log_debug "Ignoring ${pid} (current process)"
		continue
	fi

	if kill -9 "$pid" 2>/dev/null; then
		log_info "Killed ${pid}"
	else
		log_error "Could not kill ${pid}"
	fi
done

if [[ -e "${ROOTFS_MOUNT_DIR}/swapfile" ]]; then
	log_info "Disabling swap"
	busybox swapoff "${ROOTFS_MOUNT_DIR}/swapfile"
	print_swap_info
fi

unmount_dir() {
	if ! grep -qs "$1 " /proc/mounts; then
		log_warn "Skipping \"$1\", as it's not mounted"
		return
	fi
	log_info "Un-mounting \"$1\""
	if ! busybox umount "$1"; then
		log_warn "Could not un-mount \"$1\", un-mounting lazily"
		busybox umount -l "$1"
	fi
}
unmount_dir "${ROOTFS_MOUNT_DIR}/dev/shm"
unmount_dir "${ROOTFS_MOUNT_DIR}/proc"
unmount_dir "${ROOTFS_MOUNT_DIR}/sys"
unmount_dir "${ROOTFS_MOUNT_DIR}/dev"
unmount_dir "${ROOTFS_MOUNT_DIR}/tmp"
unmount_dir "${ROOTFS_MOUNT_DIR}"

log_info "Mounted locations:"
busybox mount | grep -s "${ROOTFS_MOUNT_DIR}"