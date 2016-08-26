#!/bin/bash -e
# dr-replace-db.sh - completely replace the site's database with another one
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
  echo "Usage: $0 <site-alias> <db_backup.sql.gz>"
  error_exit "This script can not be run with sudo powers, but parts of it use sudo."
fi

# check argument count
if [ $# -ne 2 ]; then
  echo "Usage: $0 <site-alias> <db_backup.sql.gz or .bz2>"
  exit 1
fi

echo "*******************"
echo "Checking the arguments..."
echo ""

targetalias="$1"
targetsite=`drush site-alias --component=uri "$1"`
[[ -n "$targetsite" ]] || error_exit "$1 is not a valid target alias"
targetfiles=`drush dd "$1:%privatefiles"`
[[ -n "$targetfiles" ]] || error_exit "$1 needs a %privatefiles path-alias"

sourcefile="$2"
if [ ! -e "$sourcefile" ]; then
  error_exit "$sourcefile is not a file"
fi

# calculate all the file paths
tempdir="/tmp/dr-replace-db"
stamp=`date +'%Y-%m-%d-%H-%M-%S'`
backup_dir="$targetfiles/droppings"
backup_file="$targetfiles/droppings/sql-drop-${stamp}.sql"
backup_file_gz="${backup_file}.gz"
dump_dir="${tempdir}/${targetsite}/restore"
dump_file="${dump_dir}/dump.sql"

echo "1. backup current site database to"
echo "    $backup_file_gz"
echo "2. expand $sourcefile into"
echo "    $dump_file"
echo "3. replace $targetsite database with $dump_file"
echo "4. run $targetsite/update.php to update the database"
echo ""
echo "You want to do all this?"
ConfirmOrExit

echo "*******************"
echo "Backing up all the current tables"
echo ""
mkdir -p "$backup_dir" || error_exit "can't make directory $backup_dir"
touch "$backup_file" || error_exit "can't make file $backup_file"
drush "$targetalias" sql-dump --result-file="$backup_file" || error_exit "can't backup $targetalias"
gzip -c "$backup_file" > "$backup_file_gz" || error_exit "can't create $backup_file_gz"
rm "$backup_file" || error_exit "can't remove $backup_file"
echo "Database dump compressed to"
ls -lh "$backup_file_gz"

echo "*******************"
echo "Unpacking database file"
echo ""
if [ -d "${dump_dir}" ]
then
  echo "deleting temp directory ${dump_dir}"
  rm -r "${dump_dir}" || error_exit "can't delete ${dump_dir}"
fi
mkdir -p "${dump_dir}" || error_exit "can't create ${dump_dir}"
extension="${sourcefile##*.}"
case $extension in
  gz)
    gunzip -c "$sourcefile" > "${dump_file}" || error_exit "can't gunzip ${sourcefile}"
    ;;
  bz2)
    bunzip2 -c "$sourcefile" > "${dump_file}" || error_exit "can't bunzip2 ${sourcefile}"
    ;;
  *)
    error_exit "Unknown extension $extension"
esac
ls -lh "${dump_file}"

echo "*******************"
echo "Dropping all the current tables"
echo ""
drush "$targetalias" sql-drop || error_exit "can't drop tables"

echo "*******************"
echo "Installing the database file"
echo ""
drush "$targetalias" sql-cli < "${dump_file}" || error_exit "can't install database"

echo "*******************"
echo "Running $targetsite/update.php to update the database"
echo ""
drush "$targetalias" updatedb || error_exit "can't update the database"

echo "Have a nice day."

