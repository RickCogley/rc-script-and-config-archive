#!/bin/bash 
# --
# mm-multi.sh - a script for creating multiple Mailman lists from a 
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

echo "mm-multi.sh - <\$Revision: 0.5 $>"
echo This script creates Mailman lists based on user variables 
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
MMDMEMBERS=/tmp/mm-defaultmembers
MMSMEMBERS=/tmp/mm-smsmembers
echo track@esolia.net >$MMDMEMBERS
echo rick.cogley@ezweb.ne.jp >$MMSMEMBERS 
echo esolia55@dk.pdx.ne.jp >>$MMSMEMBERS
echo Fukuokatk@pdx.ne.jp >>$MMSMEMBERS
echo esolia9682@dk.pdx.ne.jp >>$MMSMEMBERS
echo mschmidt@dk.pdx.ne.jp >>$MMSMEMBERS
echo esoliatech003@dk.pdx.ne.jp >>$MMSMEMBERS 
MMTMP=/tmp

echo
echo Get user input for variables...
while [ "$x" != "y" ]; do
  echo
  echo Enter a short name for the client, no spaces, UPPERcase:
  read CSN
  echo Enter the clients email domain without the .com etc, lowercase:
  read DOMSTR
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
  echo
  echo "Is this correct? (y/n)"
  read x
done

echo
echo Creating lists, generating aliases, adding base members  ...
echo

for i in Support P1 Memo Sales Projects SA
do 
    echo ===== Processing $CSN-$i =====
    echo
    echo Creating list: $CSN-$i
     # This is 2.1.5 newlist Syntax using arcane list@urlhost syntax
    $MMBIN/newlist -l $MMLISTLANG $CSN-$i@$MMDEFURLHOST $MMOWNEREMAIL $MMADMINPASS 
     # The 2.1.6 syntax will apparently be: 
     # /path/to/newlist -l en -q -u www.mydom.net listname ownermail pass
    echo Generating Aliases...
    $MMBIN/genaliases
    echo Adding Members... 
    $MMBIN/add_members -r $MMDMEMBERS -w n -a n $CSN-$i
       
      if [ "$i" = "P1" ]
       then
         $MMBIN/add_members -r $MMSMEMBERS -w n -a n $CSN-$i
      fi   

    echo Members of $CSN-$i:
    $MMBIN/list_members $CSN-$i
    echo Creating file for config_list...
    echo "real_name = '$CSN-$i'" >/tmp/mm-$CSN-$i
    echo "description = '$CSN-$i'" >>/tmp/mm-$CSN-$i
    echo "subject_prefix = '[$CSN-$i] '" >>/tmp/mm-$CSN-$i
    echo "host_name = '$MMDEFEMAILHOST'" >>/tmp/mm-$CSN-$i
    echo "max_message_size = 0" >>/tmp/mm-$CSN-$i
    echo "available_languages = ['en', 'ja']" >>/tmp/mm-$CSN-$i
    echo "accept_these_nonmembers = ['^[^@]+@(.+\\\.|)$DOMSTR\\\.', '^[^@]+@(.+\\\.|)esolia\\\.', '^[^@]+@(.+\\\.|)gmail\\\.']" >>/tmp/mm-$CSN-$i
    echo "advertised = 0" >>/tmp/mm-$CSN-$i
    echo "subscribe_policy = 2" >>/tmp/mm-$CSN-$i
    echo "private_roster = 2" >>/tmp/mm-$CSN-$i
    echo "autorespond_postings = 1" >>/tmp/mm-$CSN-$i
    echo "autoresponse_postings_text = \"\"\"Thank you for your message to %(listname)s, which has just been received into our system. An eSolia professional on your engagement team will attend to it directly. " >>/tmp/mm-$CSN-$i
    echo >>/tmp/mm-$CSN-$i
    echo "We appreciate your business!" >>/tmp/mm-$CSN-$i
    echo >>/tmp/mm-$CSN-$i
    echo "-- eSolia Inc. \"\"\"" >>/tmp/mm-$CSN-$i
    echo "autoresponse_graceperiod = 0" >>/tmp/mm-$CSN-$i
    echo "filter_content = 0" >>/tmp/mm-$CSN-$i
    echo "filter_mime_types = ''" >>/tmp/mm-$CSN-$i
    echo "pass_mime_types = ''" >>/tmp/mm-$CSN-$i
    echo "msg_footer = ''" >>/tmp/mm-$CSN-$i
    echo "respond_to_post_requests = 0" >>/tmp/mm-$CSN-$i
    echo "admin_notify_mchanges = 1" >>/tmp/mm-$CSN-$i
    echo "send_reminders = 0" >>/tmp/mm-$CSN-$i
    echo "welcome_msg = ''" >>/tmp/mm-$CSN-$i
    echo "send_welcome_msg = 0" >>/tmp/mm-$CSN-$i
    echo "send_goodbye_msg = 0" >>/tmp/mm-$CSN-$i

    if [ "$i" = "P1" ]
      then
        echo "convert_html_to_plaintext = 1" >>/tmp/mm-$CSN-$i
      else
        echo "convert_html_to_plaintext = 0" >>/tmp/mm-$CSN-$i
    fi
        
    echo Configuring list...
    $MMBIN/config_list -i /tmp/mm-$CSN-$i $CSN-$i
    echo
done 

echo =========================
echo Lists Just Created: 
echo
$MMBIN/list_lists |grep $CSN

# cleanup
rm -f /tmp/mm-*

exit 0

