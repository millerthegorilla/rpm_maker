# rpm_maker
aA script to access and download debs from launchpad and convert them to rpms

rpm_maker connects to launchpad via the rest api and downloads either all the binary packages for a ppa, and then converts them from debs to rpms, or just a single package.
Once the rpms have been created, you will need to install them manually.
The script to download urls is a bit of a hack as the launchpad api wouldn't allow me to download the binary packages directly, which may be my fault - any help appreciated.
Also, its my first real bash scripting, so don't be surprised by bad techniques, pitfalls or errors!  Any constructive criticism is always welcome.
That said, I created the project to download and install debs from the great KXStudio project, but it can be used for any project.
The usage is below, but be aware that the script needs the url name - not the display name - 
for instance - the kxstudio-den
<!--stackedit_data:
eyJoaXN0b3J5IjpbNDM5MjY2NF19
-->