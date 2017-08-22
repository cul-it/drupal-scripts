#!/bin/bash
# pantheon-updates.sh - list module updates available for sites

OUTFILE="pantheon-updates-out.txt"

rm "$OUTFILE"

for alias in $(drush sa)
do
  if [[ $alias == *".live" ]]
    then
    echo ""
    echo "************************"
    NAME=`echo $alias  | cut -d. -f 2-3`
    echo "$NAME"
    echo -n "$NAME - " >> "$OUTFILE"
    terminus 2>/dev/null >>"$OUTFILE" remote:drush "$NAME" -- ups --pipe --security-only --check-disabled --update-backend=drupal
    echo ""
    echo "."  >> "$OUTFILE"
  fi
done

echo "$OUTFILE"
grep ' - [^\.]' "$OUTFILE"
