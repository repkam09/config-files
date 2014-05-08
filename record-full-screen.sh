#! /bin/bash

# Using this config values, record the x11 desktop to a file using FFMPEG
INRES="1366x768"             # input resolution
OUTRES="1366x768"             # Output resolution
FPS="30"                     # target FPS
QUAL="medium"                # one of the many FFMPEG presets
VIDEO_NAME="`date`.mkv"
PIP_VIDEO="webcam.avi"
sleep 5

ffmpeg \
	-f x11grab -s $INRES  -r "$FPS" -i :0.0 \
	-f alsa -ac 2 -i pulse  \
	-vcodec libx264 -s $OUTRES -preset $QUAL -g 250 \
	-acodec libmp3lame -ab 128k -ar 44100 -threads 4 \
	"$VIDEO_NAME"
