# a library for this project, since it now has multiple programs

# Attempting to get rid of memory bloat $ff hash; this subroutine
# queries the db for ff status, but also checks its fairly recently
# updated. is_ff($source, $type, $target)
# [$type='friend|follower']. Returns -1 on error, +1 on success, 0 on
# failure; could obviously do this with an API query, but more
# efficient this way-- don't have to query API server zillions of
# times

sub is_ff {
  my($source,$type,$target) = @_;

  unless (freshness_check($source,$type)) {return -1;}

  # now the friend/follower query itself
  $query = "SELECT COUNT(*) FROM ff WHERE user='$source' AND type='$type' AND target='$target'";
  $res = sqlite3val($query,$ffdb);
  if ($SQL_ERROR) {logmsg("SQLERROR: $SQL_ERROR"); return -1;}
  return $res;
}

# counts number of friends/followers for given user (returns -1 on error)
sub count_ff {
  my($source,$type) = @_;

  unless (freshness_check($source,$type)) {return -1;}

  # now the count
  $query = "SELECT COUNT(*) FROM ff WHERE user='$source' AND type='$type'";
  $res = sqlite3val($query,$ffdb);
  if ($SQL_ERROR) {logmsg("SQLERROR: $SQL_ERROR"); return -1;}
  return $res;
}

# checks freshness of ff db for given user and type (ie, "friends" or
# "followers"); returns 0 if db not fresh [or other error], 1 if db is
# fresh (called from other subroutines)

sub freshness_check {
  my($source,$type) = @_;
  # when was the db last updated for this $source/$type
  my($query) = "SELECT MIN(timestamp) FROM ff WHERE user='$source' AND type='$type'";
  # TODO: could do the math here in sqlite3, but easier this way?
  my($res) = sqlite3val($query, $ffdb);
  # if no result, error
  unless ($res) {return 0;}
  # distrust results more than an hour old
  my($diff) = str2time("$res UTC")-time();
  if (abs($diff)>3600) {return 0;}
  return 1;
}

1;
