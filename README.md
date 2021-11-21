# High availability hosting / What does this do?

There's much talk about high availability, cross region, failover etc.

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


## Deploy
```
./provision.sh
```

## DNS

> already issued for this exact set of domains in the last 168 hours

```
```


## Test it
```
watch 'curl -s --head  -w "http_code: %{http_code} from remote_ip: %{remote_ip}"  http://app1.duplicate.pcpink.co.uk/'
```

## Database

```
mysql -h 127.0.0.1 -P 4000 -p
mysql> create database app1;
Query OK, 0 rows affected (0.40 sec)

mysql> create database app2;
```

pool recycle
https://stackoverflow.com/a/57262814/885983
