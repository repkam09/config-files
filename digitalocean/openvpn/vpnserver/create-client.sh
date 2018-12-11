#!/bin/bash

mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs

echo Enter the name of the client cert to create:
read clientname


cd ~/EasyRSA-3.0.4/
./easyrsa gen-req $clientname nopass


cp pki/private/$clientname.key ~/client-configs/keys/
scp pki/reqs/$clientname.req mark@repkam09.com:/tmp

echo Wait here until processing is finished on CA server...
read -p "Press enter to continue"

cp /tmp/$clientname.crt ~/client-configs/keys/
cp EasyRSA-3.0.4/ta.key ~/client-configs/keys/
sudo cp /etc/openvpn/ca.crt ~/client-configs/keys/



