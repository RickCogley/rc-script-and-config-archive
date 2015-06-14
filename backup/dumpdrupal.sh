#!/bin/sh
#
# dumpmysql.sh - script for backing up your mysql databases
# 		- Update Variables before use
# 		- Loops through specified DBs less exception tables and dumps to files with dates
#

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
	echo "Dumping ${MYSQLDB} ..."
	for TARGETTBL in $(echo "show tables" | $mysqlcmd $mysqluidpw ${MYSQLDB} | grep -v -e $stripstring) 
	do
		echo " --- ${TARGETTBL}"
		$mysqldumpcmd $mysqluidpw $mysqldumpoptions ${MYSQLDB} ${TARGETTBL} >> ${backupdir}/${MYSQLDB}-$dateandtime.sql
	done
	echo "Compressing ${MYSQLDB} dump ..."
	rm -f ${backupdir}/${MYSQLDB}-$dateandtime.sql.gz
	$gzip ${backupdir}/${MYSQLDB}-$dateandtime.sql
             find ${backupdir}/ -type f -name ${MYSQLDB}-200* -mtime +4 -exec rm -f {} \;

done
ls -l ${backupdir}






