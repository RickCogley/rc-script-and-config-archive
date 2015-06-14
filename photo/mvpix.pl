#!/usr/bin/perl -w
# Copyright  2005, 2006 Jamie Zawinski <jwz@jwz.org>
#
# Permission to use, copy, modify, distribute, and sell this software and its
# documentation for any purpose is hereby granted without fee, provided that
# the above copyright notice appear in all copies and that both that
# copyright notice and this permission notice appear in supporting
# documentation.  No representations are made about the suitability of this
# software for any purpose.  It is provided "as is" without express or 
# implied warranty.
#
##############################################################################
#
# This script is how I get pictures off my digital camera.
# It works on both Linux and MacOS X.
#
#   - examine all the files on the card and decide what directory
#     each file will go in:
#
#     - divide them into directories based on date like "YYYY-MM-DD".
#     - continuously shooting around midnight does not cause a new
#       directory: shots after midnight count as the previous day.
#     - start a new directory any time there is more than 30 minutes
#       pause between shots (suffix "b", "c", etc.)
#
#   - create directories like YYYY-MM-DD/RAW/
#   - create directories like YYYY-MM-DD/EDIT/
#
#   - for each image on the card:
#
#       - mv it into YYYY-MM-DD/RAW/
#       - if it is a CRW or CR2 (raw) file, convert it to JPEG
#         (the RAW/ directory will contain both CRW and JPEG versions)
#       - rotate it according to EXIF
#       - add a copyright notice to the file
#       - set file time to the time photo was taken
#       - chmod a-w
#       - copy the JPEG into YYYY-MM-DD/EDIT/
#       - chmod u+w the copy
#
# Then I manually crop and color-correct the files in EDIT, and delete
# the ones that I don't want.
#
# To publish photos to the web, I then scale down the versions from EDIT
# and do any late edits (unsharp mask, etc.)
#
# This way, I end up with archives of the original, unaltered images,
# as well as the large color-corrected versions, so that I can re-create
# different-sized web galleries without having to re-do the various edits.
#
# When archiving, I add a topical suffix to the directory name, e.g.,
# "2005-03-25-beach".  That way, things in the archive always sort
# chronologically, but it's still easy to find events by title.
#
##############################################################################
#
# Requirements:
#
#   Image::ExifTool  -- for reading JPEG EXIF data (photo date, rotation, etc.)
#   copyright-image  -- for putting a copyright notice in each JPEG file.
#                       (http://www.jwz.org/hacks/marginal.html)
#
# Required only if you shoot CRW or CR2 (raw) images:
#
#   dcraw            -- for reading RAW files...
#   cjpeg            -- ...and writing them as JPEG files.
#
# Created: 16-Mar-2005.
#
##############################################################################

require 5;
use diagnostics;
use strict;
use POSIX qw(mktime);
use Image::ExifTool;

my $progname = $0; $progname =~ s@.*/@@g;
my $version = q{ $Revision: 1.13 $ }; $version =~ s/^[^0-9]+([0-9.]+).*$/$1/;


#my $mountpoint = "/media/EOS_DIGITAL";    # where your camera shows up
my $mountpoint = "/Volumes/EOS_DIGITAL";

my $verbose = 1;
my $copy_p = 0;

my $rotate_thumbs_p = 1;  # Whether to correct rotation of embedded thumbnail
			  # images as well as the main image.  If you don't
			  # care about built-in thumbs, setting this to 0 will
			  # speed it up a little.

my $copyright_p = 1;	  # Whether to run "copyright-image"

my $destdir  = "RAW";
my $clonedir = "EDIT";


# like system() but checks errors.
#
sub safe_system(@) {
  my (@cmd) = @_;

  print STDOUT "$progname: executing " . join(' ', @cmd) . "\n"
    if ($verbose > 3);

  system @cmd;
  my $exit_value  = $? >> 8;
  my $signal_num  = $? & 127;
  my $dumped_core = $? & 128;
  error ("$cmd[0]: core dumped!") if ($dumped_core);
  error ("$cmd[0]: signal $signal_num!") if ($signal_num);
  error ("$cmd[0]: exited with $exit_value!") if ($exit_value);
}

