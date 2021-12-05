#!/bin/bash

set -x

# When LOAD_AVERAGE drops below x after 15 minutes,
# and the system has been up for more than 10 minutes,
# self destruct this server. The load average
# is taken from the third field of /proc/loadavg
# which is the average load over 15 minutes.
# For better metrics see
# https://www.brendangregg.com/blog/2017-08-08/linux-load-averages.html

MIN_UPTIME_BEFORE_SELF_DESTRUCT_SECS=600

if test $(cut -d '.' -f1 /proc/uptime) -lt $MIN_UPTIME_BEFORE_SELF_DESTRUCT_SECS; then
  echo "Refusing to self destruct because system uptime less than $MIN_UPTIME_BEFORE_SELF_DESTRUCT_SECS"
  exit 0
fi

LOAD_AVERAGE=$(cat /proc/loadavg | cut -d' ' -f 3)

if [[ $(bc <<< "$LOAD_AVERAGE < 0.01") -eq 1 ]]; then
  /root/hetzner/hetzner-self-destruct.sh
else
  echo System under load $LOAD_AVERAGE, refusing to self-destruct
fi

