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
  if [[ -z $DRUPALVERSION ]]; then continue; fi
  echo "$dir:Drupal $DRUPALVERSION" | tr : "\t"
  NODECOUNT=`drush sql-query "SELECT COUNT(*) AS 'N' from node" | tr 'N\n' ' '`
  SIMPLEVERSION=`echo "$DRUPALVERSION" | cut -f1 -d "."`
  echo "$dir:NodeCount:$NODECOUNT:$SIMPLEVERSION" | tr : "\t"
  ENABLED=`drush pm-list | grep Enabled | grep -o '(.\+)' | grep -o '[^()]\+' | tr '\n' ' ' && echo ""`
  IFS=' ' read -a array <<< "$ENABLED"
  for element in "${array[@]}"
  do
    echo "$dir:$element:$SIMPLEVERSION" | tr : "\t"
  done
done
