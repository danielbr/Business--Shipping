# Business::Shipping::Data
# 
# $Id: Data.pm,v 1.2 2004/01/21 22:39:52 db-ship Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Data;

$VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
@EXPORT = qw( record );

use strict;
use warnings;
use base ( 'Exporter', 'Business::Shipping' );
use Data::Dumper;
use Business::Shipping::Debug;
use Business::Shipping::Config;
use DBI;

sub record
{
	trace( 'called' );
	my ( $table, $field, $key, $opt ) = @_;
	
	# 
	# TODO: Database work
	# 
	
	my $key_column = $opt->{ foreign } || get_primary_key( $table );
	return unless $key_column;
	debug3( "key_column = $key_column" );
	
	#
	# Apparently, I have to do '*' instead of the field name.  Go figure.
	#
	my $query = "SELECT * FROM $table WHERE $key_column = \'$key\'";
	debug( $query );
	my $sth = sth( $query )
		or die "Could not get sth: $@";
		
	my $hashref = $sth->fetchrow_hashref();
	
	debug3( "hashref = " . Dumper( $hashref ) );
	return $hashref->{ $field };
}	

sub sth
{
	my ( $query ) = @_;
	
	return unless $query;
	
	my $dbh = dbh();
	
	my $sth = $dbh->prepare( $query )
		or die "Cannot prepare: " . $dbh->errstr();
	
	$sth->execute() or die "Cannot execute: " . $sth->errstr();;
	
	return $sth;	
}

sub dbh
{
	if ( ! defined $::dbh_store ) {
		$::dbh_store = {};
		my $support_files = Business::Shipping::Config::support_files();
		my $dsn = cfg()->{Database}{DSN} || "DBI:CSV:f_dir=$support_files/data";
		$dsn .= ";csv_eol=\n;";
		
		my $dbh = DBI->connect( $dsn )
			or die "Cannot connect: " . $DBI::errstr;
	
		if ( $dsn =~ /^DBI:CSV/ ) {
			#
			# Try to find tables in the configuration that have
			# extra settings.
			#
			foreach my $section ( cfg_obj()->Sections() ) {
				if ( $section =~ /^Table_/ ) {
					my $table = $section;
					$table =~ s/^Table_.+_//;
					
					
					my $table_attributes_hash = cfg()->{ $section };
					$table_attributes_hash->{ file } ||= "$table.csv";
					$table_attributes_hash->{ eol } =~ s/cr/\r/;
					$table_attributes_hash->{ eol } =~ s/nl/\n/;
					$table_attributes_hash->{ eol } ||= "\n";
					
					debug3( "adding special csv attributes for $table.  They are:" . Dumper( $table_attributes_hash ) );
					
					#
					# TODO: only allow a restricted list of attributes to be set
					# instead of letting anything in the config file be set.
					#
					$dbh->{ csv_tables }->{ $table } = $table_attributes_hash;
				}
			}
		}
		#
		# Currently, only one DBH is allowed.
		#
		$::dbh_store->{ main } = $dbh;
	}
	return $::dbh_store->{ main };
}

sub get_primary_key
{
	my ( $table ) = @_;
	
	my $sth = sth( "SELECT * FROM $table LIMIT 1" );
	
	#
	# TODO: Use some DBI method to determine the real primary key
	# Or, allow the primary key to be specified in the config.
	#
	# For now, we assume that the first column is the primary key.
	#
	return $sth->{ NAME }->[ 0 ];
}

=pod
sub bind_hash {
	my ($table, @fields) = shift;
	
	my $dbh = dbh( $table );
	my $sql = 'SELECT ' . join(', ', @fields) . " FROM $table";
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	
	my %results;
	@results{@fields} = ();
	$sth->bind_columns(map { \$results{$_} } @fields);
	return (\%results, sub { $sth->fetch() });
	
	#
	# TODO: Use this calling code: it's very good.
	#
	#my ($res, $fetch) = bind_hash('users', qw( name email ));
	#while ($fetch->()) {
	#	print "$res->{name} >$res->{email}>\n";
	#}
}
=cut


1;
__END__
