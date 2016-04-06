#!/bin/bash

# site-version.sh - list version, host of each Drupal site on current server

#empty the temp file
> /tmp/site-versions.txt
FILES=/libweb/sites/*
for f in $FILES
do
  [ ! -f "$f/htdocs/sites/default/settings.php" ] && continue
  SITE=`echo "$f" | cut -d/ -f4`
  cd "$f/htdocs"
  DRUPALVERSION=`drush core-status drupal-version --pipe`
  if [[ -z $DRUPALVERSION ]]; then continue; fi
  HOSTNAME=`nslookup $SITE | grep Name | awk '{print $2}'`
  echo -e "$DRUPALVERSION\t$SITE\t$HOSTNAME" >> /tmp/site-versions.txt
done
date
sort -t$'\t' -k 3,3 -k 1,1 -k 2,2  /tmp/site-versions.txt
