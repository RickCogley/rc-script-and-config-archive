#!/bin/sh
#
# dumpdrupal-latest.sh - script for backing up your mysql databases
# 		- Update Variables before setting up cron
# 		- Loops through specified DBs less exception tables and dumps to files 
#		- Does NOT use dates on file names as purpose is to have a recent dump every hour or so

# SET VARIABLES
# 	- List MySQL DBs to backup separated by space
# 	- Set other variables
#	- Note quotes not needed on commands or path

databases="co0142_PRDNdrupal01 co0142_PRDNdrupal02"
stripstring="access\|access_log\|cache\|search_index\|statistics\|watchdog\|Tables_in_"
backupdir=~/backups/
mysqluidpw="--user=co0142_admin --password=PowerBox1!"
mysqldumpcmd=/usr/bin/mysqldump
mysqlcmd=/usr/bin/mysql
mysqldumpoptions=" --quick --add-drop-table --add-locks --extended-insert --single-transaction"
gzip=/bin/gzip
dateandtime=`date +%F-%H%M%S`

# Create our backup directory if not already there
mkdir -p ${backupdir}

# Loop through specified databases and dump excluding certain tables
for MYSQLDB in $databases
do
	rm -f ${backupdir}/${MYSQLDB}-latest.sql
	echo "Dumping ${MYSQLDB} ..."
	for TARGETTBL in $(echo "show tables" | $mysqlcmd $mysqluidpw ${MYSQLDB} | grep -v -e $stripstring) 
	do
		echo " --- ${TARGETTBL}"
		$mysqldumpcmd $mysqluidpw $mysqldumpoptions ${MYSQLDB} ${TARGETTBL} >> ${backupdir}/${MYSQLDB}-latest.sql
	done
	echo "Compressing ${MYSQLDB} dump ..."
	rm -f ${backupdir}/${MYSQLDB}-latest.sql.gz
	$gzip ${backupdir}/${MYSQLDB}-latest.sql
done
ls -l ${backupdir}
