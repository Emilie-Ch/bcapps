#!/bin/perl

# A much reduced attempt at a metawiki that uses only a fixed number
# of well-known relations, each of which I know how to handle. Hope to
# generalize this into an all-purposes meta wiki at some point.

# Test case for this wiki is Pearls Before Swine comic strip

require "/usr/local/lib/bclib.pl";

# shortcuts just to make code look nicer
# character class excluding colons and brackets
$cc = "[^\\[\\]:]";
# double left and right bracket
$dlb = "\\[\\[";
$drb = "\\]\\]";
debug("CC1: $cc,$dlb,$drb");

my($data) = read_file("/home/barrycarter/BCGIT/METAWIKI/pbs.txt");
$data=~s%^.*?<data>(.*?)</data>.*$%$1%s;

for $i (split(/\n/, $data)) {
  # ignore blanks and comments
  if ($i=~/^\#/ || $i=~/^\s*$/) {next;}

  # split line into source page and then body
  $i=~/^(.*?)\s*($dlb.*)$/;
  my($source, $body) = ($1,$2);
  parse_text($source,$body);
}

# now, adding stuff to pages from the established triples
for $i (keys %triple) {
  for $j (keys %{$triple{$i}}) {
    for $k (keys %{$triple{$i}{$j}}) {
      debug("$i, $j, $k, $triple{$i}{$j}{$k}");
    }
  }
}

sub parse_text {
  my($source,$body) = @_;
  # return triplets
  my(@trip) = ();
  # source may contain multiple pages
  my(@source) = parse_source($source);

  # keep things like [[Pig]] as is, but tokenize so they won't bother us
  # TODO: undo this before final wiki printing
  $body=~s/$dlb($cc+)$drb/\001$1\002/sg;

  # semantic triple
  for $source (@source) {
    while ($body=~s/$dlb($cc*?)::($cc*?)$drb//) {
      # relation and value
      my($relation,$value) = ($1,$2);
      # either of these can be multiple
      for $i (split(/\+/, $relation)) {
	for $j (split(/\+/, $value)) {
	  # TODO: allow non-1 values to set order
	  $triple{$source}{$i}{$j} = 1;
	}
      }
    }
  }
}

# convert things like
# 2013-04-17-2013-04-19,2013-04-22,2013-04-23,2013-04-30,2013-05-01,2013-05-06-2013-05-08,2013-05-13-2013-05-15,2013-05-20-2013-05-22,2013-05-24,2013-05-29
# to a list of source pages
sub parse_source {
  my($source) = @_;
  my(@ret);

  for $i (split(/\,/,$source)) {
    # if source is date range (2002-06-03-2002-06-07), parse further
    if ($i=~/^(\d{4}-\d{2}-\d{2})\-(\d{4}-\d{2}-\d{2})$/) {
      push(@ret, parse_date_range($1,$2));
    } else {
      push(@ret, $i);
    }
  }
  return @ret;
}

# convert 2002-06-03-2002-06-07 to list of dates
sub parse_date_range {
  my($st,$en) = @_;
  my(@ret);
  # integer division below
  for $i (str2time($st)/86400..str2time($en)/86400) {
    push(@ret, strftime("%Y-%m-%d", gmtime($i*86400)));
  }
  return @ret;
}

