#!/bin/bash

# site-loop-test.sh - drupalgeddon-test each Drupal site on current server


FILES=/libweb/sites/*
for f in $FILES
do
  [ ! -f "$f/htdocs/sites/default/settings.php" ] && continue
  SITE=`echo "$f" | cut -d/ -f4`
  #echo "$SITE"
  cd "$f/htdocs"
  DRUPALVERSION=`drush core-status drupal-version --pipe`
  if [[ -z $DRUPALVERSION ]]; then continue; fi
  #echo "$DRUPALVERSION"
  SIMPLEVERSION=`echo "$DRUPALVERSION" | cut -d. -f1`
  if [ "$SIMPLEVERSION" = 7 ] ;
    then
    SERVER=`nslookup "$SITE" | grep 'canonical name = sf-lib-web-008'`
    echo -e "$DRUPALVERSION\t$SITE\t$SERVER"
    drush drupalgeddon-test
    drush asec
  else
    echo -e "$DRUPALVERSION\t$SITE\t"
 fi
done
