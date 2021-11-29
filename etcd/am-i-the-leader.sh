#!/bin/bash

# Return 0 (true) if the server is the etcd/raft elected learder
# Return 255 (false) if the server it not the etcd/raft current leader
  
set -x 

function isLeader {
    IS_LEADER=$(ETCDCTL_API=3 etcdctl endpoint status | cut -d ',' -f 5 | xargs echo -n)

    if [ $IS_LEADER == "false" ]
    then
       echo false
       return 1
    fi

    if [ $IS_LEADER == "true" ]
    then
       echo true
       return 0
    fi

    return 255
}

isLeader
