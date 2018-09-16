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
from importlib import util
import sys
from os import environ

if sys.version_info[0] < 3:
    raise Exception("Python 3 or a more recent version is required.")

if environ.get('LYNX_URLS') is not None:
	listfile = environ.get('PROJ_ROOT') + environ.get('LIST_DIR') + environ.get('LYNX_URLS')
	print(listfile)
else:
	print("listfile is not set in getpkgurls.py")
	sys.exit(1)

if environ.get('ARCH') is not None:
	arch = environ.get('ARCH')
else:
	arch = "amd64"

if environ.get('TEAM') is not None:
	lp_team = environ.get('TEAM')
else:
	lp_team = 'kxstudio-debian'

if environ.get('PPA') is not None:
	lp_ppa = environ.get('PPA')
else:
	lp_ppa = 'plugins'

if environ.get('PACKAGE') is not None and environ.get('PACKAGE') is not "\"\"":
	lp_pkg = environ.get('PACKAGE')
else:
	lp_pkg = None

print( "******* " + lp_pkg)

if environ.get('PKG_LOG') is not None:
	pkglog = environ.get('PROJ_ROOT') + environ.get('LOG_DIR') + environ.get('PKG_LOG')
else:
	print("no log file for getpkgurls.py")

launchpad_spec = util.find_spec("launchpadlib")

if util.find_spec("launchpadlib") == "":
	print("You need to install launchpadlib for python")
	sys.exit(1)

from launchpadlib.launchpad import Launchpad
try:
	launchpad = Launchpad.login_anonymously('rpm_maker.sh', 'production')

	team = launchpad.people[lp_team]
	ubuntu = launchpad.distributions["ubuntu"]

	ppa = team.getPPAByName(distribution=ubuntu, name=lp_ppa)

	ds1 = ubuntu.getSeries(name_or_version="trusty")
	ds2 = ubuntu.getSeries(name_or_version="lucid")
	ds3 = ubuntu.getSeries(name_or_version="xenial")
	ds4 = ubuntu.getSeries(name_or_version="bionic")

	d_s = [ds1,ds2,ds3,ds4]
	d_a_s = []
	for i in d_s:
		d_a_s.append(i.getDistroArchSeries(archtag=arch))
	p_b_h = []
	for i in d_a_s:
		p_b_h.append(ppa.getPublishedBinaries(order_by_date=True, binary_name=lp_pkg, pocket="Release", status="Published", distro_arch_series=i))

	# lp_buildcoll = ppa.getBuildRecords(build_state="Successfully built",pocket="Release")

	print("downloading urls from launchpad to " + listfile)

	f=open(listfile,"w+")
	lines_seen = set()
	
	for b in p_b_h:
		if len(b):
			for i in b:
				#get most recent - list ordered by date
				build_link_slice = i.build_link[8:]
				if build_link_slice not in lines_seen:
					#unable to obtain link to binaryFileUrls
					#from publishinghistory so using builds
					#instead
					f.write(i.build_link+"\n")
					lines_seen.add(build_link_slice)
	f.close()
	sys.exit(0)
except Exception as e:
	print(e)
	fl = open(pkglog, "a+")
	fl.write(e)
	fl.close
	sys.exit(1)
