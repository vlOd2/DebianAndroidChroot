#!/bin/bash
set -e

SRC_DIR="out/rootfs"
IMAGE_NAME="out/rootfs.img"
IMAGE_MNT_DIR="out/rootfs_mount"
IMAGE_SIZE=4 # GB
SWAP_SIZE=2 # GB

command_exists() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "E: Could not find $1"
		echo "E: Make sure to install the required packages and try again"
		return 1
	fi
	return 0
}

# Check for dependencies
if ! command_exists "mkfs.ext4" || ! command_exists "mkswap"; then
	exit 1
fi

# Ensure a rootfs has been created
if [[ ! -e "${SRC_DIR}" ]]; then
	echo "E: A rootfs is not present"
	exit 1
fi
rm -f "${IMAGE_NAME}"

# Create image
echo "I: Creating image"
echo "I: Image size: ${IMAGE_SIZE} GB"
dd if=/dev/zero of="${IMAGE_NAME}" bs=1024M count="${IMAGE_SIZE}"
mkfs.ext4 "${IMAGE_NAME}"

# Mount image
echo "I: Mounting image"
mkdir -p "${IMAGE_MNT_DIR}"
sudo mount "${IMAGE_NAME}" "${IMAGE_MNT_DIR}"

# Copy rootfs files
echo "I: Copying rootfs"
sudo cp -a "${SRC_DIR}/"* "${IMAGE_MNT_DIR}/"

# Create swap
echo "I: Creating swap"
echo "I: Swap size: ${SWAP_SIZE} GB"
sudo dd if=/dev/zero of="${IMAGE_MNT_DIR}/swapfile" bs=1024M count="${SWAP_SIZE}"
sudo mkswap "${IMAGE_MNT_DIR}/swapfile"

# Unmount image
echo "I: Unmounting image"
sudo umount "${IMAGE_MNT_DIR}"
rmdir "${IMAGE_MNT_DIR}"