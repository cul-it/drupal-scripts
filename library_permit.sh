#!/bin/bash
# library_permit.sh - check value of a variable in each site
#

DRUPALSITES=
drush core-status drupal-version --pipe

cd /libweb/sites/
dirs=`ls -d */ | sed s'/.$//'`
for dir in $dirs
do
  SITE="/libweb/sites/$dir/htdocs"
  cd $SITE
  DRUPALVERSION=`drush core-status drupal-version --pipe`
  if [[ -z $DRUPALVERSION ]]; then echo "non-drupal: $dir"; continue; fi
  # result is single blank when the the database is not working
  CONNECT=`drush sql-connect | tr -d ' '`
  if test -z "$CONNECT" ; then echo "database missing: $dir"; continue; fi
  echo "directory: `pwd`"
  VAL=`drush vget cul_login_block_required_permit`
  echo "site:$dir:$DRUPALVERSION:$VAL" | tr : "\t"
 done
