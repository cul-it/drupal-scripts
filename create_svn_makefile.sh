#!/bin/bash

EXPECTED_ARGS=1
E_BADARGS=65
SVN=`which svn`

if [ $# -ne $EXPECTED_ARGS ]
then
  echo "does the initial checkin of the drush make file for a new site"
  echo "Usage: $0 test_server_domain_name"
  exit $E_BADARGS
fi

DOMAIN="$1"
MAKEDIR="/libweb/sites/$1/make"
REPOSITORY="https://svn.library.cornell.edu/cul-drupal/drupal_7/make/$1"
OLDFILE="$1_old"

if [ -d $MAKEDIR ]
  then
  cd $MAKEDIR
  $SVN import $DOMAIN $REPOSITORY -m "Initial import of make file"
  mv $DOMAIN $OLDFILE
  $SVN co $REPOSITORY
else
  echo "$MAKEDIR does not exist - be sure the domain is set up on the server!"
fi
