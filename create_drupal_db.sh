#!/bin/bash

EXPECTED_ARGS=3
E_BADARGS=65
MYSQL=`which mysql`
USER=`whoami`

Q1="CREATE DATABASE IF NOT EXISTS $1;"
Q2="GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON $1.* TO '$2'@'localhost' IDENTIFIED BY '$3';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"

if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: $0 dbname dbuser dbpass"
  exit $E_BADARGS
fi

$MYSQL -e "$SQL" -u "$USER"
