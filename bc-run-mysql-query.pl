#!/usr/bin/perl -0777

# during testing, this works: http://stations.db.mydev/ (courtesy dnsmasq)

# run an arbitrary readonly MySQL query webapp
# starts off as a copy bc-run-sqlite3-query.pl
# format: [rss|csv|].[query|"schema"].db.(db|database).other.stuff

# TODO: replace "download sqlite3 db" with some sort of CSV/TSV dump?

require "/usr/local/lib/bclib.pl";

# TODO: stop doing this
$globopts{debug}=1;
$globopts{keeptemp}=1;

# the only constant is .db|database.
$ENV{HTTP_HOST}=~/^(.*?)\.(db|database)\.(.*)$/;
my($base, $tld) = ($1,"$2.$3");

# determine query pieces (reversed because lower parts don't always exist)
my($db, $query, $type) = reverse(split(/\./, $base));

# DB check
check_db($db);

# TODO: be more specific about which header to provide for requests
print "Content-type: text/html\n\n";

print << "MARK";
<pre>
TLD: $tld
DB: $db
QUERY: $query
TYPE: $type
</pre>
MARK
;

if ($query eq "") {form_request($db,$tld);}
if ($query eq "schema") {schema_request($db,$tld);}
if ($query eq "post") {post_request($db,$tld);}

# "real" query
if ($query=~/[0-9a-f]{32}$/) {query_request($query,$db,$tld,$type);}
print "Hostname $ENV{HTTP_HOST} not understood";

# TODO: more security?

sub check_db {
  my($db) = @_;
  my($header) = "Content-type: text/html";

  # request for all dbs? not yet supported
  if ($db eq "") {webdie("Cannot list databases (at the moment)", $header);}

  # invalid dbname?
  unless ($db=~/^[a-z_]+_shared$/i) {
    webdie("DB name: alpha only, must end in _shared", $header);
  }

  # db doesnt exist?
  my($res) = mysqlval("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$db'");
  unless ($res eq $db) {webdie("No such database: $db", $header);}
}

# this subroutines are specific to this program thus not well documented
sub schema_request {
  my($db,$tld) = @_;
  my($out,$err,$res) = cache_command2("mysqldump --no-data --compact $db | egrep -v '^/'");
  if ($res) {webdie("Schema error: $res/$out/$err");}
  print "<pre>\n$out\n</pre>\n";
}

# request for query already in requests.requests
sub query_request {
  my($hash,$db,$tld,$format) = @_;
  my($options);
  my($query) = decode_base64(mysqlval("SELECT query FROM requests WHERE md5='$hash' AND db='$db'", "requests"));

  # no query returned?
  unless ($query) {
    webdie("$db exists, but no query with hash $hash. Try http://$db.$tld/");
  }

  # actually run query (use tmpfile to avoid command line danger)
  my($tmp) = my_tmpfile("dbquery");
  write_file("$query;", $tmp);

  # options based on format
  $options="-H";
  if ($format eq "csv") {$options="-B"};
  if ($format eq "rss") {$options="-X"};

  # avoid DOS by limiting cputime
  my($out,$err,$res) = cache_command2("ulimit -t 5 && mysql $options $db < $tmp");

  # restore hyperlinks and quotes
  $out=~s/&lt;/</isg;
  $out=~s/&gt;/>/isg;
  $out=~s/&quot;/\"/isg;
  $out=~s/&\#39;/\'/isg;

  # error?
  if ($res) {webdie("QUERY: $query<br>ERROR: $err<br>");}

  # result is known good
  if ($format eq "csv") {
    $out=~s/\t/,/isg;
    $out="<pre>\n$out\n</pre>";
  }

  if ($format eq "rss") {
    $out="<pre>\n$out\n</pre>";
  }

  # info about db
  # TODO: defeat for CSV?
  print read_file("$db.txt");
  print << "MARK";
<title>$query</title>

NOTE: This page is experimental. Bug reports to
carter.barry\@gmail.com. Query language is MySQL.<p>

Prepend rss. to the URL for an RSS feed, csv. to the URL for CSV output.<p>

<p><pre>QUERY: $query</pre><p>

To edit query (or if query above is munged), see textbox at bottom of page<p>

Empty result may indicate error: I'm not sure why my error checking
code isn't working.<p>

<a href="https://github.com/barrycarter/bcapps/blob/master/bc-run-mysql-query.pl" target="_blank">Source code</a>

<p><table border>
$out
</table><p>
MARK
;
    form_request($db,$tld,$query,$hash);
}

