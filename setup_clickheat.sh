#!/bin/bash
# sudo setup_clickheat.sh <domain_name>
# setup clickheat module and library
# run in a working Drupal install where
# sites/all/libraries/clickheat
# and
# sites/all/modules/contrib/libraries
# and
# sites/all/modules/contrib/click_heatmap
# are all present but nothing is enabled yet

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
if [[ $EUID -ne 0 ]]; then
  echo "Usage: sudo $0 <domain_name>"
  error_exit "This script has to be run with sudo powers."
fi

EXPECTED_ARGS=1
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: sudo $0 <domain_name>"
  error_exit "need domain name."
fi

DOMAIN="$1"
CLICKHEATDIR="/libweb/sites/$DOMAIN/clickheat"
LIBRARY="/libweb/sites/$DOMAIN/htdocs/sites/all/libraries/clickheat"
CONFIG="$LIBRARY/config/config.php"
# relative path from clickheat module to CLICKHEATDIR
RELPATH="../../../../../clickheat"

if [ -d "$LIBRARY" ]; then
  # set up permissions for library
  DIRS="config cache logs"
  for d in $DIRS
  do
    chgrp 'apache' "$LIBRARY/$d"
    chmod g+w "$LIBRARY/$d"
  done
  # redirect paths stored in clickheat lib to directories that are not copied when
  # the site moves to another machine so the logs don't get mixed
  if [ ! -d "$CLICKHEATDIR" ]; then
    mkdir -p "$CLICKHEATDIR/clickheat_logs"
    mkdir -p "$CLICKHEATDIR/clickheat_cache"
    chown -R 'apache' "$CLICKHEATDIR"
    chmod -R u+w "$CLICKHEATDIR"
  fi
  # module stores paths in the library's configuration file
  # overwrite config lines that store file paths in place
  sed -i "/logPath/c\'logPath' => '$RELPATH/clickheat_logs/'," "$CONFIG"
  sed -i "/cachePath/c\'cachePath' => '$RELPATH/clickheat_cache/'," "$CONFIG"
  # libraries module has to be enabled BEFORE click_heatmap
  cd "/libweb/sites/$DOMAIN/htdocs"
  drush en libraries
  drush en click_heatmap
else
  echo "You need to install the clickheat library in $LIBRARY"
fi
