#!/bin/sh
service lighttpd stop  # stop lighttpd to renew certs

if ! ./letsencrypt/letsencrypt-auto certonly -tvv --standalone --keep -d repkam09.com -d www.repkam09.com > /var/log/letsencrypt/renew.log 2>&1 ; then
    echo Automated renewal failed:
    cat /var/log/letsencrypt/renew.log
    exit 1
fi
echo Automated renewal complete!
cat /var/log/letsencrypt/renew.log

cd /etc/letsencrypt/live/www.repkam09.com/
cat privkey.pem cert.pem > ssl.pem

echo Copying privkey and cert into ssl.pem for lighttpd setup
service lighttpd start # start lighttpd to renew certs
