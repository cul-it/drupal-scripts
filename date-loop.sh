#!/bin/bash

start_date=2011-11-01
num_months=30
for i in `seq 0 $num_months`
do
    date=`date +%Y-%m-%d -d "${start_date}+${i} month"`
    echo $date
done
