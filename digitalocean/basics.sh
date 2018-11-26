#!/bin/bash

USERNAME=mark

echo Setting up user $USERNAME

# adduser --disabled-password --gecos "" username
adduser --disabled-password --quiet --gecos "" $USERNAME
adduser $USERNAME sudo

mkdir -p /home/$USERNAME/.ssh/
cp ~/.ssh/authorized_keys /home/$USERNAME/.ssh/authorized_keys
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh/
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh/authorized_keys

apt update
apt upgrade
apt install tmux screen git


echo You should now be able to log on via SSH rsa key as $USERNAME



