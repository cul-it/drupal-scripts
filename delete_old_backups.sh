#!/usr/bin/bash
# ./delete_old_backups.sh 
# get rid of backup files older that 15 days
echo 
echo We are planning to save these files...
find . \( -name "*.gz" -o -name "*.sql" \) -mtime -15 -print | sort
echo 
echo and delete these files...
find . \( -name "*.gz" -o -name "*.sql" \) -mtime +15 -print | sort
while true
do
echo -n "Do you want to delete these files? (y or n) :"
read CONFIRM
case $CONFIRM in
y|Y|YES|yes|Yes) break ;;
n|N|no|NO|No)
echo Aborting - you entered $CONFIRM
exit
;;
*) echo Please enter only y or n
esac
done
echo You entered $CONFIRM. Continuing ...
find . \( -name "*.gz" -o -name "*.sql" \) -mtime +15 -print | xargs rm
ls -l