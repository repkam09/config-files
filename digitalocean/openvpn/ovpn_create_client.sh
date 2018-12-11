mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs

cd ~/EasyRSA-3.0.4/
./easyrsa gen-req client1 nopass

cp pki/private/client1.key ~/client-configs/keys/

scp pki/reqs/client1.req mark@repkam09.com:/tmp

echo Wait here until processing is finished on CA server...
read -p "Press enter to continue"

cp /tmp/client1.crt ~/client-configs/keys/

cp ~/EasyRSA-3.0.4/ta.key ~/client-configs/keys/
sudo cp /etc/openvpn/ca.crt ~/client-configs/keys/



