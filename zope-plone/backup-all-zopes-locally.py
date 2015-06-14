#!/usr/local/bin/python

# Author:      Tom Lazar <tom@tomster.org>
# Created:     2005/10/08
# Licence:     BSD


from repozo import *
import datetime
import os
import shutil

BACKUP = 1
RECOVER = 2

COMMASPACE = ', '
VERBOSE = True

REPOBASE = "/opt/zope/instance/"
BACKUPBASE = "/opt/backups/zope/"


class Options:
    mode = None         # BACKUP or RECOVER
    file = None         # name of input Data.fs file
    repository = None   # name of directory holding backups
    full = False        # True forces full backup
    date = None         # -D argument, if any
    output = None       # where to write recovered data; None = stdout
    quick = False       # -Q flag state
    gzip = False        # -z flag state


def default_options():
    options = Options()
    options.mode = BACKUP
    return options

def createDir(dir):
    """ creates a directory, but only, if it doesn't exist yet"""
    try:
        os.mkdir(dir)
    except OSError:
        pass

def dirExists(dir):
    return os.access(dir, os.F_OK)

def do_specific_backup(which=None, full=True):
    """ 
        - When performing a full backup we rename any existing backup directory and create a new, empty one, 
          into which repozo will do its magic.
        - When renaming the backup, we delete any existing old backup to prevent infinite space usage.
        - Otherwise we just perform an incremental backup into the existing folder
        - After performing a full backup we intentionally don't delete the old backup: if we did, we would lose 
          all incremental backups performed since the last full backup. I.e when performing nightly incremental
          backups and weekly full backups you will always have between seven and fourteen snapshots instead of
          just between one and seven.
        
        IMPORTANT: the `Data.fs` must(!) be located at `zeo/var/Data.fs` inside the instance directory
    """

    if which == None:
        return None

    outdir = BACKUPBASE + which
    olddir = outdir + "-old"

    # if the outdir doesn't exist yet, we can't perform an incremental backup, right?
    if not dirExists(outdir):
        full = True

    if VERBOSE:
        mode = "incremental"
        now = datetime.datetime.now()
        nowstring = now.strftime("%Y-%m-%d %H:%M")
        if full:
            mode = "full"
        print nowstring, ": Performing", mode, "backup of", which, "locally."

    # when performing a full backup, we move any existing old backup out of the way:
    if full:
        if dirExists(outdir):
            if dirExists(olddir):
                shutil.rmtree(olddir)
            os.rename(outdir, olddir)

        createDir(outdir)

    options = default_options()
    options.full = full
    options.repository = outdir
    options.file = REPOBASE + which + "/var/Data.fs"
    do_backup(options)


def main():

    args = sys.argv
    
    # we backup all directories inside the REPOPATH:
    instancelist = os.listdir(REPOBASE)
    #FIXME: for some reason the following filter returns an empty list...?!
    #instancelist = filter(os.path.isdir, instancelist)
    
    full = True
    if len(args) == 2 and args[1] == 'incremental':
        full = False

    for instance in instancelist:
        do_specific_backup(instance, full)


if __name__ == '__main__':
    main()
