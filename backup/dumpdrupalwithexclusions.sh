#!/bin/sh
#
# dumpdrupalwithexclusions.sh - grab all tables except grepped out
# and dump to a file
#

# Delete dump
rm -f ~/backups/drupal01.dump

# Dump structure to file
mysqldump -uco0142_admin -pPowerBox1! -d -e -q --single-transaction --add-drop-table co0142_PRDNdrupal01 >> ~/backups/drupal01.dump

# Dump tables with data except excluded tables and append to file
for TARGETTBL in $(echo "show tables" | mysql -u co0142_admin -pPowerBox1! co0142_PRDNdrupal01 | grep -v -e "access\|access_log\|cache\|search_index\|statistics\|watchdog\|Tables_in_")
		do
			echo "Dumping ${TARGETTBL} ..."
			mysqldump -uco0142_admin -pPowerBox1! -e -q --single-transaction --add-drop-table co0142_PRDNdrupal01 ${TARGETTBL} >> ~/backups/drupal01.dump
		done

