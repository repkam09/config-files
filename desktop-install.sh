#!/bin/bash

# install all existing updates
sudo apt-get update
sudo apt-get upgrade

#------------------------------------------------------------------------

# personal software set 
sudo apt-get install i3 suckless-tools curl youtube-dl ffmpeg vlc gparted vim feh arandr build-essential flatpak lxappearance gnome-software-plugin-snap gnome-software-plugin-flatpak network-manager-openvpn network-manager-openvpn-gnome xbacklight htop obs-studio 

#------------------------------------------------------------------------

# Install nodejs LTS
VERSION=node_16.x
DISTRO="$(lsb_release -s -c)"
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
echo "deb https://deb.nodesource.com/$VERSION $DISTRO main" | sudo tee /etc/apt/sources.list.d/nodesource.list
echo "deb-src https://deb.nodesource.com/$VERSION $DISTRO main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list

sudo apt-get update
sudo apt-get install nodejs

#------------------------------------------------------------------------

# remove dunst to use the normal notifyosd
sudo apt-get remove dunst

#------------------------------------------------------------------------

sudo -s -- << EOF
wget -O - https://content.runescape.com/downloads/ubuntu/runescape.gpg.key | apt-key add -
mkdir -p /etc/apt/sources.list.d
echo "deb [arch=amd64] https://content.runescape.com/downloads/ubuntu trusty non-free" > /etc/apt/sources.list.d/runescape.list
apt-get update
apt-get install -y runescape-launcher
EOF

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
