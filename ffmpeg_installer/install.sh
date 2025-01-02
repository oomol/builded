#! /usr/bin/env bash
get_host_os() {
	arch=$(uname -m)
	platform=unknown
	if [[ -z $arch ]]; then
		echo "Error: unknow architecture"
		exit 100
	fi
	# For wsl2 with nvidia GPU
	if [[ $arch == x86_64 ]] && [[ -f "/usr/lib/wsl" ]]; then
		platform="wsl2-$arch"
		return
	fi

	# For MacOS-x86_64
	if [[ $arch == x86_64 ]]; then
		platform="macos-$arch"
		return
	fi

	# For MacOS-aarch64
	if [[ $arch == aarch64 ]] || [[ $arch == arm64 ]]; then
		platform="macos-$arch"
		return
	fi
}

system_check() {
	install_dir=$(mount | grep host-shared | xargs | cut -d ' ' -f3)
	if [[ -z "$install_dir" ]]; then
		echo 'Error: /Users/<UserName>/.oomol-studio/host-shared/tmp dir not find !'
		exit 100
	fi
	get_host_os

	if [[ $platform == unknown ]]; then
		echo "Error: unknown platform"
		exit 100
	fi
}
# Setup ffmpeg binaries logic
setup_ffmpeg_for_macos_aarch64() {
	if [[ "$platform" != macos-aarch64 ]]; then
		echo "Error: only support macos-aarch64"
		exit 100
	fi

	if [[ -z "$install_dir" ]]; then
		echo "Error: env install_dir empty"
		exit 100
	fi

	# Install exec_macos cli tool
	cd "$install_dir/ffmpeg" && {
		rm -f /usr/bin/exec_macos
		cp exec_macos /usr/bin/exec_macos
		chmod +x /usr/bin/exec_macos
		chmod +x "$install_dir/ffmpeg/caller.sh"
		# generate the caller into /usr/local/bin
		bin_list="aviocat crypto_bench cws2fws enc_recon_frame_test enum_options ffescape ffeval ffhash ffmpeg ffplay ffprobe fourcc2pixfmt graph2dot ismindex pktdumper probetest qt-faststart scale_slice_test seek_print sidxindex trasher uncoded_frame venc_data_dump zmqsend"
		for bin in $bin_list; do
			echo "Generate ffmpeg caller in /usr/bin/$bin"

			echo '#! /usr/bin/env bash' >"/usr/bin/$bin"
			echo "$install_dir/ffmpeg/caller.sh $bin" '$@' >>"/usr/bin/$bin"
			chmod +x "/usr/bin/$bin"
		done
	} || {
		echo "Error change to install_dir/ffmpeg failed"
		exit 100
	}
}

setup_ffmpeg_for_wsl2_x86_64() {
	echo ""
}

setup_ffmpeg() {
	local platform=$platform
	if [[ "$platform" == macos-aarch64 ]]; then
		setup_ffmpeg_for_macos_aarch64
	elif [[ "$platform" == wsl2-x86_64 ]]; then
		setup_ffmpeg_for_wsl2_x86_64
	else
		echo "Error: unsupport platform: $platform"
		exit 100
	fi

}

download_ffmpeg() {
	local platform=$platform
	if [[ $platform == macos-aarch64 ]]; then
		tag_v="v1.4"
		url="https://github.com/oomol/builded/releases/download/$tag_v/ffmpeg_macos_arm64_ventura.tar.xz"
		if [[ -n $MY_CUSTOM_URL ]]; then
			url=$MY_CUSTOM_URL
		fi
		wget "$url" --output-document /tmp/ffmpeg.tar.xz
		rm -rf "$install_dir/ffmpeg"
		tar -xvf /tmp/ffmpeg.tar.xz -C "$install_dir"
		rm /tmp/ffmpeg.tar.xz

	elif [[ $platform == wsl2-x86_64 ]]; then
		echo ""
	else
		echo "Error: unsupport platform: $platform"
		exit 100
	fi
}

main() {
	# set vars platform && install_dir
	system_check

	echo "Download ffmpeg for $platform"
	download_ffmpeg
	setup_ffmpeg
}
