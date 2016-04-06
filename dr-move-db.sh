#!/bin/bash
# dr-move-db.sh - move the database from one drupal site to another
#
# usage:
#	dr-move-db.sh <source-alias> <target-alias>
### svn:keyword $Date: 2013-05-06 14:01:37 -0400 (Mon, 06 May 2013) $
### svn:keyword $Author: jgr25 $
### svn:keyword $Rev: 1478 $
### svn:keyword $URL: https://svn.library.cornell.edu/cul-drupal/scripts/dr-move-db.sh $


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

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
 	echo "Usage: sudo $0 <alias> [<sitegroup>]"
	error_exit "This script has to be run with sudo powers."
fi

# check argument count
if [ $# -ne 2 ]; then
	echo "Usage: sudo $0 <source-alias> <target-alias>"
	echo "Here is a list of the aliases:"
	drush site-alias | sort
	exit 1
fi

sourcesite=`drush site-alias --component=uri "$1"`
[[ -n "$sourcesite" ]] || error_exit "$1 is not a valid source alias"
targetsite=`drush site-alias --component=uri "$2"`
[[ -n "$targetsite" ]] || error_exit "$2 is not a valid target alias"
sourcefiles=`drush dd "$1:%privatefiles"`
[[ -n "$sourcefiles" ]] || error_exit "$1 needs a %privatefiles path-alias"
targetfiles=`drush dd "$2:%privatefiles"`
[[ -n "$targetfiles" ]] || error_exit "$2 needs a %privatefiles path-alias"
targetroot=`drush site-alias --component=root "$2"`
[[ -n "$targetroot" ]] || error_exit "$2 needs a needs a root component"

echo "Move the database from "
echo "$sourcesite"
echo "to"
echo "$targetsite ?"
ConfirmOrExit

# store the dumpfiles in drush-sql-sync
dumpdir=/libweb/drupal/backups/drush-sql-sync
[ -d "$dumpdir" ] || sudo mkdir -p "$dumpdir" ; sudo chown apache:lib_web_dev_role "$dumpdir" ; sudo chmod g+w "$dumpdir"

stamp=`date +'%Y-%m-%d-%H-%M-%S'`

# make a backup of the target to it's local drupal_files directory
bkpfile="$targetfiles/dump-$stamp-$targetsite-before.sql"
echo "backing up the $targetsite database to $bkpfile ..."
drush -r "$targetroot" sql-dump >"$bkpfile"
gzip -c "$bkpfile" >"$bkpfile.gzip" && rm "$bkpfile"

echo "doing sql-sync"
drush sql-sync "$1" "$2" --no-cache --source-dump="$dumpdir/$sourcesite.sql" --target-dump="$dumpdir/$targetsite.sql"

echo "Done."
