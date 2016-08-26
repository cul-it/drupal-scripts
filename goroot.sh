#!/bin/bash
# goroot.sh @alias
# push directory and change to the root directory of the site in the alias
echo "pushd `drush sa "$1" --component=root`"
