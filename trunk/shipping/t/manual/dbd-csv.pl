#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

#
# Note: DBD::CSV won't work if you get the line-endings wrong!
#
use DBI;
my $dbh = DBI->connect("DBI:CSV:f_dir=data")
	or die "Cannot connect: " . $DBI::errstr;
	
$dbh->{'csv_tables'}->{'a_1da'} = { 	'file' => 'a_1da', 		'eol' => "\n"	};
$dbh->{'csv_tables'}->{'bench'} = { 	'file' => 'bench', 		'eol' => "\r\n"	};
#$dbh->{'csv_tables'}->{'Ground'} = { 	'file' => 'Ground.csv',	'eol' => "\n" 	};

#my $sth = $dbh->prepare("SELECT * FROM test")
#my $sth = $dbh->prepare("SELECT * FROM bench")
#my $sth = $dbh->prepare("SELECT * FROM Ground")
my $sth = $dbh->prepare("SELECT * FROM a_1da WHERE Exceed=\'16\'")
	or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
while ( my @row = $sth->fetchrow_array ) {
	print join( "\t", @row ) . "\n";
}

$sth->finish();
$dbh->disconnect();

1;
__END__
