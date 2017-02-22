#!/bin/bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'

# Open or create a ~/.profile file and add this line:
# export PATH=~/.npm-global/bin:$PATH
# source ~/.profile


# NPM_CONFIG_PREFIX=~/.npm-global

