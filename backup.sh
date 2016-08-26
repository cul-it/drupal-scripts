#!/usr/bin/bash
# ./backup.sh database user password
if [ $# -ne 3 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 mysql_database_name mysql_user mysql_user_password"
    exit
fi
echo database is $1
echo user is $2
echo secret is $3
stamp=`date +'%Y-%m-%d-%H-%M-%S'`
mysqldump -u$2 -p$3 --add-drop-table $1 > $1-$stamp.sql
cd ..
# f has to be the last argument to gtar
/usr/sfw/bin/gtar -cpzf bkp/files-$stamp.tar.gz htdocs
cd bkp
ls -l