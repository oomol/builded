# packer.sh
Analyze the binaries and dependencies in Homebrew, pull the binaries and libraries, generate a runner script which used to launch the target binary.

## Usage
Export ffmpeg package from homebrew

```sh
brew install ffmpeg
./packer.sh ffmpeg
```
the ffmpeg.tar.xz will be `/tmp/ffmpeg.tar.xz`
