#!/bin/bash -e
# dr-restore.sh - drush restore for Drupal sites
#		expecting a backup file created by dr-backup.sh
# 
# ./dr-restore.sh <alias> <archive>
#	where <alias> is an alias from .drush/aliases.drushrc.php (with the @ prefix)
#	and <archive> is the path to a tarball created by dr-backup.sh
#
#Global Vars - Victoria02
tempdir="/libweb/tmp"
bkpdir="/libweb/drupal/backups"
sitegroup="lib_web_dev_role"
# on artslib user:group is webmstr:diglibdev-role
# on copia user:group is jgr25:webmstr
# on libdev user:group is jgr25:nobody
# on victoria02 user:group is jgr25:apache
filesgroup="apache"
filesuser=$USER

# An error exit function

function error_exit
{
	echo "$1" 1>&2
	exit 1
}

#make sure whoever runs this has sudo powers
echo "This script requires sudo powers to run."
if sudo pwd; then
	echo "You have the required sudo powers";
else
	echo "You need to have sudo to run this: $0" 1>&2
	exit 1
fi

#make sure we've got an argument for the drupal site path
if [ $1 ]; then
 echo "Checking $1" 
else
 echo "Usage: $0 <alias> <tarball>"
 echo "Here is a list of the aliases:"
 drush site-alias | sort
 exit
fi


#get site name without alias
alias="$1"
sitename=${alias:1:99}

if [ ${alias:0:1} != '@' ]
then
	echo "Error in $0 - argument 1 must be an alias starting with @"
	drush site-alias
	exit
fi

if [ -z "$2" ]
then
	echo "*******************"
	echo "Error in $0 - argument 2 must be a tarball created by dr-backup.sh"
	pushd $bkpdir/$sitename/ 1>/dev/null
	find . -type f | sed "s#^.#$(pwd)#"
	popd 1>/dev/null
	exit
fi

# find the current site
drupalsite=`drush drupal-directory $alias`

# expand the tarball
echo "*******************"
echo "restoring $2 to temp directory"
echo "temp directory: $tempdir/$sitename/restore"
if [ -d "$tempdir/$sitename/restore" ]
then
	echo "deleting temp directory $tempdir/$sitename/restore"
	sudo rm -r $tempdir/$sitename/restore
fi
mkdir -p $tempdir/$sitename/restore
# f has to be the last argument to gtar
gtar -C $tempdir/$sitename/restore -xpzf $2
# files are also in a tarball - expand htdocs
gtar -C $tempdir/$sitename/restore -xpzf $tempdir/$sitename/restore/files.tar.gz

# fix the permissions for the files directory
echo "*******************"
echo "set permissions of files in htdocs"
sudo chmod -R u+w $tempdir/$sitename/restore/htdocs
sudo chgrp -Rh $sitegroup $tempdir/$sitename/restore/htdocs
sudo chown -Rh $filesuser:$filesgroup $tempdir/$sitename/restore/htdocs/sites/default/files
sudo chmod -R g+w $tempdir/$sitename/restore/htdocs
	
# transfer the database info from the current site into a copy of 
# the new settings.php file
# store the modified settings.php file in a temp file
echo "*******************"
echo "save the current site's database info"
echo "*******************"
pushd $tempdir/$sitename/restore/htdocs/sites/default 1>/dev/null
rm -f settings.php.xfer_db_url
xfer_db_url.sh $drupalsite/sites/default/settings.php settings.php settings.php.xfer_db_url
if [ "$?" -ne "0" ]; then
	error_exit "xfer_db_url didn't work"
fi
mv -f settings.php.xfer_db_url settings.php
popd 1>/dev/null

# put the site into offline mode
echo "*******************"
echo "put site offline"
drush $alias vset --always-set site_offline 1

# update the database
echo "*******************"
echo "restore the Drupal database"
`drush $alias sql-connect` < $tempdir/$sitename/restore/data.sql

# update the file system
echo "*******************"
echo "restore the Drupal file system"
pushd $drupalsite 1>/dev/null
cd ..
if [ -d htdocs_old ]
then
	echo "deleting old htdocs"
	sudo rm -r htdocs_old
fi
echo "saving current htdocs to htdocs_old"
sudo mv htdocs htdocs_old
echo "moving restored htdocs into place"
sudo mv $tempdir/$sitename/restore/htdocs .

# put the site into back into online mode
echo "*******************"
echo "put site on line"
drush $alias vset --always-set site_offline 0

# go home
echo "*******************"
popd 1>/dev/null

# clean up temp directory
echo "cleaning up"
if [ -d "$tempdir/$sitename/restore" ]
then
	echo "deleting temp restore directory"
	sudo rm -r $tempdir/$sitename/restore
fi
echo "Done."

