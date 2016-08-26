#!/bin/bash
# aegir_site_migrate.sh - move a production site to an existing site in aegir
# based on https://omega8.cc/import-your-sites-to-aegir-in-8-easy-steps-109
# run this on test server
### svn:keyword $Date: 2014-03-31 16:51:59 -0400 (Mon, 31 Mar 2014) $
### svn:keyword $Author: jgr25 $
### svn:keyword $Rev: 2264 $
### svn:keyword $URL: https://svn.library.cornell.edu/cul-drupal/scripts/update_test_from_production.sh $
testdomain="xxx.test2.library.cornell.edu"
productiondomain="xxx.library.cornell.edu"

SOURCE_MACHINE="victoria01"
HOST_MACHINE="sf-lib-web-007.serverfarm.cornell.edu"
AEGIR_HOST="web-stg.library.cornell.edu"
DOMAIN_SUFFIX="stg.library.cornell.edu"
USER_GROUP="aegir:apachegir"

# An error exit function
function error_exit
{
	echo "**************************************"
	echo "$1" 1>&2
	echo "**************************************"
	exit 1
}

function Confirm() {
while true
do
echo -n "Please confirm (y or n) :"
read CONFIRM
case $CONFIRM in
y|Y|YES|yes|Yes) return 1 ;;
n|N|no|NO|No) return 0 ;;
*) echo Please enter only y or n
esac
done
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
	error_exit "Only run $0 on $AEGIR_HOST"
fi

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
 	echo "Usage: sudo $0 <production domain> <platform_name> <site name>"
	error_exit "This script has to be run with sudo powers."
fi

