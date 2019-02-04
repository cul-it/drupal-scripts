#!/bin/bash
# update_test_from_production.sh - move the site from production
# run this on test server
### svn:keyword $Date: 2014-03-31 16:51:59 -0400 (Mon, 31 Mar 2014) $
### svn:keyword $Author: jgr25 $
### svn:keyword $Rev: 2264 $
### svn:keyword $URL: https://svn.library.cornell.edu/cul-drupal/scripts/update_test_from_production.sh $
testdomain="xxx.test2.library.cornell.edu"
productiondomain="xxx.library.cornell.edu"

SOURCE_MACHINE="victoria01"
HOST_MACHINE="sf-lib-web-011.serverfarm.cornell.edu"

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

# Make sure we're on the test machine
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
	error_exit "Usage: sudo $0 <production domain> <test domain>"
fi

productiondomain="$1"
testdomain="$2"
testsite="/libweb/sites/$testdomain/htdocs/"
productionsite="$SUDO_USER@$SOURCE_MACHINE:/libweb/sites/$productiondomain/htdocs/"

if [ ! -d "$testsite" ]; then
	error_exit "Directory $testsite does not exist!"
fi

echo "This will copy $productiondomain into $testdomain "
ConfirmOrExit

echo "First do this: "
echo "  1. Configure the 'Site under maintenance' block on the PRODUCTION server"
echo "      http://$productiondomain/admin/build/block"
echo "      http://$productiondomain/admin/structure/block"
echo "      click 'configure' next to 'Site under maintenance'"
echo "      Under 'Page specific visibility settings' select"
echo "          'Show on every page except the listed pages.'"
echo "You did this, right?"
ConfirmOrExit
echo "  2. make a backup of the PRODUCTION site to the Manual Backups Directory"
echo "      http://$productiondomain/admin/content/backup_migrate/export"
echo "      http://$productiondomain/admin/config/system/backup_migrate"
echo "You did this, right?"
ConfirmOrExit
echo "  3. put the TEST site into maintenance mode"
echo "      http://$testdomain/admin/settings/site-maintenance"
echo "      http://$testdomain/admin/config/development/maintenance"
echo "You did this, right?"
ConfirmOrExit
echo "rsync needs your password for the PRODUCTION server:"
sudo rsync -av "$productionsite" "$testsite"

# see if there are drupal private file system files to move
testsiteprivate="/libweb/sites/$testdomain/drupal_files/"
if [ -d "$testsiteprivate" ]; then
	productionsiteprivate="$SUDO_USER@$SOURCE_MACHINE:/libweb/sites/$productiondomain/drupal_files/"
	# rsync needs sudo
	echo "rsync needs your password again for the private data on the PRODUCTION server:"
	rsync -av --exclude=.svn "$productionsiteprivate" "$testsiteprivate"
fi

echo "Now do this: "
echo "  4. restore the new backup copy to the TEST server"
echo "      http://$testdomain/admin/content/backup_migrate/destination/list/files/manual"
echo "      http://$testdomain/admin/config/system/backup_migrate/destination/list/files/manual"
echo "      click 'restore' next to the latest version of the file"
echo "You did this, right?"
ConfirmOrExit
echo "  5. take the TEST site out of maintenance mode"
echo "      http://$testdomain/admin/settings/site-maintenance"
echo "      http://$testdomain/admin/config/development/maintenance"
echo "You did this, right?"
ConfirmOrExit
echo "have a nice day"
