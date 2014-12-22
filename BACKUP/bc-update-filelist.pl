#!/bin/perl

# Instead of creating "find / -ls" daily, this program attempts to
# find (roughly) the creation time of the previous file list and only
# find files newer than it, and then merge [or perhaps version-ate?]

require "/usr/local/lib/bclib.pl";

# NOTE: considered using existing file list and finding most recent
# file (and then backing up a day to be safe), but that seems
# pointless now

# TODO: other file dumps
# TODO: decide if I want to keep these files bzip'd or not
# TODO: do this for reverse file search thing too

$file = "/usr/local/etc/kevin59/files/bcunix-files.txt";

my($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime,
$mtime, $ctime, $blksize, $blocks) = stat($file);

# the minimum of file times minus a day
my($touchtime) = min($mtime, $ctime, $atime)-86400;
system("touch -d \@$touchtime /tmp/buf.timestamp");

# is this faster than dumping the whole fs? (testing in oneliners.sh)


