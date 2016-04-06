#!/bin/bash

# site-loop.sh - list each Drupal site on current server


FILES=/libweb/sites/*
for f in $FILES
do
  [ ! -f "$f/htdocs/sites/default/settings.php" ] && continue
  SITE=`echo "$f" | cut -d/ -f4`
  echo "$SITE"
  cd "$f/htdocs"
  DRUPALVERSION=`drush core-status drupal-version --pipe`
  if [[ -z $DRUPALVERSION ]]; then continue; fi
  echo "$DRUPALVERSION"
  SIMPLEVERSION=`echo "$DRUPALVERSION" | cut -d. -f1`
  ENABLED=`drush pml --status=enabled --pipe`
  mkdir -p "/users/jgr25/module_lists/$SIMPLEVERSION"
  echo "$ENABLED" > "/users/jgr25/module_lists/$SIMPLEVERSION/$SITE.txt"
done
