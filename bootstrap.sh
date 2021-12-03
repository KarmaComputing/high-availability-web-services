#!/bin/bash

set -x

ETCD_DISCOVERY=$1
DOMAIN=$2
CLOUDNS_AUTH_ID=$3
CLOUDNS_AUTH_PASSWORD=$4


apt-get update
apt-get install -y apache2 python3.8 python3.8-venv python3.8-dev build-essential libpcre3 libpcre3-dev snapd cifs-utils linux-generic

mv whats-my-ip.sh /usr/local/bin


#Acme
curl https://get.acme.sh | sh -s email=oss@karmacomputing.co.uk



# etcd
PUBLIC_IP=$(whats-my-ip.sh)

ETCD_VER=v3.5.1
rm -rf /etc/etcd && mkdir -p /etc/etcd
echo -n $ETCD_DISCOVERY > /etc/etcd/ETCD_DISCOVERY_URL
cat /etc/etcd/ETCD_DISCOVERY_URL

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
DOWNLOAD_URL=${GOOGLE_URL}

rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test
rm -rf /var/lib/etcd && mkdir /var/lib/etcd

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

/tmp/etcd-download-test/etcd --version
/tmp/etcd-download-test/etcdctl version
/tmp/etcd-download-test/etcdutl version
mv /tmp/etcd-download-test/etcd* /usr/local/bin/
rm -rf /tmp/etcd-download-test/

mv etcd/etcd.service /etc/systemd/system/etcd.service
mv /root/etcd/* /usr/local/bin/ # Copies am-i-the-leader.sh utility

systemctl daemon-reload
systemctl enable etcd.service # start at reboot

# Apache
a2enmod proxy proxy_http proxy_uwsgi rewrite headers ssl
systemctl restart apache2
mv apache2/uwsgi.conf /etc/apache2/sites-available/uwsgi.conf
mv apache2/uwsgi-ssl.conf /etc/apache2/sites-available/uwsgi-ssl.conf
a2dissite 000-default.conf
a2ensite uwsgi
systemctl reload apache2


python3.8 -m venv venv
. venv/bin/activate
pip install wheel
pip install uWSGI==2.0.20
uwsgi --version
mv /root/venv/bin/uwsgi /usr/local/bin || true

mkdir -p /etc/uwsgi/vassals
rm -rf /etc/uwsgi/vassals/*

cp -r --preserve=mode,timestamps uwsgi/emperor.ini /etc/uwsgi
cp -r --preserve=mode,timestamps uwsgi/uwsgi.service /etc/systemd/system/
cp uwsgi/generate-uwsgi-subscription-config.sh /etc/uwsgi
/etc/uwsgi/generate-uwsgi-subscription-config.sh > /etc/uwsgi/subscriptions.ini

rm -rf /etc/uwsgi/venvs/*
mkdir -p /etc/uwsgi/venvs/app{1,2}
python3.8 -m venv /etc/uwsgi/venvs/app{1,2}/venv


# Place vassals
cp -r --preserve=mode,timestamps uwsgi/vassals/* /etc/uwsgi/vassals/

. /etc/uwsgi/venvs/app1/venv/bin/activate 
pip install -r /etc/uwsgi/vassals/app1/requirements.txt
deactivate
. /etc/uwsgi/venvs/app2/venv/bin/activate
pip install -r /etc/uwsgi/vassals/app2/requirements.txt
deactivate

rm -r uwsgi

systemctl daemon-reload
systemctl status uwsgi.service
systemctl start uwsgi.service
systemctl restart uwsgi.service
systemctl enable uwsgi.service
systemctl status uwsgi.service
