#!/bin/sh
# Copyright: GPL
# documentation:
# http://linuxfocus.org/English/May2004/article337.shtml
# or
# http://algolog.tripod.com/linux1.htm
#
#version number of shivalik script
SHIVVERSION='2.0'
# ver 2.0 major updates for the LinuxFocus article
#
# ver 1.3 saves XF86config file and myscripts directory also
# ver 1.4 added mount , cdrecord , /etc/sfatb , etc/mtab into summary
# ver 1.4 created 2004-03-27
#
error()
{
    echo "$1"
    exit 1
}
# Setup vars 
dt=`date '+%Y-%m-%d_%H%M'`
# filestoget="/postmaster* /var/lib/pgsql/data/*.conf /var/lib/pgsql/data/PG* /var/www/html/pga/conf/config.inc.php /opt/TrackStudio/etc /opt/TrackStudio/jetty /opt/TrackStudio/stopJetty /usr/lib/mailman/Mailman/mm* /rcutils/scripts/*"
# filestoget="/etc/.webmin-backup"
filestoget="/opt/TrackStudioCommon/uploads"
archfile="tsattachments.tar.gz" 

#
if [ $# = 0 -o "$1" = "-h" ]; then
    cat <<HELP
shivalik -- make a backup of /etc 

USAGE: shivalik [-h] /directory/where/the/backup/goes

OPTIONS: -h this help

backup_etc creates a sub-directory in the directory
you specify for the backup. 
The sub-directory will contain a tar.gz file of /etc and
and the following selected information from /proc:
  modules
  dma
  interrupts
  mounts
  version
  partitions
  meminfo
  pci

EXAMPLE: shivalik /usr/local/backupcfg

shivalik Ver. $SHIVVERSION
HELP
	exit 0
else
	targetdir="$1"
	if [ ! -d "$targetdir" ]; then
		echo "OK, directory $targetdir does not exist, creating it..."
		mkdir -p "$targetdir"
	fi
	mkdir "$targetdir/backup-$dt" || error "ERROR: can not create dir $targetdir/backup-$dt"
	echo "OK, creating $targetdir/backup-$dt/$archfile ..."
	(cd /;tar -czf "$targetdir/backup-$dt/$archfile" $filestoget)
	procf="$targetdir/backup-$dt/proc_info.txt"
	echo "OK, creating $procf ..."
	for f in modules dma interrupts mounts version partitions meminfo pci; do
		echo "====== /proc/$f ======" >> "$procf"
		if [ -r "/proc/$f" ]; then
			cat "/proc/$f" >> "$procf"
		else
			echo "Warning: /proc/$f does not exist, feature not enabeled in kernel"
			echo "" >> "$procf"
			echo "--File /proc/$f did not exist--" >> "$procf"
			echo "" >> "$procf"
		fi
		echo "" >> "$procf"
	done
fi
/bin/tar -tf $targetdir/backup-$dt/$archfile | /usr/bin/mutt -s "$0 Backup $dt" -a $targetdir/backup-$dt/$archfile -a $targetdir/backup-$dt/proc_info.txt report@esolia.net

