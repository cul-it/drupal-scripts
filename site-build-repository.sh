#!/bin/bash
# site-build-repository.sh - push a Drupal site into a new git repo
#
# usage:
# site-build-repository.sh <source-alias> <git-repositoy-name>

function usage()
{
  echo " Usage: $0 <source-alias> <git-repositoy-name>"
  echo "Here is a list of the aliases:"
  drush site-alias | sort
}

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

# check argument count
[[ $# -lt 2 ]] && { usage; exit 1; }

sitealias="$1"
repository="$2"

# find the domain name of the site
sourcesite=`drush site-alias --component=uri "$1"`
[[ -n "$sourcesite" ]] || error_exit "$1 is not a valid source alias"


# create a temp directory for the copy
tempdir=/tmp/site-build-repository/$sourcesite
mkdir -p -v $tempdir
mkdir -p -v "$tempdir/htdocs"
mkdir -p -v "$tempdir/privatefiles"

# put the site into offline mode
echo "*******************"
echo "put site offline"
drush $sitealias vset --always-set site_offline 1
# for drupal 7
drush $sitealias vset --always-set maintenance_mode 1

# backup the database
drush "$sitealias" sql-dump --ordered-dump > "$tempdir/database_dump.sql"

echo "Moving the htdocs directory..."
htdocs=`drush dd "$sitealias"`
echo $htdocs
rsync -az "$htdocs" "$tempdir/htdocs"

echo "Moving the private files directory..."
privatefiles=`drush dd "$sitealias:%privatefiles"`
privatefiles+='/'
echo $privatefiles
rsync -az "$privatefiles" "$tempdir/privatefiles"

# put the site into back into online mode
echo "*******************"
echo "put site on line"
drush $sitealias vset --always-set site_offline 0
# for drupal 7
drush $sitealias vset --always-set maintenance_mode 0

echo "Temp directory: $tempdir"
echo "Done!!"
