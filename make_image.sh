#!/bin/bash
set -eE
source ./common.sh

SRC_DIR="out/rootfs"
IMAGE_NAME="out/rootfs.img"
IMAGE_MNT_DIR="out/rootfs_mount"
IMAGE_SIZE=4 # GB
SWAP_SIZE=2 # GB

err_handler() {
	set +e
    echo "ERR_HANDLER: Error on line $1"
	echo "ERR_HANDLER: If this was unexpected, please make an issue report"
	echo "ERR_HANDLER: Cleaning up"
	sudo umount "${IMAGE_MNT_DIR}" >/dev/zero 2>&1
	rmdir "${IMAGE_MNT_DIR}" >/dev/zero 2>&1
	exit 1
}
trap 'err_handler $LINENO' ERR

# Check for dependencies
if ! command_exists "mkfs.ext4" || ! command_exists "mkswap" || ! command_exists "mount" || ! command_exists "umount"; then
	exit 1
fi

# Ensure a rootfs has been created
log_info "Checking work dir"
if [[ ! -e "${SRC_DIR}" ]]; then
	log_error "A rootfs is not present"
	log_error "Please run \"bootstrap_debian.sh\" and try again"
	exit 1
fi
rm -f "${IMAGE_NAME}"

# Create image
log_info "Creating image"
log_info "Image size: ${IMAGE_SIZE} GB"
dd if=/dev/zero of="${IMAGE_NAME}" bs=1024M count="${IMAGE_SIZE}"
mkfs.ext4 "${IMAGE_NAME}"

# Mount image
log_info "Mounting image"
mkdir -p "${IMAGE_MNT_DIR}"
sudo mount "${IMAGE_NAME}" "${IMAGE_MNT_DIR}"

# Copy rootfs files
log_info "Copying rootfs"
sudo cp -a "${SRC_DIR}/"* "${IMAGE_MNT_DIR}/"

# Create swap
log_info "Creating swap"
log_info "Swap size: ${SWAP_SIZE} GB"
sudo dd if=/dev/zero of="${IMAGE_MNT_DIR}/swapfile" bs=1024M count="${SWAP_SIZE}"
sudo mkswap "${IMAGE_MNT_DIR}/swapfile"

# Unmount image
log_info "Unmounting image"
sudo umount "${IMAGE_MNT_DIR}"
rmdir "${IMAGE_MNT_DIR}"