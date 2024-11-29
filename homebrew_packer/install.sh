#! /usr/bin/env bash
dir=$(mount | grep host-shared | xargs | cut -d ' ' -f3)
echo Install oomol ffmpeg package to "$dir"

echo "Download ffmpeg....."
set -ex
wget https://github.com/oomol/builded/releases/download/v1.0/ffmpeg_macos_arm64_ventura.tar.xz --output-document /tmp/ffmpeg.tar.xz >/dev/null 2>&1
tar -xvf /tmp/ffmpeg.tar.xz -C "$dir" >/dev/null 2>&1
rm /tmp/ffmpeg.tar.xz
set -ex

cd "$dir/ffmpeg"
echo Install exec_macos into /usr/bin/exec_macos
set -ex
rm -f /usr/bin/exec_macos
cp exec_macos /usr/bin/exec_macos
chmod +x /usr/bin/exec_macos
chmod +x exec_macos ffmpeg
set -ex

ln -sf "$dir/ffmpeg/ffmpeg" /usr/bin/ffmpeg

echo "Install ffmpeg finished"
