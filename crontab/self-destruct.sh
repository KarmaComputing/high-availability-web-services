#!/bin/bash

# When LOAD_AVERAGE drops below x after 15 minutes,
# self destruct this server. The load average
# is taken from the third field of /proc/loadavg
# which is the average load over 15 minutes.
# For better metrics see
# https://www.brendangregg.com/blog/2017-08-08/linux-load-averages.html

LOAD_AVERAGE=$(cat /proc/loadavg | cut -d' ' -f 3)

if [[ $(bc <<< "$LOAD_AVERAGE < 0.05") -eq 1 ]]; then
  /root/hetzner/hetzner-self-destruct.sh
else
  echo System under load $LOAD_AVERAGE, refusing to self-destruct
fi