# returns the full path of the named program, or undef.
#
sub which($) {
  my ($prog) = @_;
  foreach (split (/:/, $ENV{PATH})) {
    if (-x "$_/$prog") {
      return $prog;
    }
  }
  return undef;
}


my %files = ();   # "yyyy/mm/dd hh:mm:ss filename" => "target-dir"
my %dirs = ();    # all the parent directories we will create


# Look at the write dates on all the files on the card, and populate
# the keys in %files.
#
sub analyse_files(@) {
  my (@files) = @_;

  my $last_time = time;
  my $last_pct = -1;
  my $i = 0;

  print STDOUT "\n$progname: examining files in $mountpoint/\n"
    if ($verbose);

  foreach my $file (@files) {
    my $mtime = (stat($file))[9];
    error ("$file: unstattable?") unless ($mtime > 100000);
    my ($ss, $min, $hh, $dd, $mm, $yyyy) = localtime($mtime);
    $mm++;
    $yyyy += 1900;

    my $now = time;
    if ($now >= $last_time + 5) {
      my $pct = int ($i * 100 / ($#files+1));
      if ($pct != $last_pct) {
        print STDOUT sprintf("%4d/%d -- %d%%...\n", $i, $#files+1, $pct);
        $last_pct = $pct;
        $last_time = $now;
      }
    }

    my $key = sprintf("%04d/%02d/%02d %02d:%02d:%02d %s",
                      $yyyy, $mm, $dd, $hh, $min, $ss, $file);
    $files{$key} = 1;
    $i++;
  }
}


# Decide which directory each file should go in, being smart about
# midnight and pauses in shooting.  Fill in the values in %files.
#
sub choose_directories() {

  my $last_time = 0;
  my $last_dir = undef;

  my @keys = sort (keys %files);

  print STDOUT "\n$progname: choosing directories for " . ($#keys+1) .
               " files...\n"
    if ($verbose > 1);

  foreach my $key (@keys) {
    $_ = $key;

    my ($date, $yyyy, $mm, $dd, $hh, $min, $ss, $file) =
      m@^((\d{4})/(\d\d)/(\d\d) (\d\d):(\d\d):(\d\d)) (.*)$@s;
    error ("unparsable key: $_") unless (defined($yyyy) && $yyyy > 1990);

    my $time = mktime ($ss, $min, $hh, $dd, $mm-1, $yyyy-1900, 0, 0, -1);
    error ("bogus values in mktime") unless ($time);

    my $elapsed = $time - $last_time;

    $file =~ s@^(.*/)?([^/]*)$@$2@s;

    my $dir = $last_dir;

    # Switch to a new dated directory if:
    #
    #  - this is the first file, or;
    #  - more than 3 hours has elapsed between shots.
    #
    # That is, we don't switch just because we crossed midnight.
    #
    # Switch to a new suffix (same date) if more than 30 minutes have
    # elapsed between shots.
    #
    if (!defined($dir) || $elapsed > 3*60*60) {
      $dir = "$yyyy-$mm-$dd-a";

    } elsif ($last_time > 0 && $elapsed >= 30*60) {
      $dir =~ m/^(.*-)([a-z])$/ || error ("no suffix on $dir?");
      my ($prefix, $suffix) = ($1, $2);
      $dir = $prefix . chr(ord($suffix)+1);
    }

    if ($last_dir && $dir ne $last_dir) {
      my $e = ($elapsed <= 60*60    ? sprintf("%02d minutes", $elapsed/60) :
               $elapsed <  72*60*60 ? sprintf("%2d hours %02d minutes",
                                              $elapsed/(60*60),
                                              ($elapsed/60)%60) :
               sprintf("%.1f days", $elapsed/(24*60*60)));
      print STDOUT "\n$progname: ## -------- $e\n\n"
        if ($verbose > 5);
    }

    print "$progname: ## $dir\t$file\t# $date $elapsed\n"
      if ($verbose > 5);

    $last_time   = $time;
    $last_dir    = $dir;

    $dir =~ s/-a$//;

    $dirs{$dir}  = 1;
    $files{$key} = $dir;
  }
}


# Create each top-level directory we will be writing to in %dirs.
#
sub create_directories() {

  foreach my $d (sort (keys %dirs)) {
    if (! -d $d) {
      print STDOUT "$progname: mkdir $d/\n";
      mkdir ($d) || error ("mkdir: $d: $!");
    }

    my @subdirs;
    if ($destdir) {
      @subdirs = ("/$destdir", "/$clonedir");
    } else {
      @subdirs = ("");
    }

    foreach my $suffix (@subdirs) {
      my $d2 = "$d$suffix";
      if (! -d $d2) {
        print STDOUT "$progname: mkdir $d2/\n" if ($verbose > 1);
        mkdir ($d2) || error ("mkdir: $d2: $!");
      }
    }
  }
  print STDOUT "\n";
}


# Print some stats about time elapsed, etc.
#
sub print_stats($$$$$) {
  my ($action, $start_this, $start_total, $bytes, $files) = @_;

  return unless $verbose;

  my $secs  = time - $start_total;
  my $secs2 = time - $start_this;

  $secs  = 1 if ($secs  < 1);
  $secs2 = 1 if ($secs2 < 1);

  my $dur = sprintf("%d:%02d:%02d",
                    $secs / (60 * 60),
                    ($secs / 60) % 60,
                    $secs % 60);
  my $dur2 = sprintf("%d:%02d:%02d",
                     $secs2 / (60 * 60),
                     ($secs2 / 60) % 60,
                     $secs2 % 60);

  my $pre = "$progname: $action   $files files in $dur2";
  my $k = ($bytes / $secs2) / 1024.0;
  my $bb = ($k >= 1024
            ? sprintf ("%.1f GB/s", $k/1024.0)
            : sprintf ("%.1f KB/s", $k));

  if ($bytes && $start_this != $start_total) {
    print STDOUT "$pre ($dur total, $bb)\n";
  } elsif ($start_this != $start_total) {
    print STDOUT "$pre ($dur total)\n";
  } elsif ($bytes) {
    print STDOUT "$pre ($bb)\n";
  } else {
    print STDOUT "$pre\n";
  }
  print "\n";
}


# Actually move (or copy) the files off the card.
#
sub move_files() {

  my @keys = sort (keys %files);

  my $start = time;
  my $bytes = 0;
  my $i = 1;

  my @nfiles = ();

  foreach my $key (@keys) {
    my $dir = $files{$key};
    my $ofile = $key;
    $ofile =~ s@^[\d/]+ [\d:]+ @@s;
    my $nfile = lc($ofile);
    $nfile =~ s@^.*/@@s;
    my $sfile = $nfile;
    $nfile = ($destdir
              ? "$dir/$destdir/$nfile"
              : "$dir/$nfile");

    my $size = (stat($ofile))[7];
    my $k = int (($size / 1024.0) + 0.5);
    my $n = $#keys+1;

    print STDOUT sprintf("%s: %s %3d/%d %s... (%d KB)\n",
                         $progname, ($copy_p ? "copying" : "moving"),
                         $i, $n, $sfile, $k)
      if ($verbose);

    if ($copy_p) {
      safe_system ("cp", "-p", $ofile, $nfile);
    } else {
      safe_system ("mv",       $ofile, $nfile);

      if ($ofile =~ m/^(.*)\.(crw|cr2)$/i) {
        #
        # When Canon writes crw_NNNN.crw RAW files, they also write a
        # small JPEG thumbnail in crw_NNNN.thm.  If we're moving the
        # .crw file off the card (not just copying), then delete the
        # .thm file as well.
        #
        my $thm = "$1.thm";
        unlink ($thm);
      } elsif ($ofile =~ m/^(.*)\.(nef)$/i) {
        #
        # Likewise, Nikon writes EXIF data as XML into a "dsc_NNNN.xmp" file;
        # nuke that too.
        #
        my $xml = "$1.xmp";
        unlink ($xml);
      }
    }

    push @nfiles, $nfile;

    $bytes += $size;
    $i++;
  }

  print_stats (($copy_p ? "copied " : "moved"),
               $start, $start, $bytes, $#nfiles+1);
  return @nfiles;
}


# Rotate images in RAW/ according to EXIF data; add a copyright notice;
# make the files unwritable.
#
sub adjust_images($@) {
  my ($start, @nfiles) = @_;

  my $start2 = time;
  my $i = 1;
  my $cvt_p;

  foreach my $f1 (@nfiles) {
    my $f2;
    my $sfile = $f1;
    $sfile =~ s@^.*/@@;
    my $n = $#nfiles+1;
    $cvt_p = ($sfile =~ m/\.(crw|cr2|nef)$/i);

    print STDOUT sprintf("%s: %s %3d/%d %s...\n", $progname,
                         ($cvt_p ? "converting" : "adjusting "),
                         $i, $n, $sfile)
      if ($verbose);

    if ($cvt_p) {
      #
      # Convert a CRW file to a JPEG file, and make sure the JPEG contains
      # the same EXIF data that the CRW file had.  In an ideal world, we
      # could do this with "convert in.crw out.jpg", but ImageMagick 6.2
      # doesn't read CRW files properly.  So we have to use "dcraw" to
      # convert the CRW to a PPM, then "cjpeg" to create a JPEG... and
      # finally, we have to update the EXIF data manually.
      #
      $f2 = $f1;
      $f2 =~ s/\.(crw|cr2|nef)$/.jpg/i;
      safe_system ("dcraw -w -t 0 -c '$f1' | cjpeg -opt -qual 95 > '$f2'");
      copy_exif_data ($f1, $f2);

      # From here on, we work on the .jpg file, not the .crw file.
      ($f1, $f2) = ($f2, $f1);
    }

    rotate_jpeg ($f1);
    update_file_date ($f1, $f2);
    copyright_image ($f1) if ($copyright_p);

    if (defined ($destdir)) {
      my @cmd = ("chmod", "444", $f1);
      push @cmd, $f2 if defined ($f2);
      safe_system (@cmd);
    }

    $i++;
  }

  print_stats (($cvt_p ? "converted" : "adjusted "),
               $start2, $start, 0, $#nfiles+1);
}


# Returns an "Image::ExifTool" from the given file, with error checking.
#
sub read_exif($) {
  my ($file) = @_;

  my $exif = new Image::ExifTool;
  $exif->Options (Binary    => 1,
                  Verbose   => ($verbose > 4));
  my $info = $exif->ImageInfo ($file);

  if (($_ = $exif->GetValue('Error'))) {
    error ("$file: EXIF read error: $_");
  }

  if (($_ = $exif->GetValue('Warning'))) {
    print STDERR "$progname: $file: EXIF warning: $_\n";
    delete $info->{Warning};
  }

  return ($exif, $info);
}


# Copies the EXIF info from one file into another.
#
sub copy_exif_data($$) {
  my ($from, $to) = @_;

  my $tmp = sprintf ("%s.%08X", $to, int (rand(0xFFFFFF)));
  my $exif = new Image::ExifTool;
  $exif->Options (Binary    => 1,
                  Verbose   => ($verbose > 4));

  # Read the EXIF info out of $from...
  #
  print STDERR "$progname: $from: reading EXIF...\n" if ($verbose > 3);
#  if (! $exif->ExtractInfo ($from)) {
  if (! $exif->SetNewValuesFromFile ($from)) {
    error ("$from: invalid EXIF data");
  }

  # Copy $to to $tmp, updating $tmp with the $from EXIF data...
  #
  print STDERR "$progname: $tmp: copying EXIF...\n" if ($verbose > 3);
  if (! $exif->WriteInfo ($to, $tmp)) {
    error ("$tmp: EXIF write error: " . $exif->GetValue('Error'));
  }

  # Finally, replace $to with $tmp.
  #
  if (!rename ($tmp, $to)) {
    unlink ($tmp);
    error ("mv $tmp $to: $!");
  }

}


# If the EXIF data says the file needs to be rotated, do so.
#
sub rotate_jpeg($) {
  my ($file) = @_;

  my ($exif, $info) = read_exif ($file);
  my $rot = $exif->GetValue ('Orientation', 'ValueConv');

  return if ($rot == 1);  # don't need to do anything

  my $tmp1 = sprintf ("%s.1.%08X", $file, int (rand(0xFFFFFF)));
  my $tmp2 = sprintf ("%s.2.%08X", $file, int (rand(0xFFFFFF)));
  my $tmp3 = sprintf ("%s.3.%08X", $file, int (rand(0xFFFFFF)));

  my @rotcmd = ("jpegtran", "-copy", "all", "-trim");

  if    ($rot == 2) { push @rotcmd, ("-flip", "horizontal"); }
  elsif ($rot == 3) { push @rotcmd, ("-rotate", "180"); }
  elsif ($rot == 4) { push @rotcmd, ("-flip", "vertical"); }
  elsif ($rot == 5) { push @rotcmd, ("-transpose"); }
  elsif ($rot == 6) { push @rotcmd, ("-rotate", "90"); }
  elsif ($rot == 7) { push @rotcmd, ("-transverse"); }
  elsif ($rot == 8) { push @rotcmd, ("-rotate", "270"); }
  else {
    error ("$file: unknown Orientation value: $rot");
  }

  my $thumb_data = ($rotate_thumbs_p && defined ($$info{ThumbnailImage})
                    ? ${$$info{ThumbnailImage}}
                    : undef);

  # Copy the JPEG data from $file to $tmp1, losslessly rotating it.
  #
  print STDERR "$progname: $tmp1: rotating...\n" if ($verbose > 3);
  safe_system (@rotcmd, "-outfile", $tmp1, $file);

  # If there's a thumbnail embedded in the EXIF, losslessly rotate that too.
  #
  if ($thumb_data) {
    # Dump the thumbnail image into file $tmp2...
    #
    local *OUT;
    open (OUT, ">$tmp2")  || error ("$tmp2: $!");
    print OUT $thumb_data || error ("$tmp2: $!");
    close OUT             || error ("$tmp2: $!");

    # Rotate $tmp2 into $tmp3, and read in $tmp3...
    #
    print STDERR "$progname: $tmp3: rotating thumb...\n" if ($verbose > 3);
    safe_system (@rotcmd, "-outfile", $tmp3, $tmp2);
    $thumb_data = `cat "$tmp3"`;
    unlink ($tmp2, $tmp3);

    # And store the new thumbnail data back into the in-memory EXIF data.
    #
    my ($status, $err) = $exif->SetNewValue ('ThumbnailImage', $thumb_data,
                                             Type => 'ValueConv');
    if ($status <= 0 || $err) {
      error ("$tmp2: saving thumbnail: $status: $err");
    }
  }

  # Update the EXIF data with the new orientation, and copy $tmp1 to $tmp2
  # with the new EXIF.  There's no way to do this in one pass.
  #
  my ($status, $err) = $exif->SetNewValue ('Orientation', 1,
                                           Type => 'ValueConv');
  if ($status <= 0 || $err) {
    error ("$tmp2: EXIF Orientation: $status: $err");
  }

  print STDERR "$progname: $tmp2: updating EXIF...\n" if ($verbose > 3);
  if (! $exif->WriteInfo ($tmp1, $tmp2)) {
    error ("$tmp2: EXIF write error: " . $exif->GetValue('Error'));
  }

  # Finally, replace $file with $tmp2.
  #
  unlink $tmp1;
  if (!rename ($tmp2, $file)) {
    unlink ($tmp2);
    error ("mv $tmp2 $file: $!");
  }
}


# Set the write date of the file to be the date the photo was taken.
# If a second file is specified, set its date the same.
#
sub update_file_date($$) {
  my ($file, $file2) = @_;

  my ($exif) = read_exif ($file);
  my $date = $exif->GetValue('DateTimeOriginal');

  my ($yyyy, $mon, $dotm, $hh, $mm, $ss) = split (/[: ]+/, $date);
  error ("$file: unparsable date: \"$date\"\n")
    unless ($yyyy > 1990 && $dotm > 0);

  $date = mktime ($ss, $mm, $hh, $dotm, $mon-1, $yyyy-1900, 0, 0, -1);
  error ("bogus values in mktime") unless ($date);

  print STDERR "$progname: $file: setting date to $date\n"
    if ($verbose > 3);

  utime (time, $date, $file) || error ("changing date of $file: $!");

  if (defined ($file2)) {
    print STDERR "$progname: $file2: setting date to $date\n"
      if ($verbose > 3);
    utime (time, $date, $file2) || error ("changing date of $file2: $!");
  }
}


# Put a copyright notice on the file.
#
sub copyright_image($) {
  my ($file) = @_;
  my $devnull = ($verbose > 1 ? "" : ">/dev/null 2>&1");
  safe_system ("copyright-image --keep-date $file $devnull");
}


# Copy the RAW/ files to EDIT; make those files writable.
#
sub duplicate_files($@) {
  my ($start, @nfiles) = @_;

  return unless defined($destdir);

  my $bytes = 0;
  my $start2 = time;
  my $i = 1;
  foreach my $f1 (@nfiles) {
    $f1 =~ s/\.(crw|cr2|nef)$/.jpg/i;
    my $f2 = $f1;
    $f2 =~ s@/$destdir/@/$clonedir/@;
    error ("unable to map $destdir to $clonedir in $f1") if ($f1 eq $f2);

    my $sfile = $f1;
    $sfile =~ s@^.*/@@;

    my $n = $#nfiles+1;
    my $size = (stat($f1))[7];
    my $k = int (($size / 1024.0) + 0.5);
    print STDOUT sprintf("%s: duplicating %3d/%d %s... (%d KB)\n",
                         $progname, $i, $n, $sfile, $k)
      if ($verbose);
    safe_system ("cp", "-p", $f1, $f2);
    safe_system ("chmod", "644", $f2);
    $bytes += $size;
    $i++;
  }
  
  print_stats ("duplicated", $start2, $start, $bytes, $#nfiles+1);
}


sub mvpix() {

  my $start = time;

  my $devnull = ($verbose > 1 ? "" : ">/dev/null 2>&1");

  foreach my $req ("copyright-image") {
    which ($req) || error ("$req not found on PATH");
  }

  if ( ! -x "/usr/bin/osascript" ) {		# not MacOS X
    system ("mount $mountpoint $devnull");   # don't trap errors here
  }

  error ("$mountpoint not mounted") unless (-d "$mountpoint/.");

  my @ofiles1 = (glob ($mountpoint .    "/*.{jpg,JPG}"),
                 glob ($mountpoint .   "/*/*.{jpg,JPG}"),
                 glob ($mountpoint . "/*/*/*.{jpg,JPG}"));
  my @ofiles2 = (glob ($mountpoint .     "/*.{crw,CRW,cr2,CR2,nef,NEF}"),
                 glob ($mountpoint .   "/*/*.{crw,CRW,cr2,CR2,nef,NEF}"),
                 glob ($mountpoint . "/*/*/*.{crw,CRW,cr2,CR2,nef,NEF}"));
  my @ofiles = (@ofiles1, @ofiles2);
  error ("no files in $mountpoint/") if ($#ofiles == -1);

  if ($#ofiles2 != -1) {
    foreach my $req ("dcraw", "cjpeg") {
      which ($req) ||
        error ("CRW, CR2, or NEF files present, but $req not found on PATH");
    }
  }

  analyse_files (@ofiles);
  choose_directories ();
  create_directories ();

  my @nfiles = move_files ();

  if ( -x "/usr/bin/osascript" ) {		# MacOS X
    my $vol = $mountpoint;
    $vol =~ s@^.*/([^/]+)$@$1@;
    my $applescript = "tell application \"Finder\" to eject disk \"$vol\"";
    my @cmd = ("osascript", "-e", $applescript);
    system (@cmd);				#  don't trap errors here

  } else {					# Other Unix
    system ("umount $mountpoint $devnull");	#  don't trap errors here
  }

  print STDOUT "$progname: unmounted $mountpoint/\n\n"
    if ($verbose);

  adjust_images ($start, @nfiles);
  duplicate_files ($start, @nfiles);
  print "Done.\n" if ($verbose);
}



sub error($) {
  my ($err) = @_;
  print STDERR "$progname: $err\n";
  exit 1;
}

sub usage() {
  print STDERR "usage: $progname [--verbose] [--copy] " .
    "[--from mountpoint] [--no-dup] [--no-copyright]\n";
  exit 1;
}

sub main() {
  while ($#ARGV >= 0) {
    $_ = shift @ARGV;
    if ($_ eq "--verbose") { $verbose++; }
    elsif (m/^-v+$/) { $verbose += length($_)-1; }
    elsif (m/^--?copy$/) { $copy_p++; }
    elsif (m/^--?from$/) { $mountpoint = shift @ARGV; }
    elsif (m/^--?no-dup$/) { $destdir = undef; }
    elsif (m/^--?no-copyright$/) { $copyright_p = 0; }
    elsif (m/^-./) { usage; }
    else { usage; }
  }

  mvpix ();
}

main;
exit 0;
