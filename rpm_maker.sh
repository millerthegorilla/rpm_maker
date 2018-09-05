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
CLEAN=false

PROJ_ROOT="$(pwd)"'/'
#set -a
export TMP_DIR="$PROJ_ROOT"'./tmp/'
export LIST_DIR="lists/"
export LOG_DIR="$PROJ_ROOT"'logs/'
export DEBS_DIR="$TMP_DIR"'debs/'
export BUILT_RPMS_DIR="$PROJ_ROOT"'rpms/'
export DEB_URLS="$PROJ_ROOT$LIST_DIR"'deburls.list'
export LYNX_URLS="$PROJ_ROOT$LIST_DIR"'urls_for_lynx.list'
export ARCH="amd64"
export TEAM="kxstudio-debian"
export PPA="plugins"
export CLEAN_SRC=true
export DEBS_ONLY=false
export PACKAGE=""
export PKG_LOG="$LOG_DIR"'getpkgurls.log'
export RPM_LOG="$LOG_DIR"'build_rpms.log'
export RPM_MANIFEST="$LOG_DIR"'rpms.manifest'
export NOW=$(date +"%m-%d-%Y-%T")
# set +a

filename="$DEB_URLS"

if [ ! -d "$TMP_DIR" ]; then
	mkdir -p "$TMP_DIR"
fi

if [ ! -d "$LOG_DIR" ]; then
	mkdir -p "$LOG_DIR"
fi

if [ -s "$PKG_LOG" ]; then
        mv "$PKG_LOG" "$PKG_LOG"'.old'
fi
touch "$PKG_LOG"
echo "Log created $NOW" >> "$PKG_LOG"

packages()
{
	if [ -s "$LYNX_URLS" ]; then
		mv "$LYNX_URLS" "$LYNX_URLS"'.old'
	fi
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
