#!/usr/bin/env bash
set -o pipefail

get_source_dir() {
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
	export SCRIPT_DIR
}

cover_path() {
	chmod +x $SCRIPT_DIR/tools/cover_path
	./tools/cover_path "$@" 2>>$SCRIPT_DIR/exec_log
}

# log() echo all message into $SCRIPT_DIR/exec_log
# You can using tail -f $SCRIPT_DIR continue watch the logs comming
log() {
	echo "$@" >> $SCRIPT_DIR/exec_log
}

################### In Linux VM ###################
called_in_guest() {
	log "==== Called in Linux Guest ===="
	if [[ -z "$*" ]]; then
		log "Error: args empty, what binary do you want call ?"
		exit 100
	fi

	log "CALLING WITH ARGS: $*"
	# First we need chmod +x to caller.sh in MacOS HOST
	SH_CALLER="${SCRIPT_DIR}/caller.sh"
	export SH_CALLER

	if [[ ! -f /usr/bin/exec_macos ]]; then
		log "exec_macos not find in /usr/bin/"
		exit 100
	fi

	exec_macos chmod +x "$SH_CALLER"
	exec_macos "$SH_CALLER" "$@"
}

################### In MACOS HOST ###################
called_in_host() {
	log "==== Called in MacOS Host ===="
	if [[ -z "$*" ]]; then
		log "Error: args empty, what binary do you want call ?"
		exit 100
	fi

	export DYLD_LIBRARY_PATH="${SCRIPT_DIR}/lib"
	export PATH="$SCRIPT_DIR/bin:$PATH"
	chmod -R +x $SCRIPT_DIR/opt/homebrew/Cellar/ffmpeg

	cmdline=$(cover_path "$@" | grep NEW_CMELINE | cut -d ':' -f2-)
	log "CONVERED FULL CMDLINE: $cmdline"
	DYLD_LIBRARY_PATH="${SCRIPT_DIR}/lib" PATH="$SCRIPT_DIR/bin:$PATH" "$cmdline"
}

get_source_dir
if [[ $(uname -s) == Linux ]]; then
	# stdout and stderr all into stderr
	called_in_guest "$@"
elif [[ $(uname -s) == Darwin ]]; then
	called_in_host "$@"
fi
