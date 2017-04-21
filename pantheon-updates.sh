#!/bin/bash
# pantheon-updates.sh - list module updates available for sites

for alias in $(drush sa)
do
  if [[ $alias == *".live" ]]
    then
    echo ""
    echo "************************"
    NAME=`echo $alias  | cut -d. -f 2-3`
    echo "$NAME"
    terminus remote:drush -q "$NAME" -- ups --pipe --security-only --check-disabled --update-backend=drupal
    echo ""
  fi
done
