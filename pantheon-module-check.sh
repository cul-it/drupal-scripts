#!/bin/bash
# pantheon-module-check.sh - see if module is enabled for sites

if [ $# -ne 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <module/theme name>"
    exit
fi

MODULE=$1

for alias in $(drush sa)
do
  if [[ $alias == *".live" ]]
    then
    echo ""
    echo "************************"
    NAME=`echo $alias  | cut -d. -f 2-3`
    echo "$NAME"
    terminus remote:drush -q "$NAME" -- pml --status=enabled | grep "$MODULE" || echo "$MODULE is not enabled"
    echo ""
  fi
done
