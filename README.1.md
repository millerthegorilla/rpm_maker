# rpm_maker
a script to access and download debs from launchpad and convert them to rpms
rpm_maker connects to launchpad via the rest api and downloads either all the binary packages for a ppa, and then converts them from debs to rpms, or just a single package.
Once the rpms have been created, you will need to install them manually.
The download urls is a bit of a hack as the launchpad api wouldn't allow me to download
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTQzMTE2OTQ1N119
-->