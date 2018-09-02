#!/bin/bash

CWD="$(pwd)"
DEBS_DIR="$CWD/debs/"
RPM_BUILD_ROOT="$CWD/root/rpmbuild/BUILDROOT/"
RPM_ROOT="$CWD"
BUILT_RPMS="$PROJ_ROOT/rpms/"
ARCH="amd64"
IN_FILE="$PROJ_ROOT/lists/deburls.list"

if [ ! -e "$PROJ_ROOT/log/rpms_manifest.log" ];then
	mv $PROJ_ROOT/log/rpms_manifest.log $PROJ_ROOT/log/rpms_manifest.log
fi
touch $PROJ_ROOT/log/rpms_manifest.log

if [ -s $IN_FILE ]; then
	COUNTER_MAX=$(wc -l < $IN_FILE)
else
	echo "$IN_FILE File for scripts/build_rpms.sh does not exist"
	echo "perhaps check the options to rpm_maker?"
	exit 127
fi
COUNTER=0

if [ -e $1 ]; then
	IN_FILE=$1
fi

if [ ! -s $IN_FILE ]; then
	echo "deb urls list does not exist"
	exit 127
fi

if [ $# -eq 0 ]
  then
    echo "you need to reference a list!"
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

if [ ! -d "$BUILT_RPMS" ]; then
  mkdir -p $BUILT_RPMS
fi


sort $IN_FILE | uniq -u | while read -r line || [[ -n "$line" ]]; do
	trap "exit" INT
	filename="$line"
	tmpurl=$(echo $filename | grep -E 'https.*?amd64\.deb' -o)
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
	if [ $? -ne 0 ]; then
		cd $RPM_BUILD_ROOT
		sudo alien -r -g -v $tmppath >> "$PROJ_ROOT/log/build_rpms.log" 2>&1 | tee -a "$PROJ_ROOT/log/build_rpms.log"

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
		sudo sed -i 's#%dir "/"##' $specfilepath
		sudo sed -i 's#%dir "/usr/bin/"##' $specfilepath
        	sudo sed -i 's#%dir "/usr/share/"##' $specfilepath
        	sudo sed -i 's#%dir "/usr/lib"##' $specfilepath
		if [ ! -d "$BUILT_RPMS" ]; then
  			mkdir $BUILT_RPMS
		fi
		cd $adir
		sudo rpmbuild -bb --rebuild --clean --rmsource --root $RPM_ROOT $specfilepath >> "$PROJ_ROOT/log/build_rpms.log" 2>&1 | tee -a "$PROJ_ROOT/log/build_rpms.log"
		fn=$(echo $adir | sed 's/\///' | sed 's/\.x/-x/' | awk '{print $1".rpm"}')
		mv $RPM_BUILD_ROOT*.rpm $BUILT_RPMS$fn
		echo fn >> $PROJ_ROOT/log/rpms_manifest.log
		cd $CWD
		sudo rm -rf $RPM_BUILD_ROOT*
		rm $DEBS_DIR*
	fi
	COUNTER=$((COUNTER + 1))
	echo -ne "Building $COUNTER of $COUNTER_MAX RPMS"'\r'
done
exit 0
