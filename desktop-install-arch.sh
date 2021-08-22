#!/bin/bash

# install all existing updates
sudo pacman -Syu 

#------------------------------------------------------------------------

# personal software set
sudo pacman -Sy i3-wm dmenu i3status feh vlc vim gparted ffmpeg youtube-dl curl arandr 

#------------------------------------------------------------------------

# Configure Git globally
git config --global user.name "Mark Repka"
git config --global user.email "mark@repkam09.com"
git config --global core.editor nano 
git config --global init.defaultBranch main

git config --list

#------------------------------------------------------------------------

# Add helper programs into the local bin
chmod +x ./bin/*
cp ./bin/* ~/.local/bin/

echo "Make sure to add  ~/.local/bin/ to your PATH"
