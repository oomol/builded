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
	chmod +x $SCRIPT_DIR/tools/cover_path
	./tools/cover_path "$@"
}

################### In Linux VM ###################
called_in_guest() {
	echo "==== Called in Linux Guest ===="
	if [[ -z "$*" ]]; then
		echo "Error: args empty, what binary do you want call ?"
		exit 100
	fi

	echo "CALLING WITH ARGS: $*"
	# First we need chmod +x to caller.sh in MacOS HOST
	SH_CALLER="${SCRIPT_DIR}/caller.sh"
	set -xe
	exec_macos chmod +x "$SH_CALLER"
	exec_macos "$SH_CALLER" "$@"
	set +xe
}

################### In MACOS HOST ###################
called_in_host() {
	echo "==== Called in MacOS Host ===="
	if [[ -z "$*" ]]; then
		echo "Error: args empty, what binary do you want call ?"
		exit 100
	fi

	set -ex

	export DYLD_LIBRARY_PATH="${SCRIPT_DIR}/lib"
	export PATH="$SCRIPT_DIR/bin:$PATH"
	chmod -R +x $SCRIPT_DIR/opt/homebrew/Cellar/ffmpeg

	set +ex

	cmdline=$(cover_path "$@"| grep NEW_CMELINE| cut -d ':' -f2-)
	set -xe
	$cmdline
	set +xe
}

main() {
	OS=$(uname -s)
	if [[ $OS == Linux ]]; then
		called_in_guest "$@"
	elif [[ $OS == Darwin ]]; then
		called_in_host "$@"
	fi
}

main "$@"  2>&1 | tee -a "$SCRIPT_DIR/exec.logs"
