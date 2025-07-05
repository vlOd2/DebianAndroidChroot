#!/bin/bash
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

command_exists() {
	if ! command -v "$1" >/dev/null 2>&1; then
		log_error "Could not find $1"
		log_error "Make sure to install the required packages and try again"
		return 1
	fi
	return 0
}

echo "DebianAndroidChroot"
echo "---------------------"