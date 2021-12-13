#!/bin/bash

# Generates TiDB topology yaml
# See https://docs.pingcap.com/tidb/v5.3/hybrid-deployment-topology

DB_SERVERS=$(cat ./db-servers.txt)

function list_first_server {
  FIRST_SERVER=$(sed -n 1p ./db-servers.txt)
echo "  - host: $FIRST_SERVER"
}

function list_servers {
for DB_SERVER in $DB_SERVERS
do
echo "  - host: $DB_SERVER"
done
}

echo "global:"
echo "  user: 'tidb'"
echo "  ssh_port: 22"
echo "  deploy_dir: '/mnt/data1/tidb-deploy'"
echo "  data_dir: '/mnt/data1/tidb-data'"
echo "server_configs: {}"
echo "pd_servers:"
list_servers
echo
echo "tidb_servers:"
list_servers
echo "tikv_servers:"
list_servers
echo "monitoring_servers:"
list_first_server
echo "grafana_servers:"
list_first_server
echo "alertmanager_servers:"
list_first_server
