# Audio Convert
1. Docker image packed with audio convert software for VOIP, general audio convert, etc.
2. Scripts for related tasks.

## Components
### Converter
- astconv
- ffmpeg
- sox

## Commands
Build docker image:
```
docker build \
  --no-cache \
  --pull \
  -t audio-convert .
```

Save docker image: `docker save audio-convert | gzip > audio-convert.tar.gz`

## References
- https://github.com/arkadijs/asterisk-g72x
- http://asterisk.hosting.lv/#bin
- https://github.com/linuxserver/docker-ffmpeg/blob/master/Dockerfile
- https://www.innovaphone.com/en/services/support/convert.html
- https://community.asterisk.org/t/asterisk-with-g729-codec/88582
