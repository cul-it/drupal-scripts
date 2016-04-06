#!/bin/bash
# setup_cap_dev_site.sh - create the initial directory structure for capistrano under git

function usage {
  cat << EOF
Usage:
setup_cap_dev_site.sh [git_repo_name].git

git_repo_name must be a valid empty git repo on git.library.cornell.edu

Example:
setup_cap_dev_site.sh base7_library_cornell_edu2.git

makes a local directory called 'git_repo_name' and builds a skeletal capistrano
deploy development environment in it
EOF
  exit 1
}

if [ $# -ne "1" ]; then
  usage;
fi

# be sure it's a repo
git ls-remote "git@git.library.cornell.edu:$1" >/dev/null 2>&1
RESULT=$?
if [[ $RESULT != 0 ]]; then
  echo "$1 is not a git repo on git.library.cornell.edu"
  usage;
fi

# be sure it's not an empty repo
# victoria02 doesn't have --exit-code arg
#git ls-remote --heads --exit-code "git@git.library.cornell.edu:$1" || usage
if grep -q heads <<< `git ls-remote --heads "git@git.library.cornell.edu:$1"` ; then
  echo "repo is not empty!"
  usage;
fi

REPO="$1"
PROJECT="${REPO%.*}"
echo "repo $REPO"
echo "project $PROJECT"

mkdir "$PROJECT"
cd "$PROJECT"
git init
touch README.txt
git add README.txt
git commit -m 'first commit'
git remote add origin "git@git.library.cornell.edu:$REPO"
git push -u origin master

mkdir backup drupal_config private_files public

capify .

git subtree add --prefix cul_capistrano git@git.library.cornell.edu:cul_capistrano.git master --squash

# make the drupal make file
cat <<EOF >> drupal_config/local.make
; This file is the drush make file for this project
api = 2
core = 7.x
projects[drupal][version] = "7.26"
EOF

# make lists of enabled and disabled modules
touch drupal_config/enabled_modules.txt
touch drupal_config/disabled_modules.txt

# run the drupal make file
cd public
drush make -y --contrib-destination=sites/all --prepare-install ../drupal_config/local.make
cd ../

# make git ignore file
cat <<EOF >> .gitignore
# .gitignore
# Ignore configuration files that may contain sensitive information.
public/sites/*/*settings*.php
!public/sites/*/default.settings.php

# Ignore paths that contain generated content.
backup/
cache/
!**/ctools/**/cache/
public/sites/default/files
public/sites/default/tmp
private_files

# Ignore .htaccess files since servers want them to be empty
public/.htaccess
EOF



