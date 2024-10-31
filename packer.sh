#! /usr/bin/env bash

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
			if [[ $ret -ne 0 ]];then
				echo "Error: Packge $dep failed"
				exit 100
			fi
		fi
	done
}

target_pkg=$1

pack_target $target_pkg
pack_target_libs $target_pkg

mkdir -p /tmp/.package_on_host
tar -xvf package.tar -C /tmp/.package_on_host

cd /tmp/.package_on_host/
mkdir -p ./bin
cd ./bin || exit 100
rm -rf ./*
ln -s ../opt/homebrew/Cellar/*/*/bin/* ./


cd /tmp/.package_on_host/
mkdir -p ./lib
cd ./lib
ln -s ../opt/homebrew/Cellar/*/*/lib/* ./

cd /tmp/.package_on_host

echo "export DYLD_LIBRARY_PATH=./lib" >> ffmpeg.sh
echo "export PATH=./bin" >> ffmpeg.sh
echo "ffmpeg" >> ffmpeg.sh
chmod +x ffmpeg.sh

tar -Jcvf ${target_pkg}.tar.xz *
mv ${target_pkg}.tar.xz /tmp/
