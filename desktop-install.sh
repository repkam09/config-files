#!/bin/bash

# install all existing updates
sudo apt-get update
sudo apt-get upgrade

# personal desktop specific files
sudo apt-get install i3 suckless-tools curl youtube-dl ffmpeg vlc gparted vim feh arandr build-essential flatpak lxappearance gnome-software-plugin-snap gnome-software-plugin-flatpak network-manager-openvpn network-manager-openvpn-gnome xbacklight

# Install nodejs LTS
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -

# Replace with the branch of Node.js or io.js you want to install: node_6.x, node_8.x, etc...
VERSION=node_16.x
DISTRO="$(lsb_release -s -c)"

echo "deb https://deb.nodesource.com/$VERSION $DISTRO main" | sudo tee /etc/apt/sources.list.d/nodesource.list
echo "deb-src https://deb.nodesource.com/$VERSION $DISTRO main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list

sudo apt-get update
sudo apt-get install nodejs

# remove dunst to use the normal notifyosd
sudo apt-get remove dunst


# Add helper programs into the local bin
chmod +x ./bin/*
cp ./bin/* ~/.local/bin/

echo "Make sure to add  ~/.local/bin/ to your PATH"
