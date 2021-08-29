#!/bin/bash
BASE=`echo "$(lsb_release -is)"`

if [ $BASE == "Ubuntu" ]
then
bash ./base/ubuntu.sh
fi


if [ $BASE == "Manjaro" ]
then
bash ./base/arch.sh
fi

# Configure Git globally
git config --global user.name "Mark Repka"
git config --global user.email "mark@repkam09.com"
git config --global core.editor nano 
git config --global init.defaultBranch main

git config --list

#------------------------------------------------------------------------

# Add helper programs into the local bin
mkdir -p ~/.local/bin/
chmod +x ./bin/*
cp ./bin/* ~/.local/bin/

echo "Make sure to add  ~/.local/bin/ to your PATH"
