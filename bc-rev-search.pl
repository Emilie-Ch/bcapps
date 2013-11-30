#!/bin/perl

# I frequently search for files (eg, mlocate/slocate) where I know the
# ending part of a file; this program efficiently searches for them
# using bc-sgrep.pl and a list of files sorted in reverse
# --create: just create revfiles.txt, don't search anything

require "/usr/local/lib/bclib.pl";
option_check(["create"]);

if ($globopts{create}) {
  # TODO: perl inside perl seems ugly
  system("bzcat /usr/local/etc/weekly-backups/files/bcunix-files.txt.bz2 | perl -nle 's%^.*?\/%/%; print $_' | rev | sort > /mnt/sshfs/revfiles.txt");
  exit;
}

# TODO: allow more than one argument
my($phrase) = @ARGV;
$phrase = reverse($phrase);
system("/home/barrycarter/BCGIT/bc-sgrep.pl '$phrase' /mnt/sshfs/revfiles.txt | rev");