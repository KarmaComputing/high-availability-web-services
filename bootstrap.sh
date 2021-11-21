#!/bin/bash

set -x

apt-get update
apt-get install -y apache2 python3.8 python3.8-venv python3.8-dev build-essential libpcre3 libpcre3-dev snapd

# Apache
a2enmod proxy proxy_http proxy_uwsgi rewrite headers ssl
systemctl restart apache2
mv apache2/uwsgi.conf /etc/apache2/sites-available/uwsgi.conf
mv apache2/uwsgi-ssl.conf /etc/apache2/sites-available/uwsgi-ssl.conf
a2dissite 000-default.conf
a2ensite uwsgi
systemctl reload apache2

# Certbot
snap install core; sudo snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
snap set certbot trust-plugin-with-root=ok
snap install certbot-dns-cloudflare

mkdir -p /etc/cloudflare
mv dns/cloudflare/* /etc/cloudflare/
chmod 600 /etc/cloudflare/*
certbot certonly --agree-tos --dns-cloudflare --dns-cloudflare-credentials /etc/cloudflare/cloudflare.ini --email oss@karmacomputing.co.uk --noninteractive -d *.duplicate.pcpink.co.uk

if [ $? != 0 ]
then
  echo "Failed certbot, skipping enable of tls site"
  a2dissite uwsgi-ssl
  systemctl stop apache2
  systemctl start apache2
else
  echo "Certbot certificate OK"
  a2ensite uwsgi-ssl
fi


systemctl reload apache2


python3.8 -m venv venv
. venv/bin/activate
pip install wheel
pip install uWSGI==2.0.20
uwsgi --version
mv /root/venv/bin/uwsgi /usr/local/bin

mkdir -p /etc/uwsgi/vassals
rm -rf /etc/uwsgi/vassals/*

mv uwsgi/emperor.ini /etc/uwsgi
mv --force uwsgi/vassals/* /etc/uwsgi/vassals/
mv uwsgi/uwsgi.service /etc/systemd/system/

python3.8 -m venv /etc/uwsgi/vassals/app{1,2}/venv
. /etc/uwsgi/vassals/app1/venv/bin/activate
pip install -r /etc/uwsgi/vassals/app1/requirements.txt
. /etc/uwsgi/vassals/app2/venv/bin/activate
pip install -r /etc/uwsgi/vassals/app2/requirements.txt

rm -r uwsgi

systemctl daemon-reload
systemctl status uwsgi.service
systemctl start uwsgi.service
systemctl restart uwsgi.service
systemctl enable uwsgi.service
systemctl status uwsgi.service
