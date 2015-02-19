#!/bin/perl

require "/usr/local/lib/bclib.pl";

# --justfiles: just print out a list of files (ie, for tar --bzip --from-files)

# file format as in BACKUP/README

# report space used by files and directories (including
# subdirectories) and number of files per directory (include
# subdirectory)

# NOTE: could've sworn I've written something very similar to this already

# WARNING: BREAKING THIS COMPLETELY BECAUSE I NEED MTIME AS FIRST FIELD!!!

my(%size,%count);

while (<>) {
  chomp;

  # ignore lines without slashes (probably just the first/last date lines)
  unless(/\//) {next;}

  my(%file);

  ($file{mtime},$file{size},$file{name}) =  split(/\s+/, $_, 3);

  # TODO: filter out dirs/etc
  if ($globopts{justfiles}) {print "$filename\n"; next;}

  # to save memory, print file size directly and don't hash it
  # 1 = 1 file
  print "$file{size} 1 $file{name}\n";

  # find all ancestor directories
  while ($file{name}=~s/\/([^\/]*?)$//){
    $size{$file{name}}+=$file{size};
    $count{$file{name}}++;
  }
}

for $i (keys %size) {print "$size{$i} $count{$i} $i\n";}
