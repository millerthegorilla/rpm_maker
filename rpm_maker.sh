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
CONF_DIR="$PROJ_ROOT/conf/"
CONF_FILE="$CONF_DIR"'rpm_maker.conf'

#defaults
typeset -A config # init array
config=( # set default values in config array
[TMP_DIR]="$PROJ_ROOT"'tmp/'
[LIST_DIR]="$PROJ_ROOT"'lists/'
[LOG_DIR]="$PROJ_ROOT"'logs/'
[DEBS_DIR]=${config[TMP_DIR]}'debs/'
[BUILT_RPMS_DIR]="$PROJ_ROOT"'rpms/'
[DEB_URLS]=${config[LIST_DIR]}'deburls.list'
[LYNX_URLS]=${config[LIST_DIR]}'urls_for_lynx.list'
[ARCH]="amd64"
[TEAM]="kxstudio-debian"
[PPA]="plugins"
[CLEAN_SRC]=true
[DEBS_ONLY]=false
[PACKAGE]=""
[PKG_LOG]=${config[LOG_DIR]}'getpkgurls.log'
[RPM_LOG]=${config[LOG_DIR]}'build_rpms.log'
[RPM_MANIFEST]=${config[LOG_DIR]}'rpms.manifest'
[LOG_CREATE_MSG]='Log created : '"$(date +"%m-%d-%Y-%T")"
[CLEAN]=false
)

get_conf()
{
	grep -v '^[[:space:]]*#' "$CONF_FILE" | while read line
	do
		if echo $line | grep -F = &>/dev/null
		then
			varname=$(echo "$line" | cut -d '=' -f 1)
			${config[$varname]}=$(echo "$line" | cut -d '=' -f 2-)
		fi
	done < "$CONF_FILE"
}

export_env()
{
	for i in "${!${config[@]}}"
	do   
		export "$i=${${config[$i]}}"
	done
	exit
}

prepare_files()
{
	if [ ! -d ${config[TMP_DIR]} ]; then
		mkdir -p ${config[TMP_DIR]}
	fi

	if [ ! -d ${config[LIST_DIR]} ]; then
		mkdir -p ${config[LIST_DIR]}
	fi

	if [ ! -d ${config[LOG_DIR]} ]; then
		mkdir -p ${config[LOG_DIR]}
	fi

	if [ -s ${config[PKG_LOG]} ]; then
		mv ${config[PKG_LOG]} ${config[PKG_LOG]}'.old'
	fi
	touch ${config[PKG_LOG]}
	echo ${config[LOG_CREATE_MSG]} >> ${config[PKG_LOG]}
}

packages()
{
	if [ -s ${config[LYNX_URLS]} ]; then
		mv ${config[LYNX_URLS]} ${config[LYNX_URLS]}'.old'
	fi
	touch ${config[LYNX_URLS]}
	python3 "$PROJ_ROOT"'scripts/getpkgurls.py'
}

lynxdump()
{
	"$PROJ_ROOT"'scripts/lynxdump.sh'
}

rpmbuild()
{
	echo 'Building RPMS from list at '"$PROJ_ROOT$filename"
	cd ${config[TMP_DIR]}
	"$PROJ_ROOT"'scripts/build_rpms.sh' "$1"
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

export_env

getcommands()
{
	while [ "$1" != "" ]; do
		case $1 in
			-r | --rpmbuild )       shift
					if [ "$1" != '' ]; then
						rpmbuild $1
					fi
					exit
									;;
		-l | --lynxdump )
					lynxdump
					exit
					;;
		-g | --getpkgs )	
					packages
					exit
					;;
		-s | --setpkgs )	shift
					if [ "$1" != '' ]; then
										config[PACKAGE]=$1
										export_env
									fi
									;;
		-t | --setteam )	shift
					if [ "$1" != '' ]; then
											config[TEAM]=$1
											export_env
					fi
					;;
		-p | --setppa )		shift
					if [ "$1" != '' ]; then
											config[PPA]=$1
											export_env
					fi
					;;
		-a | --setarch )	shift
					if [ "$1" != '' ]; then
											config[ARCH]=$1
											export_env
					fi
					;;
		-c | --clean )		shift
					if [ "$1" = '' ]; then
						config[CLEAN]=true
					else
						config[CLEAN]=$1
					fi
					export_env
					;;
		-x | --cleansrc )	shift
					if [ "$1" = '' ]; then
						config[CLEAN_SRC]=true
					else
						config[CLEAN_SRC]=$1
					fi
					export_env
					;;
		-d | --debs )		config[DEBS_ONLY]=true
							export_env
					;;
			-h | --help )           usage
									exit 1
									;;
			* )                     usage
									exit 1
		esac
		shift
	done
}

script_main()
{
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
	if [ ${config[CLEAN]} = true ]; then
		sudo rm -rf tmp/*
	fi
	exit 0
}

get_conf
export_env
getcommands
export_env
script_main
