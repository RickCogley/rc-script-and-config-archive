#! /bin/bash

# Backup zope incrementally using the repozo Q switch
. /etc/sysconfig/zope
export PYTHONPATH=/opt/zope/zope/lib/python/
for instance in $ZOPE_INSTANCENAMES; do
  /opt/zope/zope/bin/repozo.py -BvzQ -r /rcutils/backups/zope/$instance -f /opt/zope/$instance/var/Data.fs
done

exit 0
