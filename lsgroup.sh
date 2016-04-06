#!/bin/bash
awk -F: -v group=$1 '
        NR==FNR && $1==group {
                gid=$3
                for (i=1; i<=split($4,a,","); i++) print a[i]
                next
        }
        NR!=FNR && $4==gid { print $1 }
' /etc/group /etc/passwd | sort -u
