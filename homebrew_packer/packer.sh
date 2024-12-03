#! /usr/bin/env bash
set -o pipefail

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
	echo "=== pack ==="
	files=$(brew list ${target_pkg})
	echo "$files"
	tar --append -vf $target_pkg.tar $files
}

pack_target_libs() {
	deps="$(brew deps $target_pkg)"
	for dep in ${deps}; do
		echo "=== Analysize && Pack $dep ===="
		dylibs=$(brew list $dep | grep dylib)
		if [[ -n $dylibs ]]; then
			echo "$dylibs"
			tar --append -vf $target_pkg.tar $dylibs
			ret=$?
			if [[ $ret -ne 0 ]]; then
				echo "Error: Packge $dep failed"
				exit 100
			fi
		fi
	done
}

main() {
	brew --version >/dev/null 2>&1 || {
		echo "Brew not installed on system."
		exit 100
	}

	target_pkg=$1

	if [[ -z $target_pkg ]]; then
		echo "Which pkg should pack ?"
		exit 100
	fi

	cd $SCRIPT_DIR
	set -x
	rm -rf $target_pkg.tar
	set +x

	pack_target $target_pkg

	cd $SCRIPT_DIR
	pack_target_libs $target_pkg

	tmp_dir="/tmp/.package_on_host_$target_pkg" && rm -rf $tmp_dir && mkdir -p $tmp_dir

	{
		set -xe
		tar -xvf $target_pkg.tar -C $tmp_dir >/dev/null 2>&1
		set +xe
		echo "- Extract $target_pkg.tar into $tmp_dir done"

	}

	{
		set -ex
		rm $target_pkg.tar
		set +ex
		echo "- Delete $target_pkg.tar done"
	}

	{
		cd $tmp_dir
		mkdir -p ./bin
		cd ./bin
		rm -rf ./*
		ln -s ../opt/homebrew/Cellar/*/*/bin/* ./
		echo "Relocate the bins done"
	}

	{
		cd $tmp_dir
		mkdir -p ./lib
		cd ./lib
		rm -rf ./*
		ln -s ../opt/homebrew/Cellar/*/*/lib/* ./
		echo "Relocate the libs done"
	}

	{
		set -xe
		cd $tmp_dir
		tar -Jcvf $SCRIPT_DIR/$target_pkg.tar * >/dev/null 2>&1
		set +xe
		echo "Package $target_pkg successful !"
	}
}

main "$@"
