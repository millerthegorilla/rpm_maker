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

PROJ_ROOT="$(pwd)"'/'

#defaults
typeset -A config # init array
config=( # set default values in config array
[TMP_DIR]="$PROJ_ROOT"'./tmp/'
[LIST_DIR]="$PROJ_ROOT"'lists/'
[LOG_DIR]="$PROJ_ROOT"'logs/'
[DEBS_DIR]="$TMP_DIR"'debs/'
[BUILT_RPMS_DIR]="$PROJ_ROOT"'rpms/'
[DEB_URLS]="$LIST_DIR"'deburls.list'
[LYNX_URLS]="$LIST_DIR"'urls_for_lynx.list'
[ARCH]="amd64"
[TEAM]="kxstudio-debian"
[PPA]="plugins"
[CLEAN_SRC]=true
[DEBS_ONLY]=false
[PACKAGE]=""
[PKG_LOG]="$LOG_DIR"'getpkgurls.log'
[RPM_LOG]="$LOG_DIR"'build_rpms.log'
[RPM_MANIFEST]="$LOG_DIR"'rpms.manifest'
[LOG_CREATE_MSG]='Log created : '"$(date +"%m-%d-%Y-%T")"
[CLEAN]=false
)

while read line
do
    if echo $line | grep -F = &>/dev/null
    then
        varname=$(echo "$line" | cut -d '=' -f 1)
        config[$varname]=$(echo "$line" | cut -d '=' -f 2-)
    fi
done < myscript.conf
export config

filename=config[DEB_URLS]

if [ ! -d config[TMP_DIR] ]; then
	mkdir -p config[TMP_DIR]
fi

if [ ! -d config[LIST_DIR] ]; then
	mkdir -p config[LIST_DIR]
fi

if [ ! -d config[LOG_DIR] ]; then
	mkdir -p config[LOG_DIR]
fi

if [ -s config[PKG_LOG] ]; then
        mv config[PKG_LOG] config[PKG_LOG]'.old'
fi
touch "$PKG_LOG"
echo "$LOG_CREATE_MSG" >> "$PKG_LOG"

packages()
{
	if [ -s "$LYNX_URLS" ]; then
		mv "$LYNX_URLS" "$LYNX_URLS"'.old'
	fi
	touch "$LYNX_URLS"
	python3 "$PROJ_ROOT"'scripts/getpkgurls.py'
}

lynxdump()
{
	"$PROJ_ROOT"'scripts/lynxdump.sh'
}

rpmbuild()
{
	echo "Building RPMS from list at "$PROJ_ROOT$filename""
	cd $TMP_DIR
	"$PROJ_ROOT"'scripts/build_rpms.sh' "$filename"
}

usage()
{
	echo "usage: rpm_maker <options>"
	echo "		-r | --rpmbuild filename - buildrpm from existing list"
	echo "					   where filename is optional listname>"
	echo "		-l | --lynxdump		 - convert list of urls from launchpad"
	echo "					   to urls to debs"
	echo "		-g | --getpkgs		 - get list of pkgs from launchpad"
	echo "		-s | --setpkg	%pkg	 - set pkgname to download and convert"
	echo "		-p | --setppa	%ppa	 - set PPA to use for obtaining"
	echo "					   urllist from launchpad"
	echo "		-t | --setteam	%team	 - set Team to use for obtaining"
	echo "					   urllist from launchpad"
	echo "		-a | --arch	%arch	 - specify the architecture amd64 | x386"
	echo "					   defaults to amd64"
	echo "		-d | --debs		 - download the debs files but do not"
	echo "					   process them with alien etc"
	echo "					   default is false"
	echo "		-c | --clean		 - clean the tmp directory of build"
	echo "					   files etc when rpm_maker is finished"
	echo "		-x | --cleansrc		 - clean the build sources and deb files"
	echo "					   defaults to true"
	echo "		-h | --help		 - this message"
	echo "		________________________________________________________________"
	echo "		no parameters will download debs and build them into ./tmp/rpms"
}

while [ "$1" != "" ]; do
    case $1 in
        -r | --rpmbuild )       shift
				if [ "$1" != '' ]; then
					filename=$1
				fi
				rpmbuild
				exit
                                ;;
	-l | --lynxdump )	lynxdump
				exit
				;;
	-g | --getpkgs )	packages
				exit
				;;
	-s | --setpkgs )	shift
				if [ "$1" != '' ]; then
                                        PACKAGE=$1
                                        export PACKAGE
                                fi
                                ;;
	-t | --setteam )	shift
				if [ "$1" != '' ]; then
                                        TEAM=$1
					export TEAM
				fi
				;;
	-p | --setppa )		shift
				if [ "$1" != '' ]; then
                                        PPA=$1
					export PPA
				fi
				;;
	-a | --setarch )	shift
				if [ "$1" != '' ]; then
                                        ARCH=$1
					export ARCH
				fi
				;;
	-c | --clean )		shift
				if [ "$1" = '' ]; then
					CLEAN=true
				else
					CLEAN=$1
				fi
				;;
	-x | --cleansrc )	shift
				if [ "$1" = '' ]; then
					CLEAN_SRC=true
				else
					CLEAN_SRC=$1
				fi
				export CLEAN_SRC
				;;
	-d | --debs )		DEBS_ONLY=true
				export DEBS_ONLY
				;;
        -h | --help )           usage
                                exit 1
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

packages
RET=$?
if [ $RET -eq 0 ]; then
	lynxdump
else
	echo "package urls failed to download with an exit code of $RET"
	exit $RET
fi
RET=$?
if [ $RET -eq 0 ]; then
	rpmbuild
else
	echo "lynxdump script failed with an exit code of $RET"
	exit $RET
fi
RET=$?
if [ $RET -ne 0 ]; then
	echo "rpmbuild script failed with an exit code of $RET"
	exit $RET
fi
if [ $CLEAN = true ]; then
	sudo rm -rf tmp/*
fi
exit 0
