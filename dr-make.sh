#!/bin/bash
# dr-make.sh - drush make for Drupal sites
#
# sudo ./dr-make.sh <alias> [<sitegroup>]
#	where <alias> is an alias from etc/drush/ (with the @ prefix)
#	and [<sitegroup>] is an optional argument - if present it becomes sitegroup
#
### svn:keyword $Date: 2016-03-03 10:48:13 -0500 (Thu, 03 Mar 2016) $
### svn:keyword $Author: jgr25 $
### svn:keyword $Rev: 3297 $
### svn:keyword $URL: https://svn.library.cornell.edu/cul-drupal/scripts/dr-make.sh $
# Global vars
sitedir="/libweb/sites"
sitegroup="lib_web_dev_role"
# on artslib user:group is webmstr:diglibdev-role
# on copia user:group is jgr25:webmstr
# on libdev user:group is jgr25:nobody
# on victoria02 user:group is jgr25:apache
# apache is both a user and a group
phprunner="apache"
filesuser=$USER

# sudo just to get the password thing over with
sudo echo "Thanks for that. Some things here have to use sudo and others must not."

drush --version

# An error exit function

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

# Make sure only root can run our script
if [[ $EUID -eq 0 ]]; then
 	echo "Usage: $0 [<alias>] [<sitegroup>]"
	error_exit "This script has to be run without sudo powers, though some steps require sudo."
fi

