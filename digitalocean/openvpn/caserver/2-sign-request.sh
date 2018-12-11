#!/bin/bash

# Set a working directory for temp files
WORKING_DIR=/home/mark/.repka/openvpn

# Switch to the working directory
cd $WORKING_DIR/EasyRSA-3.0.4/
echo Working in directory `pwd`

echo Verify that server.req file exists in /tmp/server.req
read -p "Press enter to continue"

./easyrsa import-req /tmp/server.req server
./easyrsa sign-req server server

echo Finished, transferring files back to vpn server
scp pki/issued/server.crt mark@vpn.repkam09.com:/tmp
scp pki/ca.crt mark@vpn.repkam09.com:/tmp