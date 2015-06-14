When running Filemaker Server 5.5/6.0 on Linux one looses the nice automated backup features which exist in the Windows and Mac versions of the software. It turns out backups can be automated pretty simply by using the PAUSE and RESUME options for fmserverd. I don't claim to be a super bash scripter but here's an example script to get you going (keep in mind that this script lacks error handling, use it at your own risk). NOTE: If anyone would like to add error handling and other nifty features please login and post a comment with your suggestions.

#!/bin/sh
#
# (c) 2005 Steve Moitozo 
# Use it, change it, distribute it, but don't blame me if something goes wrong.
# THERE IS NO WARRANTY.
#
# This script backs up the filemaker databases
#
# The script assumes a set of directories exist within FMBACKUPS such as:
# $FMBACKUPS/01-Monday
# $FMBACKUPS/02-Tuesday
# $FMBACKUPS/03-Wednesday
# $FMBACKUPS/04-Thursday
# $FMBACKUPS/05-Friday
# $FMBACKUPS/06-Saturday
# $FMBACKUPS/07-Sunday
#
# This script can be run from cron using the following type of config
# To backup Filemaker Server every day at 12:30pm (half past noon) and 8:30pm
# 30 12,20 * * * /var/fmserver-backups/backup-fmserver.sh

#
# CONFIGURATION
#

# the path to fmserverd
FMSERVERD="/usr/bin/startoldglibcapp /usr/bin/fmserverd"

# the path to the filemaker files
FMFILES=/var/fmserver

# the path to the filemaker log file
FMLOG=/var/log/fmserver/Events.log

# the path to the backups
FMBACKUPS=/var/fmserver-backups

#
# DO NOT EDIT BELOW THIS LINE ####################################
#

# build the path to today's directory
TODAY_PATH="0"`date +%u`"-"`date +%A`

# announce the beginning of the process
echo `date`" Beginning backup of Filemaker databases"

# First shutdown filemaker server
echo `date`" Pausing Filemaker Server"
$FMSERVERD PAUSE $FMFILES/*

# Make a backup of the filemaker files to today's directory
echo `date`" Copying files to $FMBACKUPS/$TODAY_PATH"
cp -r $FMFILES $FMBACKUPS/$TODAY_PATH

# Start up filemaker server
echo `date`" Resuming filemaker server"
$FMSERVERD RESUME $FMFILES/*

# Make a copy of the filemaker log file
echo `date`" Copying log file to $FMBACKUPS/$TODAY_PATH"
cp $FMLOG $FMBACKUPS/$TODAY_PATH

# change symbolic link
echo `date`" Moving symbolic link to $FMBACKUPS/$TODAY_PATH"
rm $FMBACKUPS/current; ln -s $FMBACKUPS/$TODAY_PATH $FMBACKUPS/current

# output the current open database file list
echo `date`" The current available databases are:"
$FMSERVERD FILES

# exit we're done
echo `date`" Filemaker backup complete"

exit 0