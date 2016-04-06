#!/bin/bash
# substitute the $db_url = xxx line in the target file with one from the source file
# put the result in the new output file

if [ $# -ne 3 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 source_file target_file output_file"
    exit 1
fi

if [ ! -f $1 ]
then
    echo "Source file [$1] not found - Aborting"
    exit 1
fi

if [ ! -f $2 ]
then
    echo "Target file [$2] not found - Aborting"
    exit 1
fi

if [ -f $3 ]
then
    echo "Output file [$3] already exists - Aborting"
    exit 1
fi


# find the last occurence of the pattern without toc (Mac)
source_version=`cat $1 | awk '{print NR,$0}' | sort -nr | sed 's/^[0-9]* //' \
| grep '[ ]*$db_url[ ]*=' -m 1`

# find the last occurence of the pattern without toc (Mac)
dest_version=`cat $2 | awk '{print NR,$0}' | sort -nr | sed 's/^[0-9]* //' \
| grep '[ ]*$db_url[ ]*=' -m 1`

# replace ALL occurences of darn thing
sed 's|'"$dest_version"'|'"$source_version"'|g' <$2 >$3
