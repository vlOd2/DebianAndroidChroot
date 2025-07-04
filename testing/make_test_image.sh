#!/bin/bash
set -e

SRC_IMAGE="../out/rootfs.img"
IMAGE_NAME="disk/disk.img"
IMAGE_MNT_DIR="disk/disk_mount"
IMAGE_SIZE=5 # GB

# Ensure a rootfs image has been created
if [[ ! -e "${SRC_IMAGE}" ]]; then
	echo "E: A rootfs image is not present"
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

# Copy rootfs image
echo "I: Copying rootfs image"
sudo cp -a "${SRC_IMAGE}" "${IMAGE_MNT_DIR}/" 

# Copy scripts
echo "I: Copying scripts"
sudo cp -a "../android_scripts/"* "${IMAGE_MNT_DIR}/"

# Unmount image
echo "I: Unmounting image"
sudo umount "${IMAGE_MNT_DIR}"
rmdir "${IMAGE_MNT_DIR}"