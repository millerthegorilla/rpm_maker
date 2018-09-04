#!/bin/bash

IN_FILE="$PROJ_ROOT/lists/urls-for-lynx.list"
OUT_FILE="$PROJ_ROOT/lists/deburls.list"

if [ -s $IN_FILE ]; then
	COUNTER_MAX=$(wc -l < $IN_FILE)
else
	echo "$INFILE File does not exist for scripts/lynxdump.sh"
	exit 127
fi
COUNTER=0

echo "downloading binary urls with lynx - this might take some time"

if [ -s ${OUT_FILE} ]; then
	echo "$PROJ_ROOT/lists/deburls.list - file exists and not empty.  Moving"
	echo "to $PROJ_ROOT/lists/deburls.list.old"
	mv $PROJ_ROOT/lists/deburls.list $PROJ_ROOT/lists/deburls.list.old
fi
touch $OUT_FILE

sort $IN_FILE | uniq -u | while read line || [[ -n "$line" ]]; do
	weblink=$(lynx -dump $line | grep -A 2 -P "web_link" | tr -d [:blank:] | tr -d '\n' | sed s/web_link//)
	lynx -dump $weblink |grep -P "(?!(.*changes)|(.*buildlog*.))https(.*)_($ARCH|all)" -o | awk '{print $1".deb"}' >> $OUT_FILE 
	COUNTER=$((COUNTER + 1))
	echo -ne "Processing $COUNTER of $COUNTER_MAX Urls"'\r'
done
echo "Binary deb url list contains $(wc -l < $PROJ_ROOT/lists/deburls.list) addresses"
exit 0