sub post_request {
  my($db,$tld) = @_;
  my($query) = <STDIN>;

  # check this query, add it to requests.db as MIME, redirect to execute it
  $query=~s/^query=//isg;
  $query=~s/\+/ /isg;
  $query=~s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
  # these characters are permitted, but ignored
  $query=~s/[\;\r\n]/ /isg;
  # trim spaces to canonize query (may not be a great idea)
  $query=~s/\s+/ /isg;

  # if blank query, just redirect to main site
  unless ($query) {
    print "Location: http://$db.$tld/\n\n";
    return;
  }

  # safety checks
  # TODO: restore this!
  unless ($query=~/^select/i) {
    webdie("Query doesn't start w SELECT: $query");
  }

  # permitted characters (is this going to end up being everything?)
  if ($query=~/([^a-z0-9_: \(\)\,\*\<\>\"\'\=\.\/\?\|\!\+\-\%\\])/i) {
    webdie("Query contains illegal character '$1': $query");
  }

  # query is now safe, add to requests.db (as base 64)
  my($iquery) = encode_base64($query);
  my($queryhash) = md5_hex($iquery);
  # TODO: if query already in db, need to do this (or pointless?)
  mysql("REPLACE INTO requests (query,db,md5) VALUES ('$iquery', '$db', '$queryhash')", "requests");
  if ($SQL_ERROR) {
    webdie("SQL ERROR (requests): $SQL_ERROR");
  }
  # and redirect
  print "Location: http://$queryhash.$db.$tld/\n\n";
}

# print the (trivial) form for queries
sub form_request {
  my($db,$tld,$query,$queryhash) = @_;
  webug("FORM_REQUEST($db,$tld,$queryhash)");
  print << "MARK";
<form method='POST' action='http://post.$db.$tld/'><table border>
<tr><th>Enter query below (must start w/ SELECT):</th></tr>
<tr><th><input type="submit" value="RUN QUERY"></th></tr>
<tr><th><textarea name="query" rows=20 cols=79>$query</textarea></th></tr>
<tr><th><input type="submit" value="RUN QUERY"></th></tr>
</form></table>

<p><a href='http://schema.$db.$tld/' target='_blank'>Schema</a>
MARK
;

  if ($queryhash) {
    print "<a href='http://rss.$queryhash.$db.$tld'>RSS feed for this query</a>\n";
  }
}

=item schema

Schema of tables and users (keep requests in an unshared db intentionally):

CREATE DATABASE requests;
\u requests
CREATE TABLE requests (
 query TEXT, -- stored query in MIME64 format
 db TEXT, -- the database for the query
 md5 TEXT -- the query hash
);

CREATE UNIQUE INDEX ui ON requests(md5(32));

-- TODO: change "test" to the db Ill actually want to use
CREATE USER readonly;
GRANT SELECT ON test TO readonly;


=cut

# TODO: move these subroutines to bclib.pl when ready

=item mysql($query,$db,$user="readonly")

Run the query $query on the mysql db $db as user $user and return
results in "raw" format.

TODO: remove the hardcoded 'readonly' before generalizing this function

=cut

sub mysql {
  my($query,$db,$user) = @_;
  unless ($user) {$user = "readonly";}
  my($qfile) = (my_tmpfile2());

  # ugly use of global here
  $SQL_ERROR = "";

  write_file($query,$qfile);
  my($cmd) = "mysql -u $user -E $db < $qfile";
  my($out,$err,$res,$fname) = cache_command2($cmd,"nocache=1");
  # get rid of the row numbers + remove blank first line
  $out=~s/^\*+\s*\d+\. row\s*\*+$//img;
  $out = trim($out);

  if ($res) {
    warnlocal("MYSQL returns $res: $out/$err, CMD: $cmd");
    debug("DB is $db", `pwd`);
    $SQL_ERROR = "$res: $out/$err FROM $cmd";
    return "";
  }
  return $out;
}

=item mysqlval($query,$db)

For queries that return a single row/column, return that row/column

# TODO: this implementation is painfully ugly

=cut

sub mysqlval {
  my($query,$db) = @_;
  my(@res) = mysql($query,$db);
  $res[0]=~s/^.*?:\s+//;
  return $res[0];
  # get rid of leading row of stars
  # TODO: if I were really clever, I could combine the two lines below!
  my(@temp) = values %{$res[0]};
  return $temp[0];
}
