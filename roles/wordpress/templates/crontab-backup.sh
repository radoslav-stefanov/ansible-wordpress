#!/bin/bash

### Theory of operation (abstract)
# Designed to be executed as a daily cron job.
# Backup database and filesystem.
# Create full database backup each day.
# Create incremental filesystem backup each day. Store up to 3 incremental backups and 1 full backup.
# It expects a dedicated backup volume mounted at $backup_volume directory.
# Just common Linux tools dependancies (nfs client, docker, tar, gzip, rsync and cp).
# Script itself is partially generated using Ansible automation, so it can be deployed on multiple systems faster.

### TODO
# Add error handling.
# Add support for email report on error.

### Process of execution
# 1. Export database.
# 2. Archive it.
# 3. Create incremental filesystem backup.
# 4. Cleanup leftovers.

# Wait randomly between 1 to 300 seconds.
sleep $[ ( $RANDOM % 300 )  + 1 ]s

# Run for the following websites. Generated by Ansible.
websites="{{ domain }}"

# Config variables
backup_volume="/mnt/backups"
yesterday="$(date -d 'yesterday' +'%F')"
system_dirs="content database"

# Execute for each website
for w in $websites; do
  # Replace dashes with underscore
  container=$(echo ${w//[.-]/_})

  # Figure out website owner
  get_user=$(docker container run --name=backup_"$container" --user=xfs -v /srv/www/"$w"/www_data:/var/www/html:rw --rm wordpress:cli /bin/sh -c 'stat -c %U wp-login.php')
  # Generate env file
  docker exec -it $container env | grep WORDPRESS > /tmp/$container
  # Export database
  docker container run --env-file /tmp/$container --name=backup_"$container" --user="$get_user" --network="$container" -v /srv/www/"$w"/www_data:/var/www/html:rw --rm wordpress:cli /bin/sh -c 'wp db export --quiet --add-drop-table .backup.sql'

  # Create system directories
  for dir in $system_dirs; do
    if [ ! -d $backup_volume/$w/$dir ]; then
      mkdir -p $backup_volume/$w/$dir
    fi
  done

  # Backup database
  cd $backup_volume/$w/database
  mv /srv/www/"$w"/www_data/.backup.sql .
  tar -czvf "$yesterday"_mysql_backup.tar.gz .backup.sql

  # Backup filesystem
  if [ -d $backup_volume/$w/content/daily.3 ] ; then
    rm -rf $backup_volume/$w/content/daily.3
  fi
  if [ -d $backup_volume/$w/content/daily.2 ] ; then
    mv $backup_volume/$w/content/daily.2 $backup_volume/$w/content/daily.3
  fi
  if [ -d $backup_volume/$w/content/daily.1 ]; then
    mv $backup_volume/$w/content/daily.1 $backup_volume/$w/content/daily.2
  fi
  if [ -d $backup_volume/$w/content/daily.0 ] ; then
    cp -al $backup_volume/$w/content/daily.0 $backup_volume/$w/content/daily.1
  fi

  rsync -aq --delete /srv/www/$w/www_data/ backups:/home/backups/$w/content/daily.0/

  # Cleanup any leftover, just in case.
  rm -rf /srv/www/"$w"/www_data/*.sql
  rm -rf /tmp/$container
done
