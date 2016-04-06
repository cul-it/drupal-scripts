#!/bin/bash
# enabled_modules_all_test_sites.sh - prints svn up and dr-make.sh on each victoria02 site
#
# drush @socialwelfare.test2.library.cornell.edu pml -p --status=enabled --no-core
# drush @socialwelfare.test2.library.cornell.edu core-status version --pipe | head -n1

#set -e

# for ALIAS in `drush site-alias`
# do
# 	drush $ALIAS core-status | grep 'Drupal bootstrap       :  Successful' > /dev/null || continue
# 	DRUPALVERS=`drush $ALIAS core-status version --pipe | grep drupal | cut -c 16`
#   	for MODULE in `drush $ALIAS pml -p --status=enabled --no-core --type=module`
#   	do
# 		echo "$ALIAS,$DRUPALVERS,$MODULE"
# 	done
# done

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
  IGNORE=`drush pm-refresh`
  UPDATES=`drush pm-update --pipe --security-only | wc -l`
  echo "site:$dir:$DRUPALVERSION:$UPDATES" | tr : "\t"
 done
