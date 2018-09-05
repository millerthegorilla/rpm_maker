#    This file is part of rpm_maker.

#    rpm_maker is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    rpm_maker is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with rpm_maker.  If not, see <https://www.gnu.org/licenses/>.
#    (c) 2018 - James Stewart Miller
#!/bin/bash

IN_FILE="$LYNX_URLS"
OUT_FILE="$DEB_URLS"

if [ -s "$IN_FILE" ]; then
	COUNTER_MAX=$(wc -l < "$IN_FILE")
else
	echo "$IN_FILE File does not exist for scripts/lynxdump.sh"
	exit 127
fi
COUNTER=0

echo "processing binary urls with lynx - this might take some time"

if [ -s "$OUT_FILE" ]; then
	echo "$OUT_FILE - file exists and not empty.  Moving to $OUT_FILE.old"
	mv -- "$OUT_FILE" "$OUT_FILE".old
fi
touch -- "$OUT_FILE"

sort "$IN_FILE" | uniq -u | while read line || [[ -n "$line" ]]; do
	weblink=$(lynx -dump "$line" | grep -A 2 -P "web_link" | tr -d [:blank:] | tr -d '\n' | sed s/web_link//)
	lynx -dump "$weblink" |grep -P "(?!(.*changes)|(.*buildlog*.))https(.*)_($ARCH|all)" -o | awk '{print $1".deb"}' >> "$OUT_FILE"
	COUNTER=$((COUNTER + 1))
	echo -ne "Processing $COUNTER of $COUNTER_MAX Urls"'\r'
done
echo "$DEB_URLS"
echo "Binary deb url list contains $(wc -l < $DEB_URLS) addresses"  >> "$PKG_LOG" 2>&1 | tee -a "$PKG_LOG"
exit 0
