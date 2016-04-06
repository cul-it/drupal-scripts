#!/usr/bin/bash
# ./db_restore.sh database user password
if [ $# -ne 4 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 new_mysql_database_name new_mysql_user new_mysql_user_password sql_file"
    exit
fi
echo database is $1
echo user is $2
echo secret is $3
echo database is coming from $4
mysql -u$2 -p$3 $1 < $4
