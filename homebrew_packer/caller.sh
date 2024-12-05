#!/usr/bin/env bash
set -o pipefail

SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
	SOURCE=$(readlink "$SOURCE")
	[[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)

SCRIPT_DIR="${DIR}"

cd "$SCRIPT_DIR" || {
	echo "Error: failed to change the workdir to ${SCRIPT_DIR}"
	exit 100
}

cover_path() {
	chmod +x ./tools/cover_path
	./tools/cover_path "$@"
}

################### In Linux VM ###################
called_in_guest() {
	echo "- Called in Linux Guest"
	ARGS="$@"

	if [[ -z $ARGS ]]; then
		echo "Error: args empty, what binary do you want call ?"
		exit 100
	fi

	echo "ARGS: $ARGS"
	# First we need chmod +x to caller in MacOS HOST
	echo exec_macos chmod +x "${SCRIPT_DIR}/$(basename "$0")"
	exec_macos chmod +x "${SCRIPT_DIR}/$(basename "$0")"

	# Then using caller.sh call the binary with args
	# new_cmdline=$(cover_path "$@" | cut -d ':' -f2-)
	echo exec_macos "${SCRIPT_DIR}/$(basename "$0")" "$@"
	exec_macos "${SCRIPT_DIR}/$(basename "$0")" "$@"
}

################### In MACOS HOST ###################
called_in_host() {
	if [[ -z "$*" ]]; then
		echo "Error: args empty, what binary do you want call ?"
		exit 100
	fi

	set -x
	export DYLD_LIBRARY_PATH="${SCRIPT_DIR}/lib"
	export PATH="$SCRIPT_DIR/bin:$PATH"
	chmod -R +x $SCRIPT_DIR/opt/homebrew/Cellar/ffmpeg
	set +x
	cmdline=$(cover_path "$@"| grep NEW_CMELINE| cut -d ':' -f2-)
	set -x
	$cmdline
}

main() {
	echo "==== Guest Comand Proxy to MacOS Host ====="
	OS=$(uname -s)
	if [[ $OS == Linux ]]; then
		called_in_guest "$@"
	elif [[ $OS == Darwin ]]; then
		called_in_host "$@"
	fi
}

main "$@"
