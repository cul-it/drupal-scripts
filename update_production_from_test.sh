#!/bin/bash
# update_production_from_test.sh - move the site from test
# run this on production server
### svn:keyword $Date: 2014-03-31 16:51:59 -0400 (Mon, 31 Mar 2014) $
### svn:keyword $Author: jgr25 $
### svn:keyword $Rev: 2264 $
### svn:keyword $URL: https://svn.library.cornell.edu/cul-drupal/scripts/update_production_from_test.sh $
testdomain="xxx.test2.library.cornell.edu"
productiondomain="xxx.library.cornell.edu"

SOURCE_MACHINE="victoria02"
HOST_MACHINE="victoria01.serverfarm.cornell.edu"

# An error exit function
function error_exit
{
	echo "**************************************"
	echo "$1" 1>&2
	echo "**************************************"
	exit 1
}

# First we define the function
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

# Make sure we're on the production machine
if [ "$HOSTNAME" != "$HOST_MACHINE" ]; then
	error_exit "Only run $0 on $HOST_MACHINE"
fi

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
 	echo "Usage: sudo $0 <alias> "
	error_exit "This script has to be run with sudo powers."
fi

# check argument count
if [ $# -ne 2 ]; then
	error_exit "Usage: sudo $0 <test domain> <production domain>"
fi

testdomain="$1"
productiondomain="$2"
testsite="$SUDO_USER@$SOURCE_MACHINE:/libweb/sites/$testdomain/htdocs/"
productionsite="/libweb/sites/$productiondomain/htdocs/"

if [ ! -d "$productionsite" ]; then
	error_exit "Directory $productionsite does not exist!"
fi

echo "This will copy $testdomain into $productiondomain"
ConfirmOrExit

echo "First do this: "
echo "	1. make a backup of the TEST site to the Manual Backups Directory"
echo "		http://$testdomain/admin/content/backup_migrate/export"
echo "		http://$testdomain/admin/config/system/backup_migrate"
echo "You did this, right?"
ConfirmOrExit
echo "	2. put the PRODUCTION site into maintenance mode"
echo "		http://$productiondomain/admin/settings/site-maintenance"
echo "		http://$productiondomain/admin/config/development/maintenance"
echo "You did this, right?"
ConfirmOrExit
echo "rsync needs your password for the TEST server:"
# rsync needs sudo
rsync -av --exclude=.svn "$testsite" "$productionsite"

# see if there are drupal private file system files to move
productionsiteprivate="/libweb/sites/$productiondomain/drupal_files/"
if [ -d "$productionsiteprivate" ]; then
	testsiteprivate="$SUDO_USER@$SOURCE_MACHINE:/libweb/sites/$testdomain/drupal_files/"
	# rsync needs sudo
	echo "rsync needs your password again for the private data on the TEST server:"
	rsync -av --exclude=.svn "$testsiteprivate" "$productionsiteprivate"
fi

echo "Now do this: "
echo "	3. restore the new backup copy to the PRODUCTION server"
echo "		http://$productiondomain/admin/content/backup_migrate/destination/list/files/manual"
echo "		http://$productiondomain/admin/config/system/backup_migrate/destination/list/files/manual"
echo "		click 'restore' next to the latest version of the file"
echo "You did this, right?"
ConfirmOrExit
echo "	4. take the PRODUCTION site out of maintenance mode"
echo "		http://$productiondomain/admin/settings/site-maintenance"
echo "		http://$productiondomain/admin/config/development/maintenance"
echo "You did this, right?"
ConfirmOrExit
echo "	5. Configure the 'Site under maintenance' block"
echo "		http://$productiondomain/admin/build/block"
echo "		http://$productiondomain/admin/structure/block"
echo "		click 'configure' next to 'Site under maintenance'"
echo "		Under 'Page specific visibility settings' select"
echo "			'Show on only the listed pages'"
echo "You did this, right?"
ConfirmOrExit
if [ -a "/libweb/sites/$productiondomain/htdocs/production_robots.txt" ]; then
	echo "fixing up robots.txt for production"
	mv -f "/libweb/sites/$productiondomain/htdocs/production_robots.txt" "/libweb/sites/$productiondomain/htdocs/robots.txt"
fi
echo "have a nice day"

