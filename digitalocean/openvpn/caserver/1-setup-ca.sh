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

# If there is an original vars file, delete it
rm $WORKING_DIR/EasyRSA-3.0.4/vars_original

# Copy the example config into the original config
cp $WORKING_DIR/EasyRSA-3.0.4/vars.example $WORKING_DIR/EasyRSA-3.0.4/vars_original

cat vars_original | sed 's/California/New York/' | sed 's/My Organizational Unit/repkam09.com/' | \
	sed 's/me@example.net/mark@repkam09.com/' | sed 's/Copyleft Certificate Co/repkam09/' | \
	sed 's/San Francisco/Rochester/' > $WORKING_DIR/EasyRSA-3.0.4/vars

# Cleanup the temporary file and gzip
rm $WORKING_DIR/EasyRSA-3.0.4/vars_original
rm $WORKING_DIR/EasyRSA-3.0.4.tgz


echo Using the following configuration
cat vars | grep "set_var EASYRSA_REQ_"

echo Starting to build PKI and CA working in directory `pwd`
./easyrsa init-pki 
./easyrsa --batch build-ca nopass 


# CA is now ready to accept certs
echo CA is ready to accept certs.