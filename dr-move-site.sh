#!/bin/bash
# dr-move-site.sh - move the database and files from one drupal site to another
#
# usage:
#	dr-move-site.sh <source-alias> <target-alias>
### svn:keyword $Date: 2012-06-29 12:42:05 -0400 (Fri, 29 Jun 2012) $
### svn:keyword $Author: cam2 $
### svn:keyword $Rev: 945 $
### svn:keyword $URL: https://svn.library.cornell.edu/cul-drupal/drupal_6/scripts/dr-move-site.sh $

# where to put the temporary and backup files
# make sure this is set up with correct user and group then
# set the sticky bit
# sudo chmod g+s <dir>
BACKUPBASE=/libweb/drupal/backups/dr-move-site

# user and group that allows php to write to directory & colleagues to use it too
PHPUSER=apache
GROUP=lib_web_dev_role

# The rsync and sql-sync commands have to run as a real user in the GROUP who
# has set up ssh keys on both machines. The real user doesn't have permission to change
# ownership/permissions of files so we don't preserver permissions during the rsync.
# This means we have to change permission/owner of files after the transfer using sudo,
# so don't run this script with sudo, but you'll be asked for a password anyway!

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
	if [ -d $DIR ]; then
		#echo "$DIR exists"
		touch "$DIR/foo_test_file" || error_exit "$DIR is not writable"
		rm -f "$DIR/foo_test_file"
	else
		mkdir -p "$DIR" || error_exit "can't make directory $DIR"
		chown "$PHPUSER:$GROUP"  "$DIR" || error_exit "can't set ownership of $DIR to $PHPUSER $GROUP"
		chmod g+w "$DIR" || error_exit "can't set $DIR to group writable"
	fi
}

# Make sure root is not running our script
if [[ $EUID -eq 0 ]]; then
 	echo "Usage: $0 <source-alias> <target-alias>"
	error_exit "This script can not be run with sudo powers, but parts of it use sudo."
fi

