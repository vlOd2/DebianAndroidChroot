#!/bin/bash
set -eE
export ROOTFS_PATH="/data/chroot/rootfs_mount"
export VIRGL_SERVER="virgl_test_server_android"
export VIRGL_SERVER_ARGS="--angle-gl"

ANSI_ESCAPE_RESET="\033[0m"
ANSI_ESCAPE_BLACK="\033[0;30m"
ANSI_ESCAPE_RED="\033[0;31m"
ANSI_ESCAPE_GREEN="\033[0;32m"
ANSI_ESCAPE_YELLOW="\033[0;33m"
ANSI_ESCAPE_BLUE="\033[0;34m"
ANSI_ESCAPE_PURPLE="\033[0;35m"
ANSI_ESCAPE_CYAN="\033[0;36m"
ANSI_ESCAPE_WHITE="\033[0;37m"

log_debug() { 
	echo -e "${ANSI_ESCAPE_BLUE}D: $@${ANSI_ESCAPE_RESET}"
}
log_info() { 
	echo -e "${ANSI_ESCAPE_GREEN}I: $@${ANSI_ESCAPE_RESET}"
}
log_warn() { 
	echo -e "${ANSI_ESCAPE_YELLOW}W: $@${ANSI_ESCAPE_RESET}"
}
log_error() { 
	echo -e "${ANSI_ESCAPE_RED}E: $@${ANSI_ESCAPE_RESET}"
}

perform_command_check() {
	if ! command -v "$1" >/dev/null 2>&1; then
		log_error "Could not find \"$1\""
		log_error "Make sure to install the required packages and try again"
		return 1
	fi
	return 0
}

is_mounted_dir() {
	# Add a space to avoid matching /foo/bar when checking /foo
	grep -qs "$1 " /proc/mounts
}

terminate_processes() {
	local procIDs=$(pgrep --full -d " " com.termux.x11)
	log_info "Killing X"
	if [ -n "${procIDs}" ]; then
		kill -9 "${procIDs}"
	fi
	
	log_info "Killing virgl"
	if ! killall -9 "${VIRGL_SERVER}"; then
		log_warn "virgl was not running"
	fi
	
	log_info "Killing pulseaudio"
	if ! killall -9 "pulseaudio"; then
		log_warn "pulseaudio was not running"
	fi
}

TERMINATED="0"
err_handler() {
	if [ "${TERMINATED}" = "1" ]; then
		return
	fi
	set +e
    echo "ERR_HANDLER: Error on line $1"
	echo "ERR_HANDLER: If this was unexpected, please make an issue report"
	terminate_processes
	exit 1
}
trap 'err_handler $LINENO' ERR

exit_handler() {
	TERMINATED="1"
	set +eE # Prevent killed process from triggering errexit
    log_info "Received interrupt signal, exitting"
	terminate_processes
	exit 0
}
trap 'exit_handler' SIGINT

echo "DebianAndroidChroot"
echo "---------------------"
echo "ROOTFS_PATH=${ROOTFS_PATH}"
echo ""

if [ $(id -u) = "0" ]; then
	log_error "This script must not be run under root"
	exit 1
fi

if ! is_mounted_dir "${ROOTFS_PATH}"; then
	log_error "Rootfs is not mounted"
	log_error "Please mount the rootfs in a separate shell and try again"
	exit 1
fi

if ! perform_command_check "termux-x11" || ! perform_command_check "pulseaudio" || ! perform_command_check "virgl_test_server_android"; then
	exit 1
fi

# This also gives us an oportunity to temporarily start X and adjust the permissions
log_info "Cleaning up previous processes"
TERMUX_X11_DEBUG=1 termux-x11 :0 >x.log 2>&1 &
sleep 1
chmod 1777 -R "${TMPDIR}/.X11-unix/"
kill -9 %1
terminate_processes

log_info "Starting pulseaudio"
pulseaudio --start --exit-idle-time=-1
pactl load-module module-native-protocol-tcp auth-anonymous=1

log_info "Starting virgl"
"${VIRGL_SERVER}" "${VIRGL_SERVER_ARGS}" &

log_info "Starting X"
log_info "The script will wait for CTRL C to terminate"
# This currently fails due to a lack of permissions, and because of SELInux, this script cannot be ran under root
#export XKB_CONFIG_ROOT="${ROOTFS_PATH}/usr/share/X11/xkb"
TERMUX_X11_DEBUG=1 termux-x11 :0 >x.log 2>&1