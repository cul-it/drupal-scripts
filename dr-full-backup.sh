#!/bin/bash
# dr-full-backup.sh - make backup copy of site and private files
#
# usage:
#	dr-full-backup.sh <source-alias>

# where to put the temporary and backup files
# make sure this is set up with correct user and group then
# set the SGID
# sudo chmod g+s <dir>
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
 	echo "Usage: $0 <alias> "
	error_exit "This script can not be run with sudo powers, but parts of it use sudo."
fi

# check argument count
if [ $# -ne 1 ]; then
	echo "Usage: $0 <source-alias>"
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

# make sure the backup base directory exists
RequireDirectory "$BACKUPBASE"

stamp=`date +'%Y-%m-%d-%H-%M-%S'`

# make a backup of the target to backups directory
echo "*******************"
echo "backup target site "
echo ""
backupdir="$BACKUPBASE/$sourcesite/$stamp"
RequireDirectory "$backupdir"

bkpfile="$backupdir/archive-dump-$sourcesite-$stamp.tar.gz"
echo "*******************"
echo "backing up the $sourcesite files & database..."
echo ""
drush "$1" archive-dump -v --destination=$bkpfile
echo "*******************"
echo "backup private files "
echo ""
privates="$BACKUPBASE/$sourcesite/$stamp"
RequireDirectory "$privates"
privatefile="$privates/private-files-$sourcesite-$stamp.tar.gz"
gtar -cpzf "$privatefile" "$sourcefiles"
echo "private files saved to:"
echo "$privatefile"

echo "Done."