# check argument count
if [ $# -ne 2 ]; then
	echo "Usage: $0 <source-alias> <target-alias>"
	echo "For a list of the aliases: drush site-alias | sort"
	exit 1
fi

echo "*******************"
echo "Checking the aliases..."
echo ""

targetsite=`drush site-alias --component=uri "$2"`
[[ -n "$targetsite" ]] || error_exit "$2 is not a valid target alias"
sourcesite=`drush site-alias --component=uri "$1"`
[[ -n "$sourcesite" ]] || error_exit "$1 is not a valid source alias"
sourcefiles=`drush dd "$1:%privatefiles"`

echo "Move the database and files from "
echo "$sourcesite"
echo "to"
echo "$targetsite ?"
ConfirmOrExit

[[ -n "$sourcefiles" ]] || error_exit "$1 needs a %privatefiles path-alias"
targetfiles=`drush dd "$2:%privatefiles"`
[[ -n "$targetfiles" ]] || error_exit "$2 needs a %privatefiles path-alias"
targetroot=`drush site-alias --component=root "$2"`
[[ -n "$targetroot" ]] || error_exit "$2 needs a needs a root component"

[[ -d "$targetroot" ]] || error_exit "You need to be on the same machine as the target $2"

# check sudo and set group of target htdocs directory
echo "*******************"
echo "make target site writable"
echo ""
sudo chgrp "$GROUP" "$targetroot" || error_exit "You must have sudo powers for chgrp"
sudo chmod g+w "$targetroot" || error_exit "You must have sudo powers for chmod"

# set drupal_files directory so our group can write w/ rsync
sudo chgrp -R "$GROUP" "$targetfiles" || error_exit "can't chgrp $targetfiles"
sudo chmod -R g+w "$targetfiles" || error_exit "can't chmod $targetfiles"

# make sure the backup base directory exists
RequireDirectory "$BACKUPBASE"

# store the dumpfiles in drush-archive-dump
dumpdir="$BACKUPBASE/drush-archive-dump"
RequireDirectory "$dumpdir"

# store target site backups in target backups
target_db_backups_dir="$BACKUPBASE/target-db-backups"
RequireDirectory "$target_db_backups_dir"

stamp=`date +'%Y-%m-%d-%H-%M-%S'`

# put the target site into offline mode
echo "*******************"
echo "put target site offline"
echo "*******************"
DRUPALVERSION=`drush "$2" core-status drupal-version --pipe`
if [[ -z $DRUPALVERSION ]]; then continue; fi
SIMPLEVERSION=`echo "$DRUPALVERSION" | cut -d. -f1`
echo "Drupal $SIMPLEVERSION site: $DRUPALVERSION"
if [ "$SIMPLEVERSION" = 7 ] ;
then
	drush "$2" vset --always-set maintenance_mode 1
	if [ "$?" -ne "0" ]; then
		error_exit "Drupal 7 site couldn't go offline"
	fi
else
	drush "$2" vset --always-set site_offline 1
	if [ "$?" -ne "0" ]; then
		error_exit "Drupal 6 site couldn't go offline"
	fi
fi
drush cache-clear all


# can't preserve permissions with this rsync - no permission
echo "*******************"
echo "moving the files"
echo ""
drush rsync -y --omit-dir-times --mode=rltz "$1" "$2" || error_exit "can't move the site root directory"

echo "*******************"
echo "moving the private files directory..."
echo ""
sudo drush rsync -y --omit-dir-times --mode=rlptz "$1:%privatefiles" "$2:%privatefiles" || error_exit "can't move the private files directory"

echo "*******************"
echo "setting file permissions..."
echo ""
sudo chmod -R ug+w "$targetroot"
sudo chgrp -R "$GROUP" "$targetroot"
sudo chown -R "$PHPUSER" "$targetroot/sites/default/files"
sudo chmod -R g+s "$targetroot/sites/default/files"
sudo chmod ugo-w "$targetroot/sites/default/settings.php"

echo "*******************"
echo "backup the target database..."
echo ""
backup_file="$target_db_backups_dir/$targetsite-${stamp}.sql"
touch "$backup_file" || error_exit "can't make file $backup_file"
drush "$2" sql-dump --yes --result-file="$backup_file" --gzip || error_exit "can't backup database $2"

echo "*******************"
echo "clear out tables from the target database..."
echo ""
drush "$2" sql-drop --yes || error exit "can't drop tables in $2"

echo "*******************"
echo "doing sql-sync using "
echo "  source: $dumpdir/$sourcesite-${stamp}.sql"
echo "  target: $dumpdir/$targetsite-${stamp}.sql"
echo ""
drush sql-sync "$1" "$2" --yes --no-cache --source-dump="$dumpdir/$sourcesite-${stamp}.sql" --target-dump="$dumpdir/$targetsite-${stamp}.sql" || error_exit "can't sync the databases"

# put the target into back into online mode
echo "*******************"
echo "put site on line"
echo ""
if [ "$SIMPLEVERSION" = 7 ] ;
then
	drush "$2" vset --always-set maintenance_mode 0
	if [ "$?" -ne "0" ]; then
		error_exit "Drupal 7 site couldn't go on line"
	fi
else
	drush "$2" vset --always-set site_offline 0
	if [ "$?" -ne "0" ]; then
		error_exit "Drupal 6 site couldn't go on line"
	fi
fi
drush "$2" cache-clear all

# host
hostname=`hostname`
machine=`echo $hostname | awk -F'.' '{print $1}'`
echo "*******************"
echo "adjust robots.txt for $machine"
echo ""
case $machine in
	victoria01|victoria03|victoria04)
		if [ -f "$targetroot/production_robots.txt" ]; then
			echo "use regular robots.txt"
			cp "$targetroot/production_robots.txt" "$targetroot/robots.txt"
		fi;;
	victoria02)
		echo "use restrictive robots.txt"
		echo -e 'User-agent: *\nDisallow: /' > "$targetroot/robots.txt";;
	*) echo "unknown machine $machine from $hostname" ;;
esac


echo "Done."
