#!/bin/sh
#Allows for Graceful shutdown of FileMaker server. 
#

fmsadmin -u Administrator -p Lapostal backup -d "filemac:/Volumes/'Server HD2'/Backups/fms-pre-shutdown/SAI-FMS-Backup-`date "+%y_%m_%d"`"

fmsadmin -u Administrator -p Lapostal backup -d "filemac:/Volumes/'Server HD'/opt/Backups/fms/SAI-FMS-Backup-`date "+%y_%m_%d"`"

/Volumes/Server\ HD/opt/Backups/fms

fmsadmin BACKUP -d "filemac:/Volumes/'Server HD2'/Backups/fms-pre-shutdown/SAI-FMS-Backup-`date "+%y_%m_%d"`" -u Administrator -p Lapostal 

/usr/bin/fmsadmin backup "$backupdir"/*.[FfIi][PpNn][7Ss] -d "$backupspath" -u "$user" -p "$pass"

fmsadmin -u Administrator -p Lapostal backup *.[FfIi][PpNn][7Ss] -d "filemac:/Volumes/'Server HD2'/Backups/fms-adhoc/"



## real

# Set paths to programs
CMDFMSADMIN=/usr/bin/fmsadmin
CMDRSYNC=/usr/local/maclemon/bin/rsync

# Build a path based on date
DTFOLDER=FMAdhocBackup-`date +%Y%m%d%-%H%M`
MAINBACKUPFOLDER=/Library/FileMaker\ Server/Data/Backups/

/Volumes/Server\ HD2/Backups/fms-adhoc/
/Volumes/WD_SAI/Backups/fms-adhoc
/Volumes/HD/Backup/fms-adhoc


echo === `date`" :: Sending connected users a message via FileMaker Pro UI. Down in 10."
$CMDFMSADMIN -u Administrator -p Lapostal send -m "FileMaker Server on `hostname` going down in 10 minutes. Please disconnect from FileMaker Server."
echo === `date`" :: Sleeping for 10."
sleep 600
echo === `date`" :: Sending connected users a message via FileMaker Pro UI. Down now."
$CMDFMSADMIN -u Administrator -p Lapostal send -m "FileMaker Server on `hostname` going down now!"
echo === `date`" :: Pausing FMS databases."
$CMDFMSADMIN -u Administrator -p Lapostal pause
echo === `date`" :: Running backup schedule."
$CMDFMSADMIN -u Administrator -p Lapostal run schedule 1


rsync -vrpo --delete -u "$hourlypath" "$external"





$FMSADMN -u Administrator -p Lapostal resume





"filemac:/'Macintosh HD'$backupdatabases/"






/Volumes/Server HD2/Backups/fms-pre-shutdown

/Volumes/External HD/Backups/`date "+%m_%d_%y"`

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



serveradmin command < commandFile
             Will execute a command specified in commandFile. Some examples of commands are:

                 afp:command = disconnectUsers
                 afp:message = "You are doomed"
                 afp:minutes = 5
                 afp:sessionIDsArray:_array_id:0 = 4

                 afp:command = sendMessage
                 afp:message = "You are doomed"
                 afp:sessionIDsArray:_array_id:0 = 4

                 info:command = getHardwareInfo
                 info:variant = withQuotaUsage

                 mail:command = getConnectedUsers

                 mail:command = getUserAccounts

                 web:command = getSites


echo `date`|wall
echo "Hello Everyone" | wall

email to all users of sai

slapconfig -backupdb -noEncrypt /opt/Backups/od/`hostname`-opendirectory-backup-`date +%Y%m%d%-%H%M`


for f in $(serveradmin list); do echo $f; done
for f in $(serveradmin list); do serveradmin settings $f > /Volumes/Server\ HD/opt/Backups/`hostname`-$f-settings-`date +%Y%m%d%-%H%M`.backup; done

serveradmin settings all > /Volumes/Server\ HD/opt/Backups/`hostname`-settings.backup

-`date +%Y%m%d%-%H%M`


{{requester:cook-requester@esolia.net assignee:rick.cogley@esolia.co.jp status:open priority:normal ticket_type:task tags:"cogley mail-api"}}