# try to find alias without argument using standard directory layout
# /libweb/sites/[sitename]/make/[sitename]/[sitename].make
# assumes you are here .....^
sitename=`echo ${PWD#/libweb/sites/} | cut -d "/" -f1`
makefile="$sitename/$sitename.make"
echo ".make file = $makefile"
echo "sitename = $sitename"
if [ -z "$sitename" ]; then
	# check argument count
	if [ $# -lt 1 ]; then
		echo "Usage: sudo $0 <alias> [<sitegroup>]"
		echo "Here is a list of the aliases:"
		drush site-alias | sort
		exit 1
	fi

	# first argument should be an alias
	sitename=`drush site-alias --component=uri "$1"`
	[[ -n "$sitename" ]] || error_exit "$1 is not a valid alias"

	alias="$1"

	# optional second argument is sitegroup
	if [ $# -eq 2 ]; then
		sitegroup="$2"
	fi

	#go to the make dir
	cd $sitedir/$sitename/make
	if [ "$?" -ne "0" ]; then
		error_exit "couldn't get to $sitedir/$sitename/make"
	fi

else
	alias="@"
	alias+=$sitename

	# test the alias
	sitename2=`drush site-alias --component=uri "$alias"`
	[[ -n "$sitename2" ]] || error_exit "$alias is not a valid alias"
fi

echo "*******************"
echo "site name: $sitename"
echo "*******************"

if [ -d "$sitedir/$sitename/make/$sitename/.git" ]; then
	error_exit "detected .git in make directory. Use dr-make-git.sh from https://github.com/cul-it/drupal-site-moves.git instead!"
fi

echo "*******************"
echo "grab the latest drush make file from svn"
echo "*******************"
svn up $sitename
if [ "$?" -ne "0" ]; then
	error_exit "couldn't do svn up $sitename"
fi

# check for configuration file in with make file
# example file:
# DRUPALSITESPATH="../htdocs"
configuration=$sitename/dr-make.conf
if [[ -f $configuration ]]; then

	echo "*******************"
	echo "using configuration file: $configuration"
	echo "*******************"

	. $configuration
fi

if [ -f $sitename/*.alias.drushrc.php ]; then
	# copy any production site alias files into /etc/drush/
	echo "*******************"
	echo "copying production site alias "
	echo "*******************"
	cp -f $sitename/*.alias.drushrc.php /etc/drush/
else
	echo "*******************"
	echo "No aliases to copy. $sitename/*.alias.drushrc.php"
	echo "*******************"
fi

# supply defaults for anything that might be in the configuration file
DRUPALSITESPATH=${DRUPALSITESPATH:-"$sitedir/$sitename/htdocs"}

#remove the old build - sudo
if [ -d target ]
then
	rm -rf target
fi
echo "*******************"
echo "test making target directory"
echo "*******************"
if mkdir target; then
	rm -r target
else
	error_exit "Can't make target directory"
fi

#if there is an installed drupal site
echo "*******************"
echo "making new working copy of $sitename"
echo "*******************"
INSTALLED=`drush --root=$DRUPALSITESPATH --pipe status | grep 'drupal_bootstrap=Successful'`
if [ -z "$INSTALLED" ]
then
	# drupal is not installed in this site - check if something else is wrong
	# if settings.php is there someone once expected the site to work
	if [ -f $DRUPALSITESPATH/sites/default/settings.php ]; then
		error_exit "the site is partially built but can not be bootstrapped so we can't update it! Check site status."
	fi
	update=0
	#make the new version with a installable default directory
	drush make --prepare-install --working-copy $sitename/$sitename.make target
	if [ "$?" -ne "0" ]; then
		error_exit "couldn't drush make new site"
	fi
else
	update=1
	#make the new version of the site
	drush make --working-copy $sitename/$sitename.make target
	if [ "$?" -ne "0" ]; then
		error_exit "drush make didn't work"
	fi

	# put the site into offline mode
	echo "*******************"
	echo "put site offline"
	echo "*******************"
	drush $alias vset --always-set site_offline 1
	if [ "$?" -ne "0" ]; then
		error_exit "site couldn't go offline"
	fi
	drush $alias vset --always-set maintenance_mode 1
	if [ "$?" -ne "0" ]; then
		error_exit "site couldn't go offline"
	fi
	drush cache-clear all

	#copy the default directory from the site over the target default directory
	echo "*******************"
	echo "copying current site sites/default"
	echo "*******************"
	# rsync needs sudo
	sudo rsync -ac --delete --perms --owner --group --times $DRUPALSITESPATH/sites/default/ target/sites/default/
	if [ "$?" -ne "0" ]; then
		error_exit "site couldn't copy"
	fi

	#make sure we can write over settings.php
	echo "*******************"
	echo "relaxing permissions in sites/default g+w"
	echo "*******************"
	# chmod needs sudo
	sudo chmod g+w $DRUPALSITESPATH/sites/default/settings.php
	if [ "$?" -ne "0" ]; then
		error_exit "site couldn't relax"
	fi
fi

# fix the permissions for the files directory
echo "*******************"
echo "set permissions of files in htdocs"
# chmods need sudo
sudo chmod -R u+w target
sudo chmod -R g+w target
sudo chgrp -R $sitegroup target
sudo chown -Rh $filesuser:$sitegroup target/sites
sudo chown -Rh $phprunner:$sitegroup target/sites/default/files
sudo chmod -R g+s target/sites

if [ -d target/sites/default/image_import ]
then
	# chown needs sudo
	sudo chown -Rh $phprunner:$sitegroup target/sites/default/image_import
fi

if [ -d target/sites/all/libraries/tinymce ]
then
	# be sure the download from the 'latest version' link actually produced a file
	echo "*******************"
	echo "checking tinymce"
	echo "*******************"
	if [ -a target/sites/all/libraries/tinymce/jscripts/tiny_mce/tiny_mce.js ]
	then
		ls target/sites/all/libraries/tinymce/jscripts/tiny_mce/
	elif [ -a target/sites/all/libraries/tinymce/js/tinymce/tinymce.min.js ]
		then
		ls target/sites/all/libraries/tinymce/js/tinymce/
	else
		error_exit "tinyMCE download did not work"
	fi
fi

# find out where contributed modules are stored
if [ -d target/sites/all/modules/contributed ]
then
	MODULESDIR="target/sites/all/modules/contributed"
elif [ -d target/sites/all/modules/contrib ]
then
	MODULESDIR="target/sites/all/modules/contrib"
elif [ -d target/sites/all/modules ]
then
	MODULESDIR="target/sites/all/modules"
else
	mkdir target/sites/all/modules
	MODULESDIR="target/sites/all/modules"
fi

if [ -d target/sites/all/SolrPhpClient ]
then
	#apachesolr.make somehow places this here instead of where it's needed
	echo "*******************"
	echo "moving SolrPhpClient (hack)"
	echo "*******************"
	mv target/sites/all/SolrPhpClient $MODULESDIR/apachesolr/
fi

if [ -d target/sites/all/libraries/swfupload ]
then
	#apachesolr.make somehow places this here instead of where it's needed
	echo "*******************"
	echo "moving swfupload (hack)"
	echo "*******************"
	mv target/sites/all/libraries/swfupload/swfupload.js $MODULESDIR/image_fupload/swfupload/
	mv target/sites/all/libraries/swfupload/plugins/swfupload.queue.js $MODULESDIR/image_fupload/swfupload/
	mv target/sites/all/libraries/swfupload/Flash/swfupload.swf $MODULESDIR/image_fupload/swfupload/
	rm -r target/sites/all/libraries/swfupload
fi

if [ -d target/sites/all/libraries/jquery.cycle ]
then
	#set all read for this directory so copy/migrate works
	echo "*******************"
	echo "fixing permission of jquery.cycle"
	echo "*******************"
	sudo chmod -R a+r target/sites/all/libraries/jquery.cycle
fi

if [ -d target/sites/all/modules/feeds_jsonpath_parser ]
then
	#set all read for this directory so copy/migrate works
	echo "*******************"
	echo "fixing permission of feeds_jsonpath_parser"
	echo "*******************"
	sudo chmod -R a+r target/sites/all/modules/feeds_jsonpath_parser
fi

if [ -d $MODULESDIR/swftools/shared/flowplayer3 ]
then
	# move any associated flowplayer plugins
	if [ -d target/sites/all/libraries/flowplayer_audio ]
	then
		echo "*******************"
		echo "moving flowplayer.audio"
		echo "*******************"

		for f in target/sites/all/libraries/flowplayer_audio/*.swf
		do
			mv "$f" $MODULESDIR/swftools/shared/flowplayer3/
		done
	fi
	if [ -d target/sites/all/libraries/flowplayer_rtmp ]
	then
		echo "*******************"
		echo "moving flowplayer.rtmp"
		echo "*******************"
		for f in target/sites/all/libraries/flowplayer_rtmp/*.swf
		do
			mv "$f" $MODULESDIR/swftools/shared/flowplayer3/
		done
	fi
fi

if [ -d $MODULESDIR/sass ]
	then
	echo "found sass"
	if [ -d target/sites/all/libraries/phamlp ]
		then
		echo "*******************"
		echo "moving phamlp"
		echo "*******************"
		mv target/sites/all/libraries/phamlp $MODULESDIR/sass/
	fi
fi

if [ -d $MODULESDIR/print ]
then
	#move any libraries print needs
	if [ -d target/sites/all/libraries/tcpdf ]
	then
		#be sure we actually got the download correctly
		if [ -d target/sites/all/libraries/tcpdf/images -a -d target/sites/all/libraries/tcpdf/cache ]
		then
			#apachesolr.make somehow places this here instead of where it's needed
			echo "*******************"
			echo "moving tcpdf for print (hack)"
			echo "...and setting owner"
			echo "*******************"
			mv target/sites/all/libraries/tcpdf $MODULESDIR/print/
			# chown needs sudo
			sudo chown apache $MODULESDIR/print/tcpdf/images
			sudo chown apache $MODULESDIR/print/tcpdf/cache
		else
			error_exit "tcpdf download did not work"
		fi
	fi
fi

if [ -a $MODULESDIR/feedapi/parser_simplepie/simplepie/simplepie.inc ]
then
	# move this file into place
	echo "*******************"
	echo "moving simplepie.inc for feedapi"
	echo "*******************"
	mv $MODULESDIR/feedapi/parser_simplepie/simplepie/simplepie.inc $MODULESDIR/feedapi/parser_simplepie/
	rm -r $MODULESDIR/feedapi/parser_simplepie/simplepie
fi

if [ -a $MODULESDIR/feeds/libraries/simplepie/simplepie.inc ]
then
	# move this file into place
	echo "*******************"
	echo "moving simplepie.inc for feeds"
	echo "*******************"
	mv $MODULESDIR/feeds/libraries/simplepie/simplepie.inc $MODULESDIR/feeds/libraries/simplepie.inc
	rm -r $MODULESDIR/feeds/libraries/simplepie
fi

if [ -a $MODULESDIR/image/image.imagemagick.inc ]
then
	# move this file into place
	echo "*******************"
	echo "moving image.imagemagick.inc"
	echo "*******************"
	cp $MODULESDIR/image/image.imagemagick.inc target/includes
fi

if [ -a $MODULESDIR/supercron/supercron.php ]
then
	# move this file into place
	echo "*******************"
	echo "moving supercron.php"
	echo "*******************"
	cp $MODULESDIR/supercron/supercron.php target/
fi

if [ -d target/sites/all/libraries/getid3_full_install ]
then
	# take the part we want and delete the rest!
	echo "*******************"
	echo "preparing getid3"
	echo "*******************"
	mv target/sites/all/libraries/getid3_full_install/getid3 target/sites/all/libraries/
	rm -R target/sites/all/libraries/getid3_full_install
fi

if [ -a $MODULESDIR/kaltura/crossdomain.xml ]
then
	# move this file into place
	echo "*******************"
	echo "moving kaltura crossdomain.xml"
	echo "*******************"
	cp $MODULESDIR/kaltura/crossdomain.xml target/
fi

if [ -d target/sites/all/libraries/clickheat ]
then
	# configure subdirectory permissions for clickheat/click_heatmap
	echo "*******************"
	echo "setting permissions for clickheat"
	echo "*******************"
	sudo chown -Rh $phprunner target/sites/all/libraries/clickheat/cache
	sudo chown -Rh $phprunner target/sites/all/libraries/clickheat/config
	sudo chown -Rh $phprunner target/sites/all/libraries/clickheat/logs
	sudo chmod -R u+w target/sites/all/libraries/clickheat/cache
	sudo chmod -R u+w target/sites/all/libraries/clickheat/config
	sudo chmod -R u+w target/sites/all/libraries/clickheat/logs
fi

echo "*******************"
echo "cleaning up .htaccess files"
echo "*******************"

if [ -a target/.htaccess ]
then
	#server configuration handles this!
	rm -f target/.htaccess
fi

# now puppet configuration handles .htaccess files in
# sites/default/files
# sites/default/tmp
# ../private_files

if [ -d $MODULESDIR/mimedetect ]
then
	# set the correct location of a magic file
	# see http://www.clearlysecure.com.au/node/81
	echo "*******************"
	echo "help mimedetect find the magic file"
	echo "*******************"
	grep "mimedetect_magic" target/sites/default/settings.php
	if [ $? -eq 1 ]
	then
		sudo chmod u+w target/sites/default/settings.php
		echo "\$conf['mimedetect_magic'] = '/usr/share/file/magic.mime';" >> target/sites/default/settings.php
		sudo chmod u-w target/sites/default/settings.php
	else
		echo "mimedetect_magic found"
	fi
fi

if [ -a target/robots.txt ]
then
	#move the default Drupal robots.txt file out of the way but save it for the production sites
	echo "*******************"
	echo "saving the robots.txt file for the production version"
	echo "*******************"
	mv target/robots.txt target/production_robots.txt
fi
echo "*******************"
echo "making a restrictive robots.txt file"
echo "*******************"
echo -e 'User-agent: *\nDisallow: /' > target/robots.txt

if [ $update -eq 0 ]
then
	# Drupal will complain during install if it can't write to the settings.php file
	# chown needs sudo
	sudo chown -Rh $phprunner:$sitegroup target/sites/default/settings.php
	sudo chmod u=rw,g=r,o= target/sites/default/settings.php
else
	sudo chown -Rh $phprunner:$sitegroup target/sites/default/settings.php
	sudo chmod u=r,g=r,o= target/sites/default/settings.php
fi

#overwrite site with new version
echo "*******************"
echo "overwriting $sitename with new copy but leaving any extra files"
echo "*******************"
# rsync needs sudo
sudo rsync -ac --include=".svn/" --include=".git/" target/* $DRUPALSITESPATH || error_exit "rsync 1 failed"
# make sure modules/themes are an exact copy
sudo rsync -avc --include=".svn/" --include=".git/" --delete target/sites/all/* $DRUPALSITESPATH/sites/all || error_exit "rsync 2 failed"

if [ $update -eq 1 ]
then
	cd $DRUPALSITESPATH

	#run update.php
	echo "*******************"
	echo "running update.php"
	echo "*******************"
	drush $alias updatedb

	# put the site into back into online mode
	echo "*******************"
	echo "put site on line"
	drush $alias vset --always-set site_offline 0
	drush $alias vset --always-set maintenance_mode 0
	drush cache-clear all
fi

echo "*******************"
echo "Done."
echo "*******************"
