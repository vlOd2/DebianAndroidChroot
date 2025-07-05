#!/bin/bash
# Debian bootstrapper for an Android based chroot
set -e

TARGET_DIR="out/rootfs"
DEBIAN_ARCH="arm64"
DEBIAN_VARIANT="minbase" # Only this one seems to work properly
DEBIAN_EXTRA_PACKAGES="locales,dialog,nano,wget,curl,vim,command-not-found,sudo"
DEBIAN_EXCLUDED_PACKAGES="systemd"
DEBIAN_RELEASE="bookworm"

command_exists() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "E: Could not find $1"
		echo "E: Make sure to install the required packages and try again"
		return 1
	fi
	return 0
}

# Check for dependencies
if ! command_exists "chroot" || ! command_exists "debootstrap" || ! command_exists "qemu-aarch64-static"; then
	exit 1
fi

# Create rootfs dir
if [[ -e "${TARGET_DIR}" ]]; then
	echo "E: A rootfs is already present"
	echo "E: Delete the \"${TARGET_DIR}\" directory, and try again"
	exit 1
fi
mkdir -p "${TARGET_DIR}"

# Helper function to run bash commands inside the rootfs
run_chroot() {
	# Need to set LANG manually
	sudo LANG=C.UTF-8 chroot "${TARGET_DIR}/" qemu-aarch64-static /bin/bash -c "$*"
}

# Bootstrap Debian into rootfs dir
echo "I: Downloading Debian"
sudo debootstrap \
	--arch="${DEBIAN_ARCH}" --foreign \
	--variant="${DEBIAN_VARIANT}" \
	--include="${DEBIAN_EXTRA_PACKAGES}" --exclude="${DEBIAN_EXCLUDED_PACKAGES}" \
	"${DEBIAN_RELEASE}" "${TARGET_DIR}/" "http://ftp.debian.org/debian"
	
# Copy static emulator and finish bootstrap
echo "I: Finishing Debian setup"
sudo cp "/usr/bin/qemu-aarch64-static" "${TARGET_DIR}/usr/bin"
run_chroot "/debootstrap/debootstrap --second-stage"

# Configure tzdata interactively
echo "I: Configuring time"
run_chroot "echo \"0.0 0 0.0\" > /etc/adjtime"
run_chroot "echo \"0\" >> /etc/adjtime"
run_chroot "echo \"UTC\" >> /etc/adjtime"
run_chroot "dpkg-reconfigure tzdata"

# Configure locales interactively
echo "I: Configuring locale"
run_chroot "dpkg-reconfigure locales"

# Configure apt sources
echo "I: Configuring apt"
run_chroot "echo \"deb http://deb.debian.org/debian/ ${DEBIAN_RELEASE} main\" > /etc/apt/sources.list"
run_chroot "echo \"deb http://deb.debian.org/debian/ ${DEBIAN_RELEASE}-updates main\" >> /etc/apt/sources.list"
run_chroot "echo \"deb http://security.debian.org/debian-security/ ${DEBIAN_RELEASE}-security main\" >> /etc/apt/sources.list"
# Prevent systemd from being installed
run_chroot "mkdir -p /etc/apt/preferences.d/"
run_chroot "echo -e \"Package: systemd\nPin: release *\nPin-Priority: -1\" > /etc/apt/preferences.d/systemd"
run_chroot "echo -e \"\n\nPackage: *systemd*\nPin: release *\nPin-Priority: -1\" >> /etc/apt/preferences.d/systemd"
# Update apt sources
run_chroot "apt update"
run_chroot "update-command-not-found"

# Clean-up
run_chroot "apt clean"
run_chroot "history -c"

echo "I: Base configuration complete"
echo "I: You may now setup additional components, or package the rootfs"
sudo chroot "${TARGET_DIR}/" qemu-aarch64-static /bin/bash