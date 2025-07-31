#!/bin/bash
set -e
source ./common.sh

TARGET_DIR="out/rootfs"
DEBIAN_ARCH="arm64"
DEBIAN_VARIANT="minbase" # Only this one seems to work properly
DEBIAN_EXTRA_PACKAGES="locales,dialog,nano,wget,curl,vim,command-not-found,sudo"
DEBIAN_EXCLUDED_PACKAGES="systemd"
DEBIAN_RELEASE="bookworm"

echo "DEBIAN_ARCH: ${DEBIAN_ARCH}"
echo "DEBIAN_VARIANT: ${DEBIAN_VARIANT}"
echo "DEBIAN_EXTRA_PACKAGES: ${DEBIAN_EXTRA_PACKAGES}"
echo "DEBIAN_EXCLUDED_PACKAGES: ${DEBIAN_EXCLUDED_PACKAGES}"
echo "DEBIAN_RELEASE: ${DEBIAN_RELEASE}"

# Check for dependencies
if ! command_exists "chroot" || ! command_exists "debootstrap" || ! command_exists "qemu-aarch64-static"; then
	exit 1
fi

# Create rootfs dir
if [[ -e "${TARGET_DIR}" ]]; then
	log_error "A rootfs is already present"
	log_error "Delete the \"${TARGET_DIR}\" directory, and try again"
	exit 1
fi
mkdir -p "${TARGET_DIR}"

# Helper function to run bash commands inside the rootfs
run_chroot() {
	# Need to set LANG manually
	sudo LANG=C.UTF-8 chroot "${TARGET_DIR}/" qemu-aarch64-static /bin/bash -c "$*"
}

# Bootstrap Debian into rootfs dir
log_info "Bootstrapping Debian"
sudo debootstrap \
	--arch="${DEBIAN_ARCH}" --foreign \
	--variant="${DEBIAN_VARIANT}" \
	--include="${DEBIAN_EXTRA_PACKAGES}" --exclude="${DEBIAN_EXCLUDED_PACKAGES}" \
	"${DEBIAN_RELEASE}" "${TARGET_DIR}/" "http://ftp.debian.org/debian"
	
# Copy static emulator and finish bootstrap
log_info "Running second stage"
sudo cp "/usr/bin/qemu-aarch64-static" "${TARGET_DIR}/usr/bin"
run_chroot "/debootstrap/debootstrap --second-stage"

# Configure tzdata interactively
log_info "Configuring time"
run_chroot "echo \"0.0 0 0.0\" > /etc/adjtime"
run_chroot "echo \"0\" >> /etc/adjtime"
run_chroot "echo \"UTC\" >> /etc/adjtime"
run_chroot "dpkg-reconfigure tzdata"

# Configure locales interactively
log_info "Configuring locale"
run_chroot "dpkg-reconfigure locales"

# Add Android groups
log_info "Configuring users"
run_chroot "groupadd -f -g 3001 aid_net_bt_admin"
run_chroot "groupadd -f -g 3002 aid_net_bt"
run_chroot "groupadd -f -g 3003 aid_inet"
run_chroot "groupadd -f -g 3004 aid_net_raw"
run_chroot "groupadd -f -g 3005 aid_net_admin"
run_chroot "groupadd -f -g 3006 aid_net_bw_stats"
run_chroot "groupadd -f -g 3007 aid_net_bw_acct"
run_chroot "groupadd -f -g 3009 aid_readproc"
run_chroot "groupadd -f -g 3010 aid_wakelock"
run_chroot "groupadd -f -g 3011 aid_uhid"
run_chroot "groupadd -f -g 3012 aid_readtracefs"
# Add root to them
run_chroot "usermod -G aid_net_bt_admin,aid_net_bt,aid_inet,aid_net_raw,aid_net_admin,aid_net_bw_stats,aid_net_bw_acct,aid_readproc,aid_wakelock,aid_uhid,aid_readtracefs -a root"
# Change primary group of _apt
run_chroot "usermod -g aid_inet _apt"

# Configure networking
log_info "Configuring networking"
run_chroot "echo localhost > /etc/hostname"
run_chroot "echo -e nameserver 1.1.1.1\\\\nnameserver 1.0.0.1 > /etc/resolv.conf"
run_chroot "echo -e 127.0.0.1\\\\tlocalhost > /etc/hosts"

# Configure apt sources
log_info "Configuring apt"
run_chroot "echo \"deb http://deb.debian.org/debian ${DEBIAN_RELEASE} main\" > /etc/apt/sources.list"
run_chroot "echo \"deb http://deb.debian.org/debian ${DEBIAN_RELEASE}-updates main\" >> /etc/apt/sources.list"
run_chroot "echo \"deb http://security.debian.org/debian-security ${DEBIAN_RELEASE}-security main\" >> /etc/apt/sources.list"
# Prevent systemd from being installed
run_chroot "mkdir -p /etc/apt/preferences.d/"
run_chroot "echo -e \"Package: systemd\\\\nPin: release *\\\\nPin-Priority: -1\" > /etc/apt/preferences.d/systemd"
run_chroot "echo -e \"\\\\n\\\\nPackage: *systemd*\\\\nPin: release *\\\\nPin-Priority: -1\" >> /etc/apt/preferences.d/systemd"
# Update apt sources
run_chroot "apt update"
run_chroot "update-command-not-found"

# Clean-up
run_chroot "apt clean"
run_chroot "history -c"

log_info "Base configuration complete"
log_info "You may now setup additional components, or package the rootfs"
sudo chroot "${TARGET_DIR}/" qemu-aarch64-static /bin/bash