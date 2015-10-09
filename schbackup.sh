#!/bin/bash

#20140508 - Author: J. Sikkema.
#This script performs checking, cleanup, backup and alert functions for a specific scheduled backup solution.

#Weekly backups are to be made every monday and kept for 4 weeks.
#Monthly backups are to be made every 1st day of the month and kept for 3 months.

BACKUP_DIR=/somedir/ 
BACKUP_PATH=/somedir/*
WEEKLY_DIR=/somedir_scheduled_backups/Weekly_backups/
MONTHLY_DIR=/somedir_scheduled_backups/Monthly_backups/
CURR_TIME=$(date +%Y-%m-%d\ %H:%M:%S)
CURR_DATE=$(date "+%Y-%m-%d")
TMPLIST="/var/tmp/backup_$CURR_DATE.tmp"
LISTDIRS=`ls -1d $BACKUP_PATH > $TMPLIST`
QUOTA_CRITICAL=2147483648 #2.0 Terabyte
QUOTA_WARNING=1887436800 #1.8 Terabyte
QUOTA_SETTING="2.0 Terabyte" #Human readable TB format
KEEP_FILE_DAYS='8'
RETURN_MAIL_ADDR="root@somemail.addr"
TO_MAIL_ADDR="recepient@somemail.addr"
MAIL_SUBJECT="Scheduled backup check has encountered a problem!"

#Some files should be checked daily for available backups, and others only on a weekly basis.
daily_regex_array=(
 'daily-staticfilestring1'
 'daily-staticfilestring2'
 'daily-staticfilestring3')
daily_list=$(printf "|/%s" "${daily_regex_array[@]}")
DAILY_BACKUPS=`egrep "$daily_list" "$TMPLIST"`

weekly_regex_array=(
 'weekly-staticfilestring1'
 'weekly-staticfilestring2'
 'weekly-staticfilestring3')
weekly_list=$(printf "|/%s" "${weekly_regex_array[@]}")
WEEKLY_BACKUPS=`egrep "$weekly_list" "$TMPLIST"`

dircheck () {
if [ -d "$1" ]; then
  echo "$CURR_TIME: Directory $1 found" > /dev/null
elif [ $1 -eq $BACKUP_DIR ]; then
  echo "Directory $1 not found! - $CURR_DATE."|mailx -s "Critical $MAIL_SUBJECT" -r $RETURN_MAIL_ADDR $TO_MAIL_ADDR
  logger -i -p user.crit -t schdbackup "Directory $1 not found, exiting.."
  exit 1
else
  echo "Backup directory $1 not found! - $CURR_DATE."|mailx -s "Warning $MAIL_SUBJECT" -r $RETURN_MAIL_ADDR $TO_MAIL_ADDR
  logger -i -p user.warn -t schdbackup "Backup directory $1 not found!.."
fi
}

check_available_backups () {
check_backups=`find $1 -type f -mtime -$2 | wc -l`
dir_count=`ls -d $1 | wc -l`
if [ $check_backups -lt $dir_count ]; then
  print_dir=`tree $BACKUP_PATH | egrep "$3"`
  echo -e "$4 backup check is reporting missing files:  \n$print_dir."|mailx -s "Critical: $MAIL_SUBJECT" -r $RETURN_MAIL_ADDR $TO_MAIL_ADDR
  logger -i -p user.crit -t schdbackup "$4 System backups are missing in directory: $BACKUP_PATH"
fi
}

filebackup () {
for dir in $BACKUP_PATH; do
  backup_file="$(find $dir -type f | sort -rn | head -1)"
    if [ ! -a $backup_file ]; then
      cp -rp $backup_file $1
    else
      unset backup_file
    fi
done
unset backup_file
find $1 -mtime +$2 -exec rm {} \; 2>/dev/null
logger -i -p user.info -t schdbackup "Created backups in $1"
}

dircheck $BACKUP_DIR

dircheck $WEEKLY_DIR

dircheck $MONTHLY_DIR

daily_sgrep=$(printf "|%s" "${daily_regex_array[@]}")
check_available_backups "$DAILY_BACKUPS" "1" "$daily_sgrep" "Daily"

weekly_sgrep=$(printf "|%s" "${weekly_regex_array[@]}")
check_available_backups "$WEEKLY_BACKUPS" "8" "$weekly_sgrep" "Weekly"

listcount=`cat $TMPLIST | wc -l`
arraycount=`egrep "$daily_list$weekly_list" $TMPLIST | wc -l`
if [ $listcount -gt $arraycount ]; then
  getobject=`egrep -v "$daily_list$weekly_list" $TMPLIST`
  echo -e "Scheduled backup has encountered an error: $getobject not embedded in appropiate directory array!"|mailx -s "Warning: $MAIL_SUBJECT" -r $RETURN_MAIL_ADDR $TO_MAIL_ADDR
  logger -i -p user.warn -t schdbackup "$getobject in directory: $BACKUP_PATH not found in directory array."
fi

weekly_backup=`date +%a | grep "Mon" | wc -l`
if [ $weekly_backup -eq 1 ]; then
  filebackup "$WEEKLY_DIR" "30"
fi

monthly_backup=`date +%d | grep "01" | wc -l`
if [ $monthly_backup -eq 1 ]; then
  filebackup "$MONTHLY_DIR" "90"
fi

del_oldfiles=`find $BACKUP_DIR -type f -mtime +$KEEP_FILE_DAYS | wc -l`
if [ $del_oldfiles -ge 1 ]; then
  find $BACKUP_DIR* -type f -mtime +$KEEP_FILE_DAYS -exec rm {} \; 2>/dev/null
  echo "$CURR_TIME: Files older then $KEEP_FILE_DAYS days in $BACKUP_DIR deleted." > /dev/null
fi

check_quota=`du -sk $BACKUP_DIR | awk '{print $1}'`
if [ $check_quota -lt $QUOTA_WARNING ]; then
  echo "$CURR_TIME: Directory usage within quota limits." > /dev/null
elif [ $check_quota -gt $QUOTA_CRITICAL ]; then
  echo "Directory $BACKUP_DIR quota limit of $QUOTA_SETTING exceeded!"|mailx -s "Critical: $MAIL_SUBJECT" -r $RETURN_MAIL_ADDR $TO_MAIL_ADDR
  logger -i -p user.crit -t schdbackup "Quota limit of $QUOTA_CRITICAL kilobytes exceeded"
  exit 1
else
  echo "Directory $BACKUP_DIR quota limit of $QUOTA_SETTING nearly reached!"|mailx -s "Warning: $MAIL_SUBJECT" -r $RETURN_MAIL_ADDR $TO_MAIL_ADDR
  logger -i -p user.warn -t schdbackup "Quota limit of $QUOTA_CRITICAL kilobytes almost reached!"
fi

rm -f "$TMPLIST"

exit
