#!/bin/bash
# pantheon-module-check.sh - see if module is enabled for sites

if [ $# -ne 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <module name>"
    echo "module is like views"
    exit
fi

SEEKING=$1

for alias in $(drush sa)
do
  if [[ $alias == *".live" ]]; then
    DRUPAL=`drush $alias variable-get maintenance_mode_message`
    ERR=$?; if [[ $ERR != 0 ]]; then continue; fi
    NAME=`echo $alias  | cut -d. -f 2-3`
    LIST=`drush "$alias" pml --status=enabled --no-core --type=module --format=list`
    OUTPUT="$NAME"
    while read -r MODULE; do
        if [ "$MODULE" = "$SEEKING" ]; then
            OUTPUT="$NAME has $SEEKING enabled."
            break
        fi
    done <<< "$LIST"
    echo "$OUTPUT"
  fi
done
