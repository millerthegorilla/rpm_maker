# rpm_maker
a script to access and download debs from launchpad and convert them to rpmsA script to access and download debs from launchpad and convert them to rpms

rpm_maker connects to launchpad via the rest api and downloads either all the binary packages for a ppa, and then converts them from debs to rpms, or just a single package.

Once the rpms have been created, you will need to install them manually.

The script to download urls is a bit of a hack as the launchpad api wouldn't allow me to download the binary packages directly, which may be my fault - any help appreciated.
Also, its my first real bash scripting, so don't be surprised by bad techniques, pitfalls or errors!  Any constructive criticism is always welcome.
That said, I created the project to download and install debs from the great KXStudio project, to install on Fedora, but it can be used for any project.

rpm_maker uses python3 for one of its scripts, and you will need to have launchpadlib installed.  I use virtualenv for ease and pip to install the launchpad library.

The usage is below, but be aware that the script needs the url name - not the display name - 
for instance - the kxstudio-debian project uses a ppa that has the displayname of 'Applications', but the script will want the url name which is 'apps'.

Also, the script  'scripts/lynxdump.sh' uses a sed regex to obtain the binary file urls for download and the format can differ depending on project.  Like I say, it is a hack, but I will probably have a look at a better way in the near future.

In the meantime, for those of you wanting to install kxstudio plugins and apps etc on a Fedora os, it should work fine, with the defaults for rpm_maker being the team 'kxstudio-debian' and the ppa being 'plugins'.  Usage of the script with no options will download and convert all the plugins in the ppa.  Some of these will be older builds and some will be unnecessary.

If you want to install Cadence, Katia etc, then you will need to install python3-pyqt4, at least until the qt5 release.  
You will also want to install the yum multimedia group for audio production - sudo yum groupinstall "Audio Production" which includes jackdbus etc
If you want to develop the idea, then using the rest api to download and compile from source obtained from launchpad might be a good idea.
I haven't tried this with i386 nor have I tested extensively, and as a relative noob to bash I wouldn't suggest this is production quality by any means, so use it at your own risk!

examples:

		./rpm_maker	

				download and convert kxstudio plugins (a lot of files)
				there will be mixed version rpms so check before installing

		./rpm_maker -t kxstudio-debian -p apps -s cadence

				download and convert the package cadence from the apps ppa of the kxstudio-debian team

usage: rpm_maker <options>

		-r | --rpmbuild filename - buildrpm from existing list

					   where filename is optional listname>

		-l | --lynxdump		 - convert list of urls from launchpad

					   to urls to debs

		-g | --getpkgs		 - get list of pkgs from launchpad

		-s | --setpkg	%pkg	 - set pkgname to download and convert

		-p | --setppa	%ppa	 - set PPA to use for obtaining

					   urllist from launchpad

		-t | --setteam	%team	 - set Team to use for obtaining

					   urllist from launchpad

		-a | --arch	%arch	 - specify the architecture amd64 | x386

					   defaults to amd64

		-d | --debs		 - download the debs files but do not

					   process them with alien etc.  Default is false

		-c | --clean		 - clean the tmp directory of build

					   files etc when rpm_maker is finished

		-x | --cleansrc		 - clean the build sources and deb files

					   defaults to true

		-h | --help		 - this message

		________________________________________________________________

		no parameters will download debs and build them into ./tmp/rpms


(c) 2018 - James Stewart Miller
