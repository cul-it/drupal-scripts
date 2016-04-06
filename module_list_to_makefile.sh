#/bin/bash

# mkdule_list_to_makefile.sh <module list one per line>
# checks for latest version of each module based on Drupal core version of local site
# will report for Drupal 7 unless run in a Drupal 6 document root!

MISSING=
REPOS=
while read line; do
VERS=`drush rl "$line" 2>/dev/null | grep Recommended | sed 's/ \+/\$/g' | cut -d\$ -f 2 | cut -b 5-`
if [ -z "$VERS" ]; then
  REPO=`svn info "https://svn.library.cornell.edu/$line" 2>/dev/null | grep URL | cut -d\  -f 2`
  if [ ! -z "$REPO" ]; then
    THEME=`svn info "https://svn.library.cornell.edu/$line/trunk/theme" 2>/dev/null | grep URL | cut -d\  -f 2`
    if [ -z "$THEME" ]; then
      echo "projects[$line][type] = \"module\""
      echo "projects[$line][download][type] = \"svn\""
      echo "projects[$line][download][url] = \"https://svn.library.cornell.edu/$line/trunk/module\""
      echo "projects[$line][revision] = \"HEAD\""
      echo "projects[$line][subdir] = \"custom\""
    else
      echo "projects[$line][type] = \"theme\""
      echo "projects[$line][download][type] = \"svn\""
      echo "projects[$line][download][url] = \"https://svn.library.cornell.edu/$line/trunk/theme\""
      echo "projects[$line][revision] = \"HEAD\""
      echo "projects[$line][subdir] = \"custom\""
    fi
  else
    MISSING="$MISSING:$line"
  fi
else
  echo "projects[$line][version] = \"$VERS\""
  echo "projects[$line][subdir] = \"contrib\""
fi
done < "$1"

echo "$MISSING" | tr : "\n"
