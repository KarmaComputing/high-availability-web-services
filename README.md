# High availability uwsgi wsgi hosting

- Randomly reboot any server and nothing breaks

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
