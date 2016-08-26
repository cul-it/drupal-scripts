#!/bin/bash
# move-goldsen-to-production.sh - goldsen site victoria02 to victoria01

SOURCE_PATH=/libweb/sites/goldsen.test.library.cornell.edu/htdocs
SOURCE_MACHINE=victoria02.library.cornell.edu
TARGET_PATH=/libweb/sites/goldsen.library.cornell.edu/htdocs
TARGET_MACHINE=victoria01.library.cornell.edu
SITE_NAME=goldsen
HOST_MACHINE="victoria01.serverfarm.cornell.edu"

DRUPAL_PATH=etc
DRUPAL_SOURCE_PATH=$SOURCE_PATH/$DRUPAL_PATH
DRUPAL_TARGET_PATH=$TARGET_PATH/$DRUPAL_PATH

STAMP=`date +'%Y-%m-%d-%H-%M-%S'`

# BACKUP_FILE=sites/default/files/private/move/$SITE_NAME-$STAMP.sql
BACKUP_FILE=/tmp/${SITE_NAME}-${USER}-${STAMP}.sql
BACKUP_FILE_GZ=$BACKUP_FILE.gz

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

function message
{
  echo ""
  echo "*************************************"
  echo "**"
  echo "** $1"
  echo "**"
  echo "*************************************"
  echo ""
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

# Make sure we're on the production machine
if [ "$HOSTNAME" != "$HOST_MACHINE" ]; then
  error_exit "Only run $0 on $HOST_MACHINE"
fi

message "This will move the goldsen site from victoria02 (test) to victoria01 (production)"
ConfirmOrExit

# backup default database to private directory
message "backing up source Drupal database"
CMD="drush vset maintenance_mode 1 ; drush sql-dump --result-file=$BACKUP_FILE --gzip || error_exit \"Can't make database backup\" ; drush vset maintenance_mode 0"
SCRIPT="cd \"$DRUPAL_SOURCE_PATH\" ; eval \$($CMD)"
#echo $SCRIPT
ssh -l "${USER}" "${SOURCE_MACHINE}" "${SCRIPT}"

# rsync entire site to target
#  --dry-run to test
message "moving new code to target"
sudo rsync -avc -e ssh --delete --exclude=$DRUPAL_PATH/sites \
  $USER@$SOURCE_MACHINE:$SOURCE_PATH/ $TARGET_PATH/
message "moving files and backups (without deleting new files on target)"
sudo rsync -avc -e ssh --exclude=settings.php \
  $USER@$SOURCE_MACHINE:$DRUPAL_SOURCE_PATH/sites/ $DRUPAL_TARGET_PATH/sites/

# copy the database dump to target
message "moving database backup to target"
sudo rsync -avc -e ssh $USER@$SOURCE_MACHINE:$BACKUP_FILE_GZ $BACKUP_FILE_GZ

# load the database dump on the target machine
message "installing database backup in target Drupal site"
cd $DRUPAL_TARGET_PATH
pwd
drush vset maintenance_mode 1
gunzip < $BACKUP_FILE_GZ | `drush sql-connect`
drush vset maintenance_mode 0

message "have a nice day"
