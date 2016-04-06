#!/bin/bash
# rebuild_all_test_sites.sh - prints svn up and dr-make.sh on each victoria02 site

set -e
src="/libweb/sites"
 
#enable for loops over items with spaces in their name
IFS=$'\n'
 
for dir in `ls "$src/"`
do
  if [ -d "$src/$dir/make/$dir" ]; then
  	echo -n "Want to update $dir ? (y/n/q) :"
  	read ANS
  	case $ANS in
  		y|Y)
  			svn update "$src/$dir/make/$dir"
  			dr-make.sh "@$dir"
  			;;
  		q|Q)
  			exit
  			;;
  	esac
  fi
done
