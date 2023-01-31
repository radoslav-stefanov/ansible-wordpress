#!/bin/bash

# Wait randomly between 1 to 300 seconds.
sleep $[ ( $RANDOM % 300 )  + 1 ]s

for d in $DOMAINS; do
  if /usr/bin/wget -q -O - http://"{{ wp_host }}"/wp-cron.php?doing_wp_cron > /proc/1/fd/1 2>/proc/1/fd/2; then
    /bin/echo "wordpress cronjob for $d ok"
  else
    /bin/echo "wordpress cronjob for $d error"
  fi
done
