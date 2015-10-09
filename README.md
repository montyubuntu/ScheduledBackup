# ScheduledBackup
A simple customizable backup solution for unix platforms.
It finds files in directories and copies them to monthly or weekly directories.
A mail is send if backups are missing and it uses the logger binary to write operations to logfile.
This is build as a standalone shellscript and should run in cron.
It is heavily dependend on specific customization and uses smtp to send alerts if backups are missing.
Use it to your liking or re-use the code for your specific backup implementation.
