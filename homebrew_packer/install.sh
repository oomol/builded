#! /usr/bin/env bash
dir=$(mount | grep host-shared | xargs | cut -d ' ' -f3)

if [[ -z $dir ]]; then
	echo 'Error: /Users/<UserName>/.oomol-studio/host-shared/tmp dir not find !'
	exit 100
fi

echo Install oomol ffmpeg package to "$dir"

url="https://github.com/oomol/builded/releases/download/v1.1/ffmpeg_macos_arm64_ventura.tar.xz"

if [[ -n $MY_CUSTOM_URL ]];then
	url=$MY_CUSTOM_URL
fi


echo "Download ffmpeg....."
set -ex
wget "$url" --output-document /tmp/ffmpeg.tar.xz
rm -rf $dir/ffmpeg
tar -xvf /tmp/ffmpeg.tar.xz -C "$dir" >/dev/null
rm /tmp/ffmpeg.tar.xz

{
	# Install exec_macos cli tool
	cd "$dir/ffmpeg"
	rm -f /usr/bin/exec_macos
	cp exec_macos /usr/bin/exec_macos
	chmod +x /usr/bin/exec_macos
	chmod +x $dir/ffmpeg/caller.sh
}

{
	# generate the caller into /usr/local/bin
	set +x
	bin_list="aviocat crypto_bench cws2fws enc_recon_frame_test enum_options ffescape ffeval ffhash ffmpeg ffplay ffprobe fourcc2pixfmt graph2dot ismindex pktdumper probetest qt-faststart scale_slice_test seek_print sidxindex trasher uncoded_frame venc_data_dump zmqsend"
	for bin in $bin_list;do
		echo "Generate ffmpeg caller in /usr/bin/$bin"
		echo '#! /usr/bin/env bash' > "/usr/bin/$bin"
		echo "$dir/ffmpeg/caller.sh $bin" '$@' >> "/usr/bin/$bin"
		echo chmod +x "/usr/bin/$bin"
		chmod +x "/usr/bin/$bin"
	done
	
}

set +ex

echo "Install ffmpeg finished"
