# rpm_maker
aA script to access and download debs from launchpad and convert them to rpms

rpm_maker connects to launchpad via the rest api and downloads either all the binary packages for a ppa, and then converts them from debs to rpms, or just a single package.
Once the rpms have been created, you will need to install them manually.
The script to download urls is a bit of a hack as the launchpad api wouldn't allow me to download the binary packages directly, which may be my fault - any help appreciated.
Also, its my first real bash scripting, so don't be surprised by bad techniques, pitfalls or errors!  Any constructive criticism is always welcome.
That said, I created the project to download and install debs from the great KXStudio project, but it can be used for any project.
The usage is below, but be aware that the script needs the url name - not the display name - 
for instance - the kxstudio-debian project uses a ppa that has the displayname of 'Applications', but the script will want the url name which is 'apps'.
Also, the script  'scripts/lynxdump.sh' uses a sed regex to obtain the binary file urls for download and the format can differ depending on project.  Like I say, it is a hack, but I will probably have a look at a better way in the near future.
In the meantime, for those of you wanting to install kxstudio plugins and apps etc on a Fedora os, it should work fine, with the defaults for rpm_maker being the team 'kxstudio-debian' and the ppa 
<!--stackedit_data:
eyJoaXN0b3J5IjpbMTAwNTUzODU2N119
-->