# check argument count
if [ $# -ne 3 ]; then
	error_exit "Usage: sudo $0 <production domain> <platform_name> <site name>"
fi

productiondomain="$1"
platform_name="$2"
site_name="$3"
testsite="/var/aegir/platforms/$platform_name/sites/$site_name"
productionsite="$SUDO_USER@$SOURCE_MACHINE:/libweb/sites/$productiondomain/htdocs/"
productionsite_files="${productionsite}sites/default/files"

if [ ! -d "$testsite" ]; then
	error_exit "First create $site_name in platform $platform_name!"
fi

echo "This will move $productiondomain from $SOURCE_MACHINE into an Aegir platform called $platform_name and site named $site_name"
ConfirmOrExit

let STEP=1
echo "First do this: "
echo "	$STEP. Configure the 'Site under maintenance' block on the PRODUCTION server"
echo "		http://$productiondomain/admin/build/block"
echo "		http://$productiondomain/admin/structure/block"
echo "		click 'configure' next to 'Site under maintenance'"
echo "		Under 'Page specific visibility settings' select"
echo "			'Show on every page except the listed pages.'"
echo "You did this, right?"
ConfirmOrExit

let STEP=STEP+1
echo "	$STEP. make a backup of the PRODUCTION site to the Manual Backups Directory"
echo "		http://$productiondomain/admin/content/backup_migrate/export"
echo "		http://$productiondomain/admin/config/system/backup_migrate"
echo "You did this, right?"
ConfirmOrExit

let STEP=STEP+1
echo "  $STEP. Copy site files from $SOURCE_MACHINE"
echo "    rsync needs your password for the PRODUCTION server:"
sudo rsync -av "$productionsite_files/*" "$testsite/files"

# copy in a .htaccess file so clean urls will work
cd "$testsite"
wget -q https://drupalgooglecode.googlecode.com/svn/trunk/.htaccess

# set up permissions for aegir
sudo chmod -R 755 "$testsite"
sudo chmod -R 777 "$testsite/files/"
sudo chown -R "$USER_GROUP" "$testsite"

# see if there are drupal private file system files to move
testsiteprivate="${testsite}/private/files/"
sudo mkdir -p "$testsiteprivate"
if [ -d "$testsiteprivate" ]; then
	productionsiteprivate="$SUDO_USER@$SOURCE_MACHINE:/libweb/sites/$productiondomain/drupal_files/"
	# rsync needs sudo
	echo "	rsync needs your password again for the private data on the PRODUCTION server:"
	rsync -av --exclude=.svn "$productionsiteprivate" "$testsiteprivate"

	# set up permissions for aegir
	sudo chmod -R 775 "${testsite}/private"
	sudo chown -R "$USER_GROUP" "$testsiteprivate"
fi

let STEP=STEP+1
echo "Now do this: "
echo "	$STEP. Go to the new site and set up user #1 (Administrative User)"
echo "		http://$AEGIR_HOST/hosting/sites"
echo "		click on your site: $platform_name.${DOMAIN_SUFFIX}"
echo "		click on the Go to $platform_name.${DOMAIN_SUFFIX} link"
echo "		set up admin user email and password"
echo "		Hit Save at the bottom of the page"
echo "You did this, right?"
ConfirmOrExit

let STEP=STEP+1
echo "Now do this:"
echo "	$STEP. Enable the Backup Migrate module"
echo "		http://$platform_name.${DOMAIN_SUFFIX}/admin/build/modules"
echo "		http://$platform_name.${DOMAIN_SUFFIX}/admin/modules"
echo "		Check off Backup Migrate"
echo "		Hit Save configuration at the bottom of the page"
echo "You did this, right?"
ConfirmOrExit

let STEP=STEP+1
echo "Now do this:"
echo "	$STEP. Check for the backup file you just created among the backups"
echo "		http://$platform_name.${DOMAIN_SUFFIX}/admin/content/backup_migrate/destination/list/files/manual"
echo "		http://$platform_name.${DOMAIN_SUFFIX}/admin/config/system/backup_migrate/destination/list/files/manual"
echo "Do you see the backup file there?"
Confirm
retval=$?
if [ "$retval" == 0 ]; then
	let STEP=STEP+1
	echo "Now do this:"
	echo "	$STEP. Set path of Backup Migrate manual backups so we can find the database backup"
	echo "		http://$platform_name.${DOMAIN_SUFFIX}/admin/content/backup_migrate/destination"
	echo "		http://$platform_name.${DOMAIN_SUFFIX}/admin/config/system/backup_migrate/destination"
	echo "		Click override or edit and set the manual backups path to "
	echo "		sites/$platform_name.${DOMAIN_SUFFIX}/private/files/backup_migrate/manual"
	echo "You did this, right?"
	ConfirmOrExit
fi

let STEP=STEP+1
echo "Now do this: "
echo "	$STEP. restore the new backup copy to the TEST server"
echo "		http://$platform_name.${DOMAIN_SUFFIX}/admin/content/backup_migrate/destination/list/files/manual"
echo "		http://$platform_name.${DOMAIN_SUFFIX}/admin/config/system/backup_migrate/destination/list/files/manual"
echo "		click 'restore' next to the latest version of the file"
echo "		on the next page hit the Restore button"
echo "You did this, right?"
ConfirmOrExit

let STEP=STEP+1
echo "	$STEP. Rename the site (using Migrate task) once"
echo "		http://$AEGIR_HOST/hosting/sites"
echo "		click on your site $platform_name.${DOMAIN_SUFFIX}"
echo "		Click on Migrate > Run"
echo "		Domain name: temp.$platform_name.${DOMAIN_SUFFIX}"
echo "		Database server: localhost"
echo "		Platform: (use Current platform)"
echo " 		click on Migrate and wait for the Migrate task to finish"
echo "		(this process fixes up the paths to images and files within the site)"
echo "You did this, right?"
ConfirmOrExit

let STEP=STEP+1
echo "	$STEP. Rename the site (using Migrate task) again a second time"
echo "		http://$AEGIR_HOST/hosting/sites"
echo "		click on your site temp.$platform_name.${DOMAIN_SUFFIX}"
echo "		Click on Migrate > Run"
echo "		Domain name: $platform_name.${DOMAIN_SUFFIX}"
echo "		Database server: localhost"
echo "		Platform: (use Current platform)"
echo " 		click on Migrate and wait for the Migrate task to finish"
echo "You did this, right?"
ConfirmOrExit

let STEP=STEP+1
echo "	$STEP. Re-verify the site"
echo "		http://$AEGIR_HOST/hosting/sites"
echo "		click on your site $platform_name.${DOMAIN_SUFFIX}"
echo "		click on Verify > Run and wait"
echo "You did this, right?"
ConfirmOrExit
echo "have a nice day"
