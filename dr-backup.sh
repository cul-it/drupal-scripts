#!/bin/bash -e
# dr-backup.sh - drush backup for Drupal sites
#
# ./dr-backup.sh <alias>
#	where <alias> is an alias from .drush/aliases.drushrc.php (with the @ prefix)
#
#Global Vars - Victoria02
tempdir="/libweb/tmp"
bkpdir="/libweb/drupal/backups"
stamp=`date +'%Y-%m-%d-%H-%M-%S'`

#make sure we've got an argument for the drupal site path
if [ $1 ]; then
 echo "Checking $1"
else
 echo "Usage: $0 <alias> "
 drush site-alias | sort
 exit
fi

#get site name without alias
alias="$1"
sitename=${alias:1:99}

if [ ${alias:0:1} != '@' ]
then
	echo "Error in $0 - argument 1 must be an drupal site alias starting with @"
	exit
fi

# check site status
set -e
drush $1 core-status
set +e

# clean out any old temporary files
if [ -d $tempdir/$sitename ]
then
	chmod -R a+w $tempdir/$sitename
	rm -r $tempdir/$sitename/*
fi


# put the site into offline mode
echo "*******************"
echo "put site offline"
drush $alias vset --always-set site_offline 1

# backup database with drush (skip cache clear)
echo "*******************"
echo "Backing up $sitename database..."
mkdir -p $tempdir/$sitename
drush $1 sql-dump > $tempdir/$sitename/data.sql

# put the site into back into online mode
echo "*******************"
echo "put site on line"
drush $alias vset --always-set site_offline 0

# tar up the site files
drupalsite=`drush drupal-directory $1`
pushd $drupalsite
siteroot=${PWD##*/}
cd ../
echo "*******************"
echo "tarring up $drupalsite..."
gtar -cpzf $tempdir/$sitename/files.tar.gz $siteroot

# combine and move backups into bkpdir
echo "*******************"
echo "combining backups and moving into "
echo "$bkpdir/$sitename/$sitename-$stamp.tar.gz"
mkdir -p $bkpdir/$sitename
cd $tempdir/$sitename
gtar -cpzf $bkpdir/$sitename/$sitename-$stamp.tar.gz .

# go home - can't delete temp dir while in it!
echo "*******************"
echo "returning to original directory"
popd

# delete temporary dir
echo "*******************"
echo "cleaning up temporary files..."
chmod -R a+w $tempdir/$sitename
rm -r $tempdir/$sitename

# go home
echo "*******************"
echo "Done."

