# Video transition with GPU(M1) acceleration

## Apple VideoToolbox

```
ffmpeg -y -hwaccel videotoolbox \
    -i /oomol-driver/oomol-storage/1.mp4  \
    -c:v h264_videotoolbox \
    -profile main -b:v 500 \
    -c:a copy -vf subtitles=/oomol-driver/oomol-storage/1.srt  \
    -f mp4 /oomol-driver/oomol-storage/out.mp4
```

# Whisper test case

## Save audio from mp4

```
ffmpeg -y  -i /oomol-driver/oomol-storage/1.mp4   -q:a 0 -map a  /oomol-driver/oomol-storage/1.mp3
```
## Using whisper python bind

```
import whisper  
model = whisper.load_model("turbo")    
result = model.transcribe("/oomol-driver/oomol-storage/1.mp3")
print(result["text"])    
```


# ffmpeg logs

In macOS host
```
$ cat /Users/<USER_NAME>/.oomol-studio/host-shared/ffmpeg/exec_log
```
