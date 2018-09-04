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
#!/bin/bash

RPM_BUILD_ROOT="$TMP_DIR/root/rpmbuild/BUILDROOT/"
RPM_ROOT="$TMP_DIR"
IN_FILE="$DEB_URLS"
COUNTER=0

if [ -s "$RPM_LOG" ]; then
        mv "$RPM_LOG" "$RPM_LOG.old"
fi
touch "$RPM_LOG"
echo "Log created $NOW" >> "$RPM_LOG"

if [ -s "$RPM_MANIFEST" ]; then
        mv "$RPM_MANIFEST" "$RPM_MANIFEST.old"
fi
touch "$RPM_MANIFEST"
echo "Manifest created $NOW" >> "$RPM_MANIFEST"


if [ $# -ne 0 ]; then
	IN_FILE=$1
	if [ ! -e $IN_FILE ]; then
		if [ ! -s $IN_FILE ]; then
			echo "$IN_FILE File for scripts/build_rpms.sh does not exist or is empty"
			echo "perhaps check the options to rpm_maker?"
			exit 127
		fi
	fi
fi

if [ -s $IN_FILE ]; then
	COUNTER_MAX=$(wc -l < $IN_FILE)
elif [ -e $IN_FILE ]; then
	echo "deb urls list is empty. exiting"
	exit 127
fi

if [ ! -d "$RPM_ROOT" ]; then
  mkdir -p $RPM_ROOT
fi

if [ ! -d "$DEBS_DIR" ]; then
  mkdir -p $DEBS_DIR
fi

if [ ! -d "$RPM_BUILD_ROOT" ]; then
  mkdir -p $RPM_BUILD_ROOT
fi

if [ ! -d "$BUILT_RPMS_DIR" ]; then
  mkdir -p $BUILT_RPMS_DIR
fi

sort $IN_FILE | uniq -u | while read -r line || [[ -n "$line" ]]; do
	trap "exit" INT
	filename="$line"
	echo "filename is $filename"
	tmpurl=$(echo $filename | grep -E 'https.*?\.deb' -o)
	echo "tmpurl is $tmpurl"
	tmpfile=$(echo $tmpurl | grep -E '[^/]+(?=/$|$)' -o)
	echo "arch is $ARCH"

	tmppath=$DEBS_DIR$tmpfile

	echo "tmpfile is $tmpfile"
	echo "processing "$tmppath
	if [ ! -f "$tmppath" ]; then
		echo "getting file"
		wget $filename -O $tmppath
	fi
	RET=$?
	echo "debs_only is $DEBS_ONLY"
	if [ $DEBS_ONLY != true ]; then
		if [ $RET -eq 0 ]; then
			cd $RPM_BUILD_ROOT
			sudo alien -r -g -v $tmppath >> "$RPM_LOG" 2>&1 | tee -a "$RPM_LOG"

			aliendir=$(find . -maxdepth 1 -type d -name '[^.]?*' -printf %f -quit)
			echo "aliendir is $aliendir"

			specfilename=$(find $RPM_BUILD_ROOT$aliendir -type f -name \*.spec)
			specfilename=$(basename $specfilename)
			echo "specfilename is $specfilename"

			if [ $ARCH=='amd64' ]; then
				adir=$(echo $specfilename | sed 's/spec/x86_64\//')
	        	else
				adir=$(echo $specfilename | sed 's/spec/x386\//')
		        fi
			echo "adir is $adir"

			mv "$RPM_BUILD_ROOT$aliendir" "$RPM_BUILD_ROOT$adir"

			specfilepath="$RPM_BUILD_ROOT$adir$specfilename"

			#edit spec file to remove unnecessary prefixes
			sudo sed -i '/^%dir/ d' $specfilepath

			cd $adir
			sudo rpmbuild -bb --rebuild --clean --rmsource --root $RPM_ROOT $specfilepath >> "$RPM_LOG" 2>&1 | tee -a "$RPM_LOG"
			fn=$(echo $adir | sed 's/\///' | sed 's/\.x/-x/' | awk '{print $1".rpm"}')
			mv $RPM_BUILD_ROOT*.rpm $BUILT_RPMS_DIR$fn
			echo $fn >> $RPM_MANIFEST
			cd $CWD
			if [ $CLEAN_SRC = true ]; then
				sudo rm -rf $RPM_BUILD_ROOT*
				rm $DEBS_DIR*
			fi
		else
			echo "unable to download $filename"
		fi
	fi
	COUNTER=$((COUNTER + 1))
	echo -ne "Building $COUNTER of $COUNTER_MAX RPMS"'\r'
done
exit 0
