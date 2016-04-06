#!/bin/bash
# site-push.sh - push a Drupal site into it's git repo
#
# usage:
# site-push.sh <source-alias> <git-repositoy-name>


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
if [ $# -ne 2 ]; then
  echo "Usage: sudo $0 <source-alias> <repo-name>"
  echo "Here is a list of the aliases:"
  drush site-alias | sort
  exit 1
fi

repository="$2"

# find the domain name of the site
sourcesite=`drush site-alias --component=uri "$1"`
[[ -n "$sourcesite" ]] || error_exit "$1 is not a valid source alias"


# create a temp directory for the copy
tempdir=/tmp/site-push/$sourcesite
mkdir -p -v $tempdir

# get a copy of the current repository
cd $tempdir
git clone "git@git.library.cornell.edu:$repository" || error_exit "$repository is not a valid git repository"

echo "Done!!"
