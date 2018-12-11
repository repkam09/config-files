#!/bin/bash

# Set a working directory for temp files
WORKING_DIR=/home/mark/.repka/openvpn


# Clean the working directory
rm -rf $WORKING_DIR/

# Create a CA working directory
mkdir -p $WORKING_DIR/


# Switch to the working directory
cd $WORKING_DIR
pwd


# To begin building the CA and PKI infrastructure, install the latest version of EasyRSA from 
# the official GitHub project on both your CA machine and your OpenVPN server with the following command:

wget -q -P $WORKING_DIR/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.4/EasyRSA-3.0.4.tgz

# Extract the targz
tar xf EasyRSA-3.0.4.tgz

# Switch into the new folder
cd $WORKING_DIR/EasyRSA-3.0.4/
pwd

echo Starting to build PKI in directory `pwd`
./easyrsa init-pki 
./easyrsa gen-req server nopass

echo Inserting new server.key into /etc/openvpn
sudo rm /etc/openvpn/server.key
sudo cp $WORKING_DIR/EasyRSA-3.0.4/pki/private/server.key /etc/openvpn/

echo Transferring server.req to CA server... 
scp $WORKING_DIR/EasyRSA-3.0.4/pki/private/server.key mark@repkam09.com:/tmp

echo Once the CA server has signed your request and responded....
read -p "Press enter to continue"


sudo cp /tmp/{server.crt,ca.crt} /etc/openvpn/
cd $WORKING_DIR/EasyRSA-3.0.4/
./easyrsa gen-dh

openvpn --genkey --secret ta.key

sudo cp $WORKING_DIR/EasyRSA-3.0.4/ta.key /etc/openvpn/
sudo cp $WORKING_DIR/EasyRSA-3.0.4/pki/dh.pem /etc/openvpn/

mkdir -p $WORKING_DIR/client-configs/keys
chmod -R 700 $WORKING_DIR/client-configs
cd $WORKING_DIR/EasyRSA-3.0.4/


echo Server is ready to create client certs
