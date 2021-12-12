# High availability hosting / What does this do?

See design goals

This demo currently deploys two different websites (app1 , app2) both of them have their own database, they are replicated across as few or as many servers as you wish (at least 3 recommended). 

There's much talk about high availability, cross region, failover etc often associated with popular cloud providers.

We don't like having to look after individual servers- the idea here is that any server can go offline (even intermittently- which is more complex to deal with) yet the (web) application *and* persistent store (database) stay online and remain able to be in a consistent state.

This repo is a proof of concept high availability web services using only standard protocols and open software.
Meaning, this works across any provider (and this is encouraged).

## Design goals

- [x] Randomly reboot any server and nothing breaks
- We can add/destroy nodes at any time, even stateful ones
- We can re-create the entire deployment in the event of disaster via a mostly automated process
- The number of different technologies needed to deploy is kept to a minimum
- Cost: Total cost of ownership is low as possible (let's make high availability a standard deployment model)
- Use open source libre software
- Host many python web apps (e.g. flask, django etc)


## How does it work?

[Video how it works](https://youtu.be/N4IZEuBeEt0)

It relies heavily on:

- Round robin DNS 
- uwsgi with fastrouter and subscription-server feature
- TiDB for the database
- etcd to store and distribute letsencrypt keys
- Nodes self destruct if their load is below a threshold after 15 minutes. Checked every x minutes.


#### I thought round-robin dns was a bad idea for high availability?

So did we, and it still might be for your use case.
Modern browsers (even `curl`) have become better at retrying when multiple DNS A records are available, and a connection to a record fails, the next will be attempted*. At the web application layer, single page applications, though not required for this, are also resilient to ip address rotation (if coded with retries). 

* *Note*: Typically a web browser (user agent) will only consider a server down if it cannot open a TCP connection to it. If your web app is down (e.g. returning a 500) then round robin DNS still won't help you, because as far as the web browser is concerned, the destination is online. 

To handle that, we monitor at the DNS level to remove dead endpoints, and lean on `uwsgi` fast router and `subscription-server` to route to online apps to mitigate this. Uwsgi's subscription-server and fastrouter featuers also help mitigate another down-side of round-robin DNS, since there's limited loadbalancing (round-robin DNS is not aware of the destinations current CPU load, for example), but with uwsgi , its fastrouter component helps by loadbalancing requests to other servers so that the node presented by DNS is not bearing all the *application* load.


## Setup

> Note: All scripts must be ran from the root of this repo.
  don't `cd` into the dir and run from a subdirectory

## Setup (~automated) Day 0

- Creates servers
- Configures DNS
- Installs web & database across all servers
```
# Deploy database (tidb)
./provision-database.sh
# Deploy web stack (apache & uwsgi)
./day0.sh <domain> <number-of-servers> <percent-at-once>
# e.g. ./day0.sh example.com 3 1 # means deploy 3 servers, all at once (100% in parallel)
# Note: It takes about 10 minutes to complete 5 servers
```

## Destroy everything
```
./destroy-all.sh
```

## Day 2
`day2.sh` will take a % of servers offline by rebooting,
renewing certs. The default is 50%
```
./day2.sh <percentage to take offline at once>
# e.g. ./day2.sh 0.25  # take 25% offline at a time
```


## Setup (menual without day0.sh)

### DNS

> You don't need to do this manually if using CloudNS, it's been
automated for you. You do need to populate `.env.` (see `.env.example`
with your api key).

1. Choose a domain name to deploy to
2. Add a duplicate wildcard `A` record for each server
   e.g. if your domain is example.com, and you have three
   servers, then create three wildcard entries:

   ```
   A *.example.com IN 10.0.0.1
   A *.example.com IN 10.0.0.2
   A *.example.com IN 10.0.0.3
   ```
   This will allo you to create many apps, e.g.
   app1.example.com
   app2.example.com
   app-whatever.example.com ... etc

   and they will all be routed to one of the available
   servers by round-robin DNS.
3. Set DNS healthchecks for TCP port 443 on every A records, and set to remove record if failed, add back if healthcheck successful see https://www.cloudns.net/wiki/article/271/

## How day0 works (overview)

1. Creates `n` ubuntu servers (e.g. 3 of them- they must be ubuntu)
2. Puts the ip address of every server in `servers.txt` one on each line
3. Runs the `provision.sh` script:
  ```
  ./provision.sh
  ```
6. Check https://app1.<example.co.uk>  in your web browser
7. Not working? Check your DNS healthchecks, are they all failing? If yes, check one/all of the servers to see why none of them are succesful with the healthcheck

Read the script to see what it does, it basically:

- Installs apache, uwsgi
- Copies over example app1 and app2
- Creates certificates (certbot)
- Starts apache & uwsgi

- *Note* Setting up and installing TiDB cluster is not automated yet.



## Test it
```
watch 'curl -s --head  -w "http_code: %{http_code} from remote_ip: %{remote_ip}"  http://app1.duplicate.pcpink.co.uk/'
```

## Debugging tools / commands

Show me etcd status
- `etcdctl endpoint status --cluster -w table`
- `etcdctl endpoint status` # just current node
- `etcdctl endpoint status -w json` # give me json

Am I the leader? / Is this node the current etcd leader
- am-i-the-leader.sh

## Database

```
mysql -h 127.0.0.1 -P 4000 -p
mysql> create database app1;
Query OK, 0 rows affected (0.40 sec)

mysql> create database app2;
```

pool recycle
https://stackoverflow.com/a/57262814/885983


## Benchmarks / Load testing

[Video benchmark how to + cost analysis](https://youtu.be/N4IZEuBeEt0)

With apache bench, its possible to set the `Host` head to ensure you're targeting all possible endpoints
one by one. You would want to do this, to be in control / bypass the round-robin DNS to be sure 
you're targeting all nodes at once to simulate that.

e.g. if you have three servers deployed:

```
ab -n 1000000 -c 60 -H "Host: app1.jtkarma.co.uk" https://168.119.231.40/
```
Server 2:
```
ab -n 1000000 -c 60 -H "Host: app1.jtkarma.co.uk" https://23.88.97.119/
```
Server 3:
```
ab -n 10000 -c 60 -H "Host: app1.jtkarma.co.uk" https://23.88.101.53/
```

Remember that uwsgi fastrouter will loadbalance between nodes, so even if apache bench (`ab`)
has finished against one node, you will see load on all servers still because uwsgi will be 
balancing connections across all possible nodes ('full mesh').

## The many ways this can fail

- If apache cannot contact the target proxied destination, it will return a 500 and the end user will see that


# links

https://stackoverflow.com/a/43267603/885983
https://docs.edgecast.com/dns/Content/Route/Tutorials/Load_Balancing_CNAME_Creation.htm
https://superuser.com/questions/968561/how-to-get-the-machine-ip-address-in-a-systemd-service-file
https://unix.stackexchange.com/a/167040
https://www.reddit.com/r/shortcuts/comments/9u57kr/comment/e91ogm4/?utm_source=share&utm_medium=web2x&context=3
https://askubuntu.com/questions/77352/need-help-with-bash-checking-if-computer-uptime-is-greater-than-5-minutes
https://unix.stackexchange.com/questions/87405/how-can-i-execute-local-script-on-remote-machine-and-include-arguments
