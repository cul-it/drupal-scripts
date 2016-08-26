#!/bin/bash
# dr-full-backup-restore.sh - restore backup copy of site and private files
#
# usage:
#	dr-full-backup-restore.sh <source-alias> YYYY-MM-DD-HH-MM-SS

# where to put the temporary and backup files
# make sure this is set up with correct user and group then
# set the sticky bit
# sudo chmod +d <dir>
BACKUPBASE=/libweb/drupal/backups/dr-full-backup

# user and group that allows php to write to directory & colleagues to use it
PHPUSER=apache
GROUP=lib_web_dev_role

function error_exit
{
	echo "*******************      *******************"
	echo "*******************      *******************"
	echo "*******************      *******************"
	echo "$1" 1>&2
	echo "*******************"
	echo "*******************"
	exit 1
}

function ConfirmOrExit() {
while true
do
echo -n "Please confirm (y or n) :"
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
}

function RequireDirectory() {
	DIR=${1}
	# mkdir -p only makes dir if it's not there
	sudo mkdir -p "$DIR" || error_exit "can't make directory $DIR"
	sudo chown "$PHPUSER:$GROUP"  "$DIR" || error_exit "can't set ownership of $DIR to $PHPUSER $GROUP"
	sudo chmod g+w "$DIR" || error_exit "can't set $DIR to group writable"
	sudo chmod ug+s "$DIR" || error_exit "can't set $DIR SGID"
}

# Make sure root is not running our script
if [[ $EUID -eq 0 ]]; then
 	echo "Usage: $0 <alias> YYYY-MM-DD-HH-MM-SS"
	error_exit "This script can not be run with sudo powers, but parts of it use sudo."
fi

# check argument count
if [ $# -ne 2 ]; then
	echo "Usage: $0 <source-alias> YYYY-MM-DD-HH-MM-SS"
	echo "Here is a list of the aliases:"
	drush site-alias | sort
	exit 1
fi

echo "*******************"
echo "Checking the aliases..."
echo ""

sourcesite=`drush site-alias --component=uri "$1"`
[[ -n "$sourcesite" ]] || error_exit "$1 is not a valid source alias"
sourcefiles=`drush dd "$1:%privatefiles"`
[[ -n "$sourcefiles" ]] || error_exit "$1 needs a %privatefiles path-alias"

stamp=$2

# make a backup of the target to backups directory
echo "*******************"
echo "checking backup "
echo ""
backupdir="$BACKUPBASE/$sourcesite/$stamp"
[[ -d "$backupdir" ]] || error_exit "missing directory: $backupdir"

bkpfile1="$backupdir/archive-dump-$sourcesite-$stamp.tar.gz"
[[ -f "$bkpfile1" ]] || error_exit "missing archive-dump: $bkpfile1"

privates="$BACKUPBASE/$sourcesite/$stamp"
privatefile="$privates/private-files-$sourcesite-$stamp.tar.gz"
[[ -f "$privatefile" ]] || error_exit "missing private-files: $privatefile"

echo "Do you really want to replace $sourcesite with the backup from $stamp?"
ConfirmOrExit

echo "*******************"
echo "restoriing the $sourcesite files & database from $bkpfile1"
echo ""
drush archive-restore "$bkpfile1" "$sourcesite"

echo "*******************"
echo "restoring private files from $privatefile"
echo ""
gtar -xzf --strip-components=4 "$privatefile" -C "$sourcefiles"
echo "private files saved to:"
echo "$sourcefiles"

echo "Done."
