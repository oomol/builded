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
	args="$(echo "$@" | xargs -n1)"
	end_str="$args"
	for str in $args; do
		vm_path=$(echo "$str" | grep -o '/[^[:space:]]*' | cut -d '/' -f 1,2,3 -s)
		if [[ -n $vm_path ]]; then
			echo "=== OOMOL DRIVER MAP ==="
			echo "container:$vm_path"

			host_dir=$(grep -m1 -B 1 "$vm_path" /root/.oomol-studio/app-config/oomol-storage/mount-point.json | grep hostPath | cut -d ':' -f2 | sed 's/"//g' | sed 's/,//g' | tr -d ' ')
			# If the dir is /oomol-driver/oomol-storage, cover to /Users/<NAME>/oomol-storage
			if [[ $vm_path == "/oomol-driver/oomol-storage" ]]; then
				host_user_dir="$(pwd | cut -d '/' -f 1,2,3 -s)"
				echo host_user_dir:$host_user_dir
				host_dir="$host_user_dir/oomol-storage"
			fi
			echo "host:$host_dir"
			end_str=$(echo $end_str | sed "s#$vm_path#$host_dir#g")
		fi
	done
	echo exec_macos "${SCRIPT_DIR}/$(basename "$0")" "$end_str"
}

################### In Linux VM ###################
called_in_guest() {
	echo "- Called in Linux Guest"
	ARGS="$@"

	if [[ -z $ARGS ]];then
		echo "Error: args empty, what binary do you want call ?"
		exit 100
	fi

	echo "ARGS: $ARGS"
	echo exec_macos chmod +x "${SCRIPT_DIR}/$(basename "$0")"
	echo exec_macos ${SCRIPT_DIR}/$(basename "$0") "$ARGS"
}

################### In MACOS HOST ###################
called_in_host() {
	echo "- Called in MacOS Host"
	set -x
	export DYLD_LIBRARY_PATH="${SCRIPT_DIR}/lib"
	export PATH="$SCRIPT_DIR/bin:$PATH"
	"$@"
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
