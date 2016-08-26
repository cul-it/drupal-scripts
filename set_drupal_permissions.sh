#!/bin/bash
# set_drupal_permissions.sh - fix permissions and ownership in a drupal directory

# An error exit function
function error_exit
{
  echo "**************************************"
  echo "$1" 1>&2
  echo "**************************************"
  exit 1
}

function message
{
  echo ""
  echo "*************************************"
  echo "**"
  echo "** $1"
  echo "**"
  echo "*************************************"
  echo ""
}

SITEROOT="$1"
sitegroup="lib_web_dev_role"
filesgroup="apache"
filesuser=$USER

#make sure we've got an argument for the drupal site path
if [ $1 ]; then
  # be sure it's a Drupal site
  if [ -f $SITEROOT/misc/drupal.js ]; then

    # fix the permissions for the files directory
    message "set permissions of files in $SITEROOT"
    # chmods need sudo
    sudo chmod -R u+w $SITEROOT
    sudo chmod -R g+w $SITEROOT
    sudo chown -R $filesuser:$sitegroup $SITEROOT
    sudo chown -Rh $filesuser:$sitegroup $SITEROOT/sites
    sudo chown -Rh $filesgroup:$sitegroup $SITEROOT/sites/default/files
    sudo chmod -R g+s $SITEROOT/sites

    for f in $SITEROOT/sites/*/settings.php; do
      sudo chmod ugo-w $f
    done
    message "done setting permissions"

  else
    error_exit "$SITEROOT is not a Drupal site"
  fi

else
 error_exit "Usage: $0 /path/to/my/Drupal/site/htdocs "
fi
