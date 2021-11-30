./hetzner/hetzner-create-n-servers.sh 3
cp servers.txt servers.bk
./hetzner/hetzner-get-all-servers-ip-public-net.sh > servers.txt
./dns/create-all-wildcards.sh
./provision.sh
