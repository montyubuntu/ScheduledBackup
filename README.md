# ScheduledBackup
A simple customizable backup solution for unix platforms.
It finds files in directories and copies them to daily or weekly directories.
A mail is send if backups are missing and it uses the logger binary to write operations to logfile.
This is build as a standalone shell script and should run in cron.
It is heavily depended on specific customization and uses smtp to send alerts if backups are missing.
Use it to your liking or re-use the code for your specific backup implementation.

What it does:
-Copies files to weekly or daily directories depending on what is placed in the appropriate array.
-Deletes old backup files based on the daily or weekly value.
-Checks for file system usage, a warning is send when a certain threshold is reached.

You need to fill the local variables and the arrays to make it work appropriately.

This script is intended for 'big' multi-host platforms that need a backup solution in conjunction with protocols like (s)ftp or rsync.
Typically, full system backups or database backups can be administered by using this script.
