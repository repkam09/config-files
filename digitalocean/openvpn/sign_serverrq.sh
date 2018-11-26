#!/bin/bash
cd EasyRSA-3.0.4/
./easyrsa import-req /tmp/server.req server
./easyrsa sign-req server server

echo Finished, transferring files back to vpn server
scp pki/issued/server.crt mark@vpn.repkam09.com:/tmp
scp pki/ca.crt mark@vpn.repkam09.com:/tmp


