#!/bin/bash
# runescape client
sudo add-apt-repository ppa:hikariknight/unix-runescape-client

# install all existing updates
sudo apt-get update
sudo apt-get upgrade

# personal desktop specific files
sudo apt-get install i3 suckless-tools curl youtube-dl ffmpeg vlc gparted vim feh openjdk-8-jre git htop runescape consolekit

# remove dunst to use the normal notifyosd
sudo apt-get remove dunst

# required for Steam
sudo apt-get install libgl1-mesa-dri:i386, libgl1-mesa-glx:i386, libc6:i386
