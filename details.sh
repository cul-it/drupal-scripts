#!/bin/bash
# details.sh - lookup info for an alias

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


function usage {
  cat << EOF
Usage:
details.sh <alias>
EOF
  exit 1
}

if [ $# -ne "1" ]; then
  usage;
fi

alias="$1"

echo "******************"
echo "******************"
drush sa | grep "$alias"
targetsite=`drush site-alias --component=uri "$alias"`
[[ -n "$targetsite" ]] || error_exit "$alias is not a valid target alias"
db=`drush "$alias" status | grep "Database name" | awk 'NF>1{print $NF}'`
SERVER=`nslookup "$targetsite" | grep 'canonical name' | awk 'NF>1{print $NF}'`
echo "database $db"
echo "backups:"
find /libweb/restore/ -name "*${db}*"
echo "served by $SERVER"
echo "******************"
