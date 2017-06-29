#!/bin/bash
# pantheon-module-check.sh - see if module is enabled for sites

if [ $# -ne 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <package name>"
    echo "package is like mail,media,"
    exit
fi

PACKAGE=$1

for alias in $(drush sa)
do
  if [[ $alias == *".live" ]]
    then
    echo ""
    echo "************************"
    NAME=`echo $alias  | cut -d. -f 2-3`
    echo "$NAME"
    terminus --yes remote:drush -q "$NAME" -- pml --no-core --type=module --status=enabled --package="$PACKAGE"
    echo ""
  fi
done
