#!/bin/bash

#@@@@ Intended to be run as non-root user @@@@
### !! be sure to have the env variables set in home directory for b2:
# B2_APPLICATION_KEY_ID
# B2_APPLICATION_KEY

# A sync script for the data directory store used for all app data
# This directory is currently at: /mnt/data/ and is a 2TB raid 1 array

log_path="$HOME/logs/b2/"
timestamp=$(date '+%Y-%m-%d--%H-%M-%S')
log_file=data_backup_$timestamp.log
log=$log_path$log_file
backup_retention_days=14
log_retention_days=30

touch $log
echo "Starting backup at $timestamp" >> $log

# Cleanup any psql backups older than given days
echo "Cleaning up old psql backups and sync logs" >> $log
# TODO: List the backups and logs being deleted
find /mnt/data/postgres-data/BACKUPS/ -name "*.sql" -mtime +$backup_retention_days -type f -delete >> $log
find /home/oasis/logs/ -name "*.log" -mtime +$log_retention_days -type f -delete >> $log



# Create a backup of the NC database used for Nextcloud
#   The backup is an .sql file saved to the "BACKUPS" dir of the postgres container data volume
echo "Creating a new NC database backup" >> $log

backupfile="`date +%Y-%m-%d`-NC_backup.sql"
docker exec -it nextcloud_NCDatabase_1 pg_dump -U nextcloud NC > /mnt/data/postgres-data/BACKUPS/$backupfile >> $log

if [ $? ]; then
  echo "Nextcloud database backup successfully created" >> $log
else
  echo "Failed to create nextcloud database backup" >> $log
fi


# sync all needed data to b2 s3-style bucket
echo "syncing all specified data to b2 bucket" >> $log
sync_log=b2-sync-log_$timestamp.log
sync_log_path=$log_path$sync_log
b2 sync /mnt/data b2://sanctuary-data/ --excludeRegex '(^.*postgres-data\/)' --includeRegex '(^.*BACKUPS\/)' >> $sync_log_path

if [ $? ]; then
  rm $sync_log_path >> $log
  echo "$(date +%Y-%m-%d_%H:%M:%S) BACKUP COMPLETED" >> $log
else
  echo "ERROR: Sync to B2 failed, see sync log $sync_log_path" >> $log
fi
