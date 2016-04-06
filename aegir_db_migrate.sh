#!/bin/bash
# aegir_db_migrate.sh - move a site database to a site in aegir
# run this on aegir server
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
MYUSER="jgr25"

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
	error_exit "This script needs to be run as root."
fi

# check argument count
if [ $# -ne 2 ]; then
	error_exit "Usage: sudo $0 <production domain> <platform_name>"
fi

stamp=`date +'%Y-%m-%d-%H-%M-%S'`
productiondomain="$1"
platform_name="$2"
aegir_site_name="${platform_name}.$DOMAIN_SUFFIX"
aegirsite="/var/aegir/platforms/$platform_name/sites/$platform_name.$DOMAIN_SUFFIX"
productionsite="$SUDO_USER@$SOURCE_MACHINE:/libweb/sites/$productiondomain/htdocs/"

if [ ! -d "$aegirsite" ]; then
	error_exit "Directory $aegirsite must already exists!"
fi

echo "This will move the database from $productiondomain on $SOURCE_MACHINE into an Aegir site called $platform_name.$DOMAIN_SUFFIX"
ConfirmOrExit

# make backup of production site on production machine
BACKUP_NAME="${productiondomain}_$stamp.sql"
SCRIPT="cd \"/libweb/sites/$productiondomain/htdocs\" ; drush sql-dump > \"/libweb/sites/$productiondomain/drupal_files/$BACKUP_NAME\""
ssh -l "${MYUSER}" "${SOURCE_MACHINE}" "${SCRIPT}"
echo "backed up db to $BACKUP_NAME"

# copy the remote database into the aegir temp dir
scp "${MYUSER}@${SOURCE_MACHINE}:/libweb/sites/$productiondomain/drupal_files/$BACKUP_NAME" "/tmp/$BACKUP_NAME"

# move file into private dir as aegir
aegirsiteprivate="${aegirsite}/private/files/"
sudo mkdir -p "$aegirsiteprivate"
sudo mv "/tmp/$BACKUP_NAME" "$aegirsiteprivate"
sudo chmod -R 755 "$aegirsiteprivate"
sudo chown -R "$USER_GROUP" "$aegirsiteprivate"
echo "copied backup into $aegirsiteprivate"

# load the database into the site as the aegir user
echo "Loading the database..."
sudo -iu aegir drush "@${aegir_site_name}" sqlc < "${aegirsiteprivate}$BACKUP_NAME"
echo "database loaded"

echo "have a nice day"
