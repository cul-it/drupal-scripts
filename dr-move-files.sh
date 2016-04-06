#!/bin/bash
# dr-move-files.sh - move the files (not modules/themes/core) from one drupal site to another
#
# usage:
#	dr-move-files.sh <source-alias> <target-alias>
### svn:keyword $Date: 2014-11-04 15:39:05 -0500 (Tue, 04 Nov 2014) $
### svn:keyword $Author: jgr25 $
### svn:keyword $Rev: 2876 $
### svn:keyword $URL: https://svn.library.cornell.edu/cul-drupal/scripts/dr-move-files.sh $


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
	echo "Usage: $0 <source-alias> <target-alias>"
	echo "Here is a list of the aliases:"
	drush site-alias | sort
	exit 1
fi

sourcesite=`drush site-alias --component=uri "$1"`
[[ -n "$sourcesite" ]] || error_exit "$1 is not a valid source alias"
targetsite=`drush site-alias --component=uri "$2"`
[[ -n "$targetsite" ]] || error_exit "$2 is not a valid target alias"

echo "Move the files (not modules/themes/core etc.) from "
echo "$sourcesite"
echo "to"
echo "$targetsite ?"
ConfirmOrExit

stamp=`date +'%Y-%m-%d-%H-%M-%S'`

drush rsync "$1" "$2" --include-paths="sites/default:../drupal_files"
echo "Moving the public files directory..."
drush rsync "$1:%files" "$2:%files"

echo "Moving the private files directory..."
drush rsync "$1:%privatefiles" "$2:%privatefiles"

echo "Done."
