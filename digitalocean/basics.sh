#!/bin/bash

USERNAME=mark

# Set up user account if it does not exist
if [ ! -d "/home/$USERNAME" ]
then
	echo Setting up user $USERNAME
	adduser --disabled-password --quiet --gecos "" $USERNAME
	adduser $USERNAME sudo
else
	echo Skipping user creationg because $USERNAME exists
fi


# Set up ssh keys if they do not exist
if [ ! -d "/home/$USERNAME/.ssh" ]
then
	mkdir -p /home/$USERNAME/.ssh/
	cp ~/.ssh/authorized_keys /home/$USERNAME/.ssh/authorized_keys
	chown $USERNAME:$USERNAME /home/$USERNAME/.ssh/
	chown $USERNAME:$USERNAME /home/$USERNAME/.ssh/authorized_keys
else
	echo Skipping ssh key copy as .ssh already exists
fi

echo Running apt updates
apt update
apt upgrade

echo Installing helpful tools...
apt install tmux screen git





