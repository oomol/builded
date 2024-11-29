#! /usr/bin/env bash

SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do
	DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
	SOURCE=$(readlink "$SOURCE")
	[[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)

SCRIPT_DIR=$DIR

cd "${SCRIPT_DIR}" || {
	echo "Error: failed to change dir to ${SCRIPT_DIR}"
	exit 100
}

pack_target() {
	files=$(brew list ${target_pkg})
	echo "=== pack ==="
	echo "$files"
	tar --append -vf package.tar $files
}

pack_target_libs() {
	deps="$(brew deps $target_pkg)"
	for dep in ${deps}; do
		echo "=== Analysize && Pack $dep ===="
		dylibs=$(brew list $dep | grep dylib)
		if [[ -n $dylibs ]]; then
			echo "$dylibs"
			tar --append -vf package.tar $dylibs
			ret=$?
			if [[ $ret -ne 0 ]]; then
				echo "Error: Packge $dep failed"
				exit 100
			fi
		fi
	done
}

main() {
	target_pkg=$1

	cd $SCRIPT_DIR
	rm -f package.tar
	pack_target $target_pkg

	cd $SCRIPT_DIR
	pack_target_libs $target_pkg

	tmp_dir="/tmp/.package_on_host_$target_pkg"

	mkdir -p $tmp_dir
	# Extract the package.tar into tmp_dir
	tar -xvf package.tar -C $tmp_dir
	rm package.tar

	{
		cd $tmp_dir
		mkdir -p ./bin
		cd ./bin
		rm -rf ./*
		ln -s ../opt/homebrew/Cellar/*/*/bin/* ./
	}

	{
		cd $tmp_dir
		mkdir -p ./lib
		cd ./lib
		rm -rf ./*
		ln -s ../opt/homebrew/Cellar/*/*/lib/* ./
	}

	{
		set -xe
		cd $tmp_dir
		tar -Jcvf ${target_pkg}.tar.xz *
		mv ${target_pkg}.tar.xz /tmp/
		set +xe
	}
}

main "$@"
