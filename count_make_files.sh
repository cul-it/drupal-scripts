#!/bin/bash
# count make files at a given date
# count_make_files.sh 2012-10-01
#  ~/scripts/date-loop.sh | xargs ~/scripts/count_make_files.sh

function counter
{

CHECKDATE=$1
svn update -q -r {$CHECKDATE}

if [ -d 'drupal_6/make' ] ;then
  D6=`ls drupal_6/make/*/*.make | wc -l`
else
  D6=0
fi
if [ -d 'drupal_7/make' ] ;then
  D7=`ls drupal_7/make/*/*.make | wc -l`
else
  D7=0
fi

echo "$CHECKDATE:$D6:$D7" | tr ":" "\t"
}


[ -d cul-drupal ] || svn co https://svn.library.cornell.edu/cul-drupal

cd cul-drupal

start_date=2011-11-01
num_months=30
for i in `seq 0 $num_months`
do
    date=`date +%Y-%m-%d -d "${start_date}+${i} month"`
    counter "$date"
done
