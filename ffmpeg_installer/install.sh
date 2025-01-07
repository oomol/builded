#! /usr/bin/env bash
set -o pipefail

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
	# You can set the INSTALL_DIR env to custom install dir
	if [[ -n "$INSTALL_DIR" ]]; then
		install_dir="$INSTALL_DIR"
	fi

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

chmod_on_host() {
	local b="$1"
	chmod +x /usr/bin/exec_macos && exec_macos chmod +x "${b}"
}

chmod_on_guest() {
	local b="$1"
	chmod +x "${b}"
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
		rm -f "/usr/bin/exec_macos"
		cp exec_macos "/usr/bin/exec_macos"
		chmod_on_guest "/usr/bin/exec_macos"
		chmod_on_host "$install_dir/ffmpeg/caller"

		# generate the caller into /usr/local/bin
		bin_list="aviocat crypto_bench cws2fws enc_recon_frame_test enum_options ffescape ffeval ffhash ffmpeg ffplay ffprobe fourcc2pixfmt graph2dot ismindex pktdumper probetest qt-faststart scale_slice_test seek_print sidxindex trasher uncoded_frame venc_data_dump zmqsend"
		for bin in $bin_list; do
			echo "Generate ffmpeg caller in /usr/bin/$bin"
			script_part_one="IyEgL3Vzci9iaW4vZW52IGJhc2gKY3AgL2Rldi9udWxsIC90bXAvLnRtcF9hcmdzCmZvciBhcmcgaW4gIiRAIjsgZG8KICBlY2hvIC1uIFwnXCIkYXJnXCJcJyAnICcgPj4gL3RtcC8udG1wX2FyZ3MKZG9uZQoKZmluYWxfYXJnPSQoY2F0IC90bXAvLnRtcF9hcmdzKQojZXZhbCAiJChlY2hvIGV4ZWNfbWFjb3MgL1VzZXJzL2RhbmhleG9uL2ZmbXBlZ19pbnN0YWxsX2Rpci9mZm1wZWcvY2FsbGVyIGZmbXBlZyAkZmluYWxfYXJnKSIK"
			echo $script_part_one | base64 -d >"/usr/bin/$bin"
			script_part_two="ZXZhbCAiJChlY2hvIGV4ZWNfbWFjb3MgSU5TVEFMTF9ESVIvZmZtcGVnL2NhbGxlciBQUk9KICRmaW5hbF9hcmcpIgo="
			echo $script_part_two | base64 -d | sed "s#INSTALL_DIR#$install_dir#g" | sed "s/PROJ/$bin/g" >>"/usr/bin/$bin"
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
	local platform="$platform"
	if [[ "$platform" == macos-aarch64 ]]; then
		tag_v="v1.4"
		url="https://github.com/oomol/builded/releases/download/$tag_v/ffmpeg_macos_arm64_ventura.tar.xz"
		# You can set the MY_CUSTOM_URL env to custom ffmpeg download url
		if [[ -n $MY_CUSTOM_URL ]]; then
			url=$MY_CUSTOM_URL
		fi

		if [[ -z "$install_dir" ]]; then
			echo "Error: env install_dir empty"
			exit 100
		fi

		wget "$url" --output-document /tmp/ffmpeg.tar.xz

		set +e
		rm -rf "$install_dir/ffmpeg"
		set -e
		mkdir -p "$install_dir"
		tar -xvf /tmp/ffmpeg.tar.xz -C "$install_dir"
		rm -rf /tmp/ffmpeg.tar.xz
	elif [[ $platform == wsl2-x86_64 ]]; then
		echo ""
	else
		echo "Error: unsupport platform: $platform"
		exit 100
	fi
}

# $MY_CUSTOM_URL Custom ffmpeg download url
# $$INSTALL_DIR  Custom ffmpeg install dir
install_for_mac_arm64() {
	# set vars platform && install_dir
	system_check

	echo "Download ffmpeg for $platform"
	download_ffmpeg
	setup_ffmpeg
}

install_for_wsl2_amd64() {
	nvidia-smi || {
		echo "nvidia-smi running failed, mybe you dont have nvidia GPU card on your system or host driver not installed"
		exit 10
	}
	wget https://github.com/oomol/builded/releases/download/v1.7/ffmpeg-wsl2_x86_64.tar.xz --output-document=/tmp/ffmpeg-wsl2_x86_64.tar.xz
	tar -xvf /tmp/ffmpeg-wsl2_x86_64.tar.xz  -C /tmp/
	echo "Install ffmpeg"
	cp /tmp/ffmpeg/ffmpeg /usr/bin/
	cp /tmp/ffmpeg/ffprobe /usr/bin/
	echo "Install ffmpeg done"
}

main() {
	uname -a | grep --ignore-case microsoft-standard-WSL2
	ret=$?
	if [[ "$ret" -eq 0 ]]; then
		install_for_wsl2_amd64
	else
		install_for_mac_arm64
	fi
}

main
