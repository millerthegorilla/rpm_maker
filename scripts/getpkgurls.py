#python3?
import importlib
import sys
from os import environ

if environ.get('PROJ_ROOT') is not None:
	proj_root = environ.get('PROJ_ROOT')
else:
	print("project root is not set")
	sys.exit(1)

if environ.get('ARCH') is not None:
	arch = environ.get('ARCH')
else:
	arch = "amd64"

if environ.get('TEAM') is not None:
	lpteam = environ.get('TEAM')
else:
	lpteam = 'kxstudio-debian'

if environ.get('PPA') is not None:
	lp_ppa = environ.get('PPA')
else:
	lp_ppa = 'plugins'

launchpad_spec = importlib.util.find_spec("launchpadlib")
found = launchpad_spec is not None
if found is not True:
	print("You need to install launchpadlib for python")
	sys.exit(1)

from launchpadlib.launchpad import Launchpad
try:
	launchpad = Launchpad.login_anonymously('just testing', 'production')

	team = launchpad.people[lpteam]
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
		p_b_h.append(ppa.getPublishedBinaries(pocket="Release", status="Published",distro_arch_series=i))
	listfile = proj_root + "/lists/urls-for-lynx.list"

	print("downloading urls from launchpad to " + listfile)

	f=open(listfile,"w+")
	lines_seen = set()
	for b in p_b_h:
		if b.__len__():
			for i in b:
				if i.build_link not in lines_seen:
					#unable to obtain link to binaryFileUrls
					#from publishinghistory so using builds
					#instead
					f.write(i.build_link+"\n")
					lines_seen.add(i.build_link)
	f.close()
	sys.exit(0)
except Exception as e:
	print(e)
	fl = open("$PROJ_ROOTlog/getpkgurls.log", "a")
	fl.write(e)
	fl.close
	sys.exit(1)
