#!/bin/bash
sudo apt update
sudo apt install openvpn

echo Configuring openvnpn server
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
sudo gzip -d /etc/openvpn/server.conf.gz
mv server.conf server.conf.orig

cat /etc/openvpn/server.conf.orig | sed 's/;tls-auth ta.key 0/tls-auth ta.key 0/' | \                         sed 's/tls-auth ta.key 0/tls-auth ta.key 0 \\\nkey-direction 0\\\n/' | \                              sed 's/cipher AES-256-CBC/cipher AES-256-CBC\\\nauth SHA256/' | \                                     sed 's/;user /user /' | \                                                                             sed 's/;group /group /'


exit

wget -P ~/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.4/EasyRSA-3.0.4.tgz
cd ~
tar xvf EasyRSA-3.0.4.tgz

cd EasyRSA-3.0.4/
./easyrsa init-pki
./easyrsa gen-req server nopass

sudo cp ~/EasyRSA-3.0.4/pki/private/server.key /etc/openvpn/

echo Copying server.req to CA server...
scp ~/EasyRSA-3.0.4/pki/reqs/server.req mark@repkam09.com:/tmp


echo Wait here until processing is finished on CA server...
read -p "Press enter to continue"

sudo cp /tmp/{server.crt,ca.crt} /etc/openvpn/
cd EasyRSA-3.0.4/
./easyrsa gen-dh

openvpn --genkey --secret ta.key

sudo cp ~/EasyRSA-3.0.4/ta.key /etc/openvpn/
sudo cp ~/EasyRSA-3.0.4/pki/dh.pem /etc/openvpn/

mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs
cd ~/EasyRSA-3.0.4/


echo Server is ready to create client certs




