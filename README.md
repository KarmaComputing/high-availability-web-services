# High availability hosting / What does this do?

This demo currently deploys two different websites (app1 , app2) both of them have their own database, they are replicated across 5 servers. 

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

It relies heavily on:

- Round robin DNS 
- uwsgi with fastrouter and subscription-server feature
- TiDB for the database
- etcd to store and distribute letsencrypt keys


#### I thought round-robin dns was a bad idea for high availability?

So did we, and it still might be for your use case.
Modern browsers (even `curl`) have become better at retrying when multiple DNS A records are available. 

*Note*: This is only based on if a TCP connection can be made by the browser- if your web app is down (e.g. returning a 500) then round robin DNS still won't help you, because as far as the web browser is concerned, the destination is online. To handle that, we can either use programatic DNS to remove dead endpoints, or (what we propose) lean on `uwsgi` fast router and `subscription-server` to route to online apps to mitigate this. This also helps with another down-side of round-robin DNS, since there's limited loadbalancing (a DNS nameserver is not aware of the destinations current CPU load, for example), but if using uwsgi , the fastrouter may help loadbalancing so that the node presented by DNS is not bearing all the *application* load.


## Setup

Set your domain
```
./rename-domain.sh example.com <your-domain>
# e.g.
./rename-domain.sh example.com google.com
```

Set DNS API username/password
```

```

## Deploy

1. Create `n` ubuntu servers (e.g. 3 of them- they must be ubuntu)
2. Make sure you can ssh to all of them
3. Put the ip address of every server in `servers.txt` one on each line
4. Run the `provision.sh` script:
  ```
  ./provision.sh
  ```

Read the script to see what it does, it basically:

- Installs apache, uwsgi
- Copies over example app1 and app2
- Creates certificates (certbot)
- Starts apache & uwsgi

- *Note* Setting up and installing TiDB cluster is not automated yet.

## DNS

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


Note, if you have more than 5 nodes, during deployment certbot will fail on the 6th because you're not allowed to get more than 5 certificates within 168 hours (unless that's changed?):
> already issued for this exact set of domains in the last 168 hours


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

## The many ways this can fail

- If apache cannot contact the target proxied destination, it will return a 500 and the end user will see that


# links

https://stackoverflow.com/a/43267603/885983
https://docs.edgecast.com/dns/Content/Route/Tutorials/Load_Balancing_CNAME_Creation.htm
https://superuser.com/questions/968561/how-to-get-the-machine-ip-address-in-a-systemd-service-file
https://unix.stackexchange.com/a/167040
