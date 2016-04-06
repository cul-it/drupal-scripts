#!/bin/bash
# aegir_make_platform.sh - drush make file into aegir platform

# An error exit function
function error_exit
{
  echo "**************************************"
  echo "$1" 1>&2
  echo "**************************************"
  exit 1
}

# First we define the function
function ConfirmOrExit() {
while true
do
echo -n "Please confirm (y or n) :"
read CONFIRM
case $CONFIRM in
y|Y|YES|yes|Yes) break ;;
n|N|no|NO|No)
echo Aborting - you entered $CONFIRM
exit
;;
*) echo Please enter only y or n
esac
done
echo You entered $CONFIRM. Continuing ...
}

# Make sure only root can run our script
if [[ $EUID -eq 0 ]]; then
  echo "Usage: $0 <make_file> <platform_name> "
  error_exit "This script can not be run with sudo powers."
fi

# check argument count
if [ $# -ne 2 ]; then
  error_exit "Usage: $0 <make_file> <platform_name>"
fi

HOST_MACHINE=`hostname`
MAKE_FILE=$1
PLATFORM=$2

platform_path="/var/aegir/platforms/$PLATFORM/"
productionsite="$SUDO_USER@$SOURCE_MACHINE:/libweb/sites/$productiondomain/htdocs/"

if [ -d "$platform_path" ]; then
  error_exit "Directory $platform_path already exists!"
fi

TEMP_PATH="/tmp/aegir_make_platform/"
mkdir -p "$TEMP_PATH"
TEMP_PATH="${TEMP_PATH}$PLATFORM"
drush make "$MAKE_FILE" "$TEMP_PATH"

# set up permissions for aegir
sudo chmod -R 775 "$TEMP_PATH"
sudo chmod -R 777 "${TEMP_PATH}sites/default/files/"
sudo chown -R aegir:aegir "$TEMP_PATH"
sudo mv "$TEMP_PATH" "/var/aegir/platforms/"

echo "Now do this:"
echo "  1. add a platform in aegir"
echo "    http://$HOST_MACHINE/node/add/platform"
echo "    the Name: should be $PLATFORM"
echo "    leave the Makefile: blank and the Web sever: the default"
echo "    Hit Save and wait for the Verify task to finish"
echo "You did this, right?"
ConfirmOrExit
echo "have a nice day"

