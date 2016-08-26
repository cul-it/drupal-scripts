#!/usr/bin/bash
# ./files_restore.sh tarball
if [ $# -ne 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 tarball"
    exit
fi
echo restoring $1 to local directory
# f has to be the last argument to gtar
/usr/sfw/bin/gtar -xvpzf $1
ls -l