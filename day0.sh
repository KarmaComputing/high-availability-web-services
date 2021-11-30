./hetzner/hetzner-create-n-servers.sh 3
cp servers.txt servers.bk
./hetzner/hetzner-get-all-servers-ip-public-net.sh > servers.txt
./dns/create-all-wildcards.sh
sleep 60 # wait for servers to boot
./provision.sh
