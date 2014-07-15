#!/bin/perl

# Obtains sunrise/sunset info from
# http://aa.usno.navy.mil/data/docs/RS_OneYear.php and puts it into an
# SQLite3 db

require "/usr/local/lib/bclib.pl";

# values of $type below (split into 2 pieces)
my(@types)=("SR", "SS", "MR", "MS", "CTS", "CTE", "NTS", "NTE", "ATS", "ATE");

# for db delete
for $i (@types) {push(@delme, "'$i'");}
$delme = join(", ", @delme);

# I probably shouldn't do it this way
open(A,"|sqlite3 /home/barrycarter/BCGIT/db/abqastro.db");
print A "DELETE FROM abqastro WHERE event IN ($delme);\n";
print A "BEGIN;\n";

# In theory, the POST form,
# http://aa.usno.navy.mil/cgi-bin/aa_rstablew.pl, accepts only POST
# data, but it actually accepts GET data as well

# TODO: move this declaration much further inside
my(%data);
for $year (2009..2024) {
  for $type (0..4) {
    my($out,$err,$res) = cache_command2("curl 'http://aa.usno.navy.mil/cgi-bin/aa_rstablew.pl?FFX=1&xxy=$year&type=$type&st=NM&place=albuquerque&ZZZ=END'","age=86400");

    # parse result
    for $k (split(/\n/, $out)) {
      # TODO: need header lines to determine what data I have, but skip for now
      # determine day (if not one, skip)
      unless ($k=~/^\s*(\d+)\s*/) {next;}
      my($day) = $1;
      # data is positional and has blanks, so can't use split() here
      for $month ("01".."12") {
	my($times) = substr($k,$month*11-7,9);
	# can't use \d below because of blanks
	$times=~/^(..)(..) (..)(..)$/;
	my(@times) = ("$1:$2", "$3:$4");
	for $i (0..1) {
	  # ignore blanks
	  if ($times[$i]=~/^\s*:\s*$/) {next;}
	  # bizarre hack for DST
	  # TODO: generalize MST, the webpage does include this information
	  my($time) = strftime("%Y-%m-%d %H:%M", localtime(str2time("$year-$month-$day $times[$i] MST")));
	  print A "INSERT INTO abqastro VALUES ('$types[2*$type+$i]', '$time');\n";
	}
      }
    }
  }
}

print A "COMMIT;\n";

close(A);
