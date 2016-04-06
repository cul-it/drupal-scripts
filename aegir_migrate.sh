#!/bin/bash
# aegir_migrate.sh - move a production site to its own platform in aegir
# based on https://omega8.cc/import-your-sites-to-aegir-in-8-easy-steps-109
# run this on test server
### svn:keyword $Date: 2014-03-31 16:51:59 -0400 (Mon, 31 Mar 2014) $
### svn:keyword $Author: jgr25 $
### svn:keyword $Rev: 2264 $
### svn:keyword $URL: https://svn.library.cornell.edu/cul-drupal/scripts/update_test_from_production.sh $
testdomain="xxx.test2.library.cornell.edu"
productiondomain="xxx.library.cornell.edu"
my_user="jgr25"

stamp=`date +'%Y-%m-%d-%H-%M-%S'`
SOURCE_MACHINE="victoria01"
HOST_MACHINE="sf-lib-web-007.serverfarm.cornell.edu"
AEGIR_HOST="lamp-stg.library.cornell.edu"
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
 	echo "Usage: sudo $0 <production domain> <platform_name> "
	error_exit "This script has to be run with sudo powers."
fi

# check argument count
if [ $# -ne 2 ]; then
	error_exit "Usage: sudo $0 <production domain> <platform_name>"
fi

productiondomain="$1"
platform_name="$2"
testsite="/var/aegir/platforms/$platform_name/"
productionsite="$SUDO_USER@$SOURCE_MACHINE:/libweb/sites/$productiondomain/htdocs/"
aegir_site_name="${platform_name}.$DOMAIN_SUFFIX"

if [ -d "$testsite" ]; then
	error_exit "Directory $testsite already exists!"
fi

echo "This will move $productiondomain from $SOURCE_MACHINE into an Aegir platform called $platform_name"
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
echo "	$STEP. make a backup of the PRODUCTION site database to the drupal_files Directory"
echo "		requires your $SOURCE_MACHINE account password"
# make backup of production site on production machine
BACKUP_NAME="${productiondomain}_$stamp.sql"
SCRIPT="cd \"/libweb/sites/$productiondomain/htdocs\" ; drush sql-dump > \"/libweb/sites/$productiondomain/drupal_files/$BACKUP_NAME\""
ssh -l ${my_user} "${SOURCE_MACHINE}" "${SCRIPT}"

let STEP=STEP+1
echo " $STEP. Copy site files from $SOURCE_MACHINE"
echo "rsync needs your password for the PRODUCTION server:"
sudo rsync -av "$productionsite" "$testsite"

# copy in a .htaccess file so clean urls will work
cd "$testsite"
wget -q https://drupalgooglecode.googlecode.com/svn/trunk/.htaccess

# set up permissions for aegir
sudo chmod -R 755 "$testsite"
sudo chmod -R 777 "${testsite}sites/default/files/"
sudo chown -R "$USER_GROUP" "$testsite"

let STEP=STEP+1
echo "Now do this:"
echo "  $STEP. add a platform in aegir"
echo "		http://$AEGIR_HOST/node/add/platform"
echo "		the Name: should be $platform_name"
echo "		leave the Makefile: blank and the Web sever: the default"
echo "		Hit Save and wait for the Verify task to finish"
echo "You did this, right?"
ConfirmOrExit

let STEP=STEP+1
echo "Now do this: "
echo "	$STEP. create a new, blank site on the platform you just made"
echo "		http://$AEGIR_HOST/node/add/site"
echo "		Domain name: $aegir_site_name"
echo "		Client: admin"
echo "		SSL cert: the one with 'wildcard' in the name"
echo "		Install profile: Standard (or Drupal for Drupal 6.x)"
echo "		Platform: $platform_name"
echo "		Language: English"
echo "		Database server: localhost"
echo " 		Hit Save and wait for the Install task to finish"
echo "		Ignore errors like 'No proper IP provided by the frontend for server @server_master, using wildcard'"
echo "You did this, right?"
ConfirmOrExit

let STEP=STEP+1
echo "	$STEP. Copying the files into place"
# copy all the files to aegir's multisite files place
cp -af "${testsite}sites/default/files/." "${testsite}sites/$aegir_site_name/files/"

# see if there are drupal private file system files to move
testsiteprivate="${testsite}sites/$aegir_site_name/private/files/"
sudo mkdir -p "$testsiteprivate"
if [ -d "$testsiteprivate" ]; then
	productionsiteprivate="$SUDO_USER@$SOURCE_MACHINE:/libweb/sites/$productiondomain/drupal_files/"
	# rsync needs sudo
	echo "	rsync needs your password again for the private data on the PRODUCTION server:"
	rsync -av --exclude=.svn "$productionsiteprivate" "$testsiteprivate"

	# set up permissions for aegir
	sudo chmod -R 755 "$testsiteprivate"
	sudo chown -R "$USER_GROUP" "$testsiteprivate"
fi

#load the database using the site alias
echo "Loading the database..."
sudo -iu aegir drush "@${aegir_site_name}" sqlc < "$testsiteprivate/$BACKUP_NAME"
echo "database loaded"

let STEP=STEP+1
echo "	$STEP. Rename the site (using Migrate task) once"
echo "		http://$AEGIR_HOST/hosting/sites"
echo "		click on your site $aegir_site_name"
echo "		Click on Migrate > Run"
echo "		Domain name: not$aegir_site_name"
echo "		Database server: localhost"
echo "		Platform: (use Current platform)"
echo " 		click on Migrate and wait for the Migrate task to finish"
echo "		(this process fixes up the paths to images and files within the site)"
echo "You did this, right?"
ConfirmOrExit

let STEP=STEP+1
echo "	$STEP. Rename the site (using Migrate task) again a second time"
echo "		http://$AEGIR_HOST/hosting/sites"
echo "		click on your site not$aegir_site_name"
echo "		Click on Migrate > Run"
echo "		Domain name: $aegir_site_name"
echo "		Database server: localhost"
echo "		Platform: (use Current platform)"
echo " 		click on Migrate and wait for the Migrate task to finish"
echo "You did this, right?"
ConfirmOrExit

let STEP=STEP+1
echo "	$STEP. Re-verify the site"
echo "		http://$AEGIR_HOST/hosting/sites"
echo "		click on your site $aegir_site_name"
echo "		click on Verify > Run and wait"
echo "You did this, right?"
ConfirmOrExit
echo "have a nice day"
