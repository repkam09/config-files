#!/bin/bash


wget -q -P ~/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.4/EasyRSA-3.0.4.tgz

cd ~

tar xf EasyRSA-3.0.4.tgz

cd ~/EasyRSA-3.0.4/



cp vars.example vars_original

cat vars_original | sed 's/California/New York/' | sed 's/My Organizational Unit/repkam09.com/' | \
	sed 's/me@example.net/mark@repkam09.com/' | sed 's/Copyleft Certificate Co/repkam09/' | \
	sed 's/San Francisco/Rochester/' > vars

rm vars_original
rm ~/EasyRSA-3.0.4.tgz

echo Using the following configuration
cat vars | grep "set_var EASYRSA_REQ_"



./easyrsa init-pki 
./easyrsa build-ca nopass 



