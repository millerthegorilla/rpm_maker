# rpm_maker
aA script to access and download debs from launchpad and convert them to rpms

rpm_maker connects to launchpad via the rest api and downloads either all the binary packages for a ppa, and then converts them from debs to rpms, or just a single package.
Once the rpms have been created, you will need to install them manually.
The download urls is a bit of a hack as the launchpad api wouldn't allow me to download the binary packages directly.



<!--stackedit_data:
eyJoaXN0b3J5IjpbNzM5NTA0MDk3XX0=
-->