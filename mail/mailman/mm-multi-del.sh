#!/bin/bash 
# --
# mm-multi-del.sh - a script for deleting multiple Mailman lists from a 
# common base string.
#
# Copyright (c) 2005, Rick Cogley
# <rick [at] esolia [dot] co [dot] jp>, eSolia Inc.
#
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the GNU General Public License as published by 
# the Free Software Foundation; either version 2 of the License, or 
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
# GNU General Public License for more details.
#
# Get the GNU General Public License from the Free Software 
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
# --

echo "mm-multi-del.sh - <\$Revision: 0.2 $>"
echo This script deletes Mailman lists based on user variables 
echo entered interactively and set with variables in the script. 
echo It is intended to help maintain consistency. 

# set global variables
MMBIN=/usr/lib/mailman/bin
MMALIASES=/etc/mailman
MMLISTLANG=en
MMOWNEREMAIL=rick.cogley@esolia.co.jp
MMADMINPASS=mm2005!
MMDEFURLHOST=www.esolia.net
MMDEFEMAILHOST=esolia.net
MMTMP=/tmp

echo
echo Get user input for variables...
while [ "$x" != "y" ]; do
  echo
  echo Enter the short name for the client, no spaces, lowercase.
  echo This is the string used in the lists you will now delete. 
  echo For example the xyz of xyz-support@esolia.net.
  read CSN
  echo "Remove archives too? (y/n)"
  read RMARCHIVES
  echo
  echo == SCRIPT PRESETS ==
  echo Default URL Host: $MMDEFURLHOST
  echo Defautl EMAIL Host: $MMDEFEMAILHOST
  echo Location of Mailman scripts: $MMBIN
  echo Location of Mailman aliases: $MMALIASES
  echo List language: $MMLISTLANG
  echo List Owner Email: $MMOWNEREMAIL
  echo List Admin Password: $MMADMINPASS
  echo
  echo == USER ==
  echo Client Short Name: $CSN
  echo Client Domain String: $DOMSTR
  if [ "$RMARCHIVES" = "y" ]; then
    echo Remove archives: Yes
    RMOPT="-a"
  else
    echo Remove archives: No
  fi
  echo
  echo "Is this correct? (y/n)"
  read x
done

echo
echo Removing lists and optionally archives...
echo

for i in support p1 memo sales projects sa
do 
    echo ===== Processing $CSN-$i =====
    echo
    echo Removing list: $CSN-$i

    $MMBIN/rmlist $RMOPT $CSN-$i
    $MMBIN/genaliases
    echo
done 

echo =========================
echo Confirm Lists Were Removed 
echo
echo Using list_lists:
echo "(Blank is correct)"
echo
$MMBIN/list_lists |grep $CSN
echo Using cat on aliases file:
echo "(Blank is correct)"
echo
cat /etc/mailman/aliases|grep $CSN
echo
# cleanup
rm -f /tmp/mm-*

exit 0

