# Business::Shipping::RateRequest::Offline::UPS - Offline cost estimating.
#
# $Id: UPS.pm,v 1.2 2003/12/22 03:49:06 db-ship Exp $
#
# Copyright (C) 2003 Interchange Development Group
# Copyright (c) 2003 Kavod Technologies, Dan Browning. 
#
# All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 
# Based on the corresponding work in the Interchange project, which was
# written by Mike Heins <mike@perusion.com>.
# See http://www.icdevgroup.org for more info.
#

package Business::Shipping::RateRequest::Offline::UPS;

use strict;
use warnings;

use vars qw( $VERSION );
$VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
use base ( 'Business::Shipping::RateRequest::Offline' );

use Business::Shipping::Shipment::UPS;
use Business::Shipping::Package::UPS;
use Business::Shipping::Debug;
use Business::Shipping::Data;
use Business::Shipping::Util;
use Business::Shipping::Config;
use Data::Dumper;
use POSIX;
use Fcntl ':flock';

use Business::Shipping::CustomMethodMaker
	new_with_init => 'new',
	new_hash_init => 'hash_init',
	hash => [ 'zone' ],
	grouped_fields_inherit => [
		optional => [ 
			'zone_file', 'zone_name', 'auto_update',
			'disable_download', 'disable_unzip', 
		]
	];

use constant INSTANCE_DEFAULTS => (
#	zone_name	=> '450',	
#	zone_file	=> 'data/450.csv',
);

sub to_residential { return shift->shipment->to_residential( @_ ); }

sub init
{
	my $self   = shift;
	
	my %values = ( INSTANCE_DEFAULTS, @_ );
	$self->hash_init( %values );
	return;
}



sub convert_ups_rate_file
{
	trace "( $_[0] )";
	
	my ( $file ) = @_;
	my $file2 = "$file.new";
	if ( ! -f $file ) { return; }
	
	open( 		RATE_FILE,		$file			) or die $@;
	binmode( 	RATE_FILE 						) if $Global::Windows;
	flock( 		RATE_FILE, 		LOCK_EX 		) or die $@;
	open( 		NEW_RATE_FILE,	">$file2"		) or die $@;
	binmode( 	NEW_RATE_FILE 					) if $Global::Windows;
	flock( 		NEW_RATE_FILE,	LOCK_EX			) or die $@;
	
	my $line;

	#
	# Line ending is now \n (might have been changed to nothing ealier)
	#
	$/ = "\n";

	#
	# Remove all the lines until we get to the line with "Weight Not To Exceed"
	#
	while ( $line = <RATE_FILE> ) {
		last if ( $line =~ /^Weight Not To Exceed/ );
	}
	
	# Remove "Weight Not To " from this line
	$line =~ s/^Weight Not To//;
	
	# Remove all occurences of "Zone" from this line
	$line =~ s/Zone//g;
	
	# Remove all the left-over spaces.
	$line =~ s/ //g;
	
	# Now-adjusted Header
	print NEW_RATE_FILE $line if $line;
	
	#
	# Remove blank lines before the data starts, if any
	#
	
	while ( $line = <RATE_FILE> ) {
		#
		# Skip the line if it is empty, or just has commas.
		#
		debug3( "checking line... $line" );
		
		next if ! $line;
		next if $line =~ /^\s+$/; 
		next if $line =~ /^(\,|\ )+$/;
		
		#
		# wwrates/ww-xp*
		# I don't really know what "Min" and "Per Pd." are for, so I'm deleting them.
		#
		last if $line =~ /^UPS Worldwide Express Box/;
		last if $line =~ /^Min/;
		last if $line =~ /^Per Pd\./;
		
		debug3( "Writing line... $line" );
		
		print NEW_RATE_FILE $line;
	}

	flock( 	RATE_FILE, 		LOCK_UN	) or die $@;
	close( 	RATE_FILE 				) or die $@;
	flock(	NEW_RATE_FILE, 	LOCK_UN	) or die $@;
	close(	NEW_RATE_FILE 			) or die $@;
	copy( 	$file2, 		$file 	) or die $@;
	unlink( $file2 					) or die $@;
	
	return;
}


sub do_download
{
	my ( $self ) = @_;
	my $data_dir = cfg()->{ general }->{ data_dir };
	debug( "data_dir = $data_dir" );
	
	my $us_origin_rates_url = cfg()->{ ups_information }->{ us_origin_rates_url };
	my $us_origin_zones_url = cfg()->{ ups_information }->{ us_origin_zones_url };
	my $us_origin_rates_filenames = cfg()->{ ups_information }->{ us_origin_rates_filenames };
	my $us_origin_zones_filenames = cfg()->{ ups_information }->{ us_origin_zones_filenames };
	my @us_origin_rates_filenames = split( ' ', $us_origin_rates_filenames );
	my @us_origin_zones_filenames = split( ' ', $us_origin_zones_filenames );
	
	if ( ! $self->disable_download() ) {
		Business::Shipping::Util::download_to_file( "$us_origin_zones_url/$_", "$data_dir/$_" ) foreach @us_origin_zones_filenames;
		Business::Shipping::Util::download_to_file( "$us_origin_rates_url/$_", "$data_dir/$_" ) foreach @us_origin_rates_filenames;
	}
	
	my @files_to_unzip = ( @us_origin_rates_filenames, @us_origin_zones_filenames );
	
	for ( @files_to_unzip ) {
		my $filename_without_extension = Business::Shipping::Util::filename_only( $_ );
		#
		# Disable splitting up the data.  I just want them in one big flat directory, for now.
		#
		#my $destionation_dir = "$filename_without_extension/";
		my $destionation_dir = '';
		debug3( "Going to unzip: $data_dir/$_ into directory $data_dir/$destionation_dir" );
		Business::Shipping::Util::_unzip_file(  "$data_dir/$_", "$data_dir/$destionation_dir" )
			unless $self->disable_unzip();
	}
	
	return;
}


=item * do_data_convert()

Find all data .csv files and convert them from the vanilla UPS CSV format
into one that Business::Shipping can use.

=cut
sub do_data_convert
{
	trace '()';
	my $self = shift;
	
	#
	# * Find all *rate* csv files in the data directory (and sub-dirs)
	# * Ignore zone files (because they can be used as-is) 
	# * Ignore other files (zip files, extented area, residential, domestic, fuel surcharge, etc. files).
	#
	
	my @files_to_process;
	my $find_rates_files_sub = sub {
		# Ignore zone directories, we only convert rates.
		return if ( $File::Find::dir =~ /zone/i );
		return if ( $_ =~ /zone/i );
		return if ( $_ =~ /\d\d\d/ );
		my $cvs_files_skip_regexes = cfg()->{ ups_information }->{ cvs_files_skip_regexes };
		#debug( "NOTE: " . Dumper( $cvs_files_skip_regexes ) );
		#$cvs_files_skip_regexes =~ s/\s+/ /g;
		#debug( "cvs_files_skip_regexes = $cvs_files_skip_regexes" );
		#my @cvs_files_skip_regexes = split( ' ', $cvs_files_skip_regexes );
		foreach my $cvs_files_skip_regex ( @$cvs_files_skip_regexes ) {
			$cvs_files_skip_regex =~ s/\s//g;
			#return if ( $_ =~ /$cvs_files_skip_regex/ );
			return if ( $_ eq $cvs_files_skip_regex );
		}
		
		
		# Only CSV files
		return if ( $_ !~ /\.csv$/i );
		
		# Ignore CVS files
		return if ( $_ eq '.' );
		return if ( $File::Find::dir =~ /CVS$/ );
		return if ( $_ eq 'CVS' );
		
		# Ignore Dirs
		return unless ( -f $_ );
		
		debug3( "$_\n" );
		
		push ( @files_to_process, $File::Find::name );
		return;
	};
	
	find( $find_rates_files_sub, cfg()->{ general }->{ data_dir } );
	
	
	
	my @cannot_convert_at_this_time = (
		#
		# International Export Accessorials
		#
		'wwrates/wwaccs.csv',
		
		#
		# Canada Export Accessorials
		#
		'canrates/canaccs.csv',
		
		#
		# U.S. Accessorials
		#
		'usrates/accessorials.csv',
		
		#
		# Domestic Areas Table
		#
		'usrates/xarea.csv',
		
		#
		# Hundred weight services not supported at this time.
		#
		'usrates/1dacwt.csv',
		'usrates/1dasavercwt.csv',
		'usrates/2dacwt.csv',
		'usrates/2damcwt.csv',
		'usrates/3dscwt.csv',
		'usrates/gndcwt.csv',
	);
	
	@cannot_convert_at_this_time = (
		#
		# International Export Accessorials
		#
		'wwaccs.csv',
		
		#
		# Canada Export Accessorials
		#
		'canaccs.csv',
		
		#
		# U.S. Accessorials
		#
		'accessorials.csv',
		
		#
		# Domestic Areas Table
		#
		'xarea.csv',
		
		#
		# Hundred weight services not supported at this time.
		#
		'1dacwt.csv',
		'1dasavercwt.csv',
		'2dacwt.csv',
		'2damcwt.csv',
		'3dscwt.csv',
		'gndcwt.csv',
	);
	
	
	#
	# add the data dir
	#
	my @temp;
	for ( @cannot_convert_at_this_time ) {
		push @temp, cfg()->{ general }->{ data_dir } . "/$_";
	}
	@cannot_convert_at_this_time = @temp;

	#
	# Remove the files that we cannot convert at this time.
	#
	@files_to_process = Business::Shipping::Util::remove_elements_of_x_that_are_in_y( \@files_to_process, \@cannot_convert_at_this_time );
	
	debug3( "files_to_process = " . join( "\n", @files_to_process ) );
	for ( @files_to_process ) {
		Business::Shipping::Util::remove_windows_carriage_returns( $_ );
		convert_ups_rate_file( $_ );
		my $new_filename = Business::Shipping::Util::remove_extension( $_ );
		rename_tables_that_start_with_numbers( $new_filename );
	}
}


sub rename_tables_that_start_with_numbers
{
	my $path = shift;
	trace "( $path )";
	
	$_ = $path;
	
	my ( $dir, $file ) = Business::Shipping::Util::split_dir_file( $path );
	
	if ( $file =~ /^\d/ ) {
		debug( "renaming $path => $dir/a_$file" );
		rename( $path, "$dir/a_$file" );
	}
	
	return;
}

	

sub _handle_response
{
	my $self = $_[ 0 ];
	
	if ( $self->auto_update() ) {
		$self->do_download();
		$self->do_data_convert();
	}

	#
	# Put things in $self->results() # a hash
	#
	#my %results = $self->calc_zone();
		
	
	#
	# Zones hash refrence not stored in object due to extreme size.
	#
	my $zones_ref = $self->calc_zone_data();
	
	my $total_charges;
	$total_charges = $self->calc_cost( $zones_ref->{ $self->zone_name() } );
	$total_charges += $self->calc_fuel_surcharge( $total_charges );
	$total_charges += $self->calc_residential_surcharge();
	
	
	# Round to two decimal points.
	$total_charges = Business::Shipping::Util::currency( { no_format => 1 }, $total_charges );
	#
	# 'return' method:
	# 1. Save a "results" hash.
	#
	# TODO: multi-package support: loop over the packages
	#
	my $packages = [
		{ 
			#description
			#package_id
			'charges' => $total_charges, 
		},
		#{
		#	#another package
		#	# 'charges' => ...
		#}
	];
	
	my $results = {
		$self->shipment->shipper() => $packages
	};
	debug3 'results = ' . uneval(  $results );
	$self->results( $results );
	
	return $self->is_success( 1 );
}

#
# TODO: Lookup the zip code in the xzones.csv chart, if found, add the $1.17
#
# For now, all it does is go by the user's specification.
#
sub calc_residential_surcharge
{
	my $self = shift;
	
	if ( $self->to_residential() ) {
		return 1.17
	}
	else {
		return 0;
	}
}
sub calc_fuel_surcharge
{
	my ( $self, $total_charges ) = @_;
	
	my $fuel_surcharge = cfg()->{ ups_information }->{ fuel_surcharge };
	$fuel_surcharge =~ s/\%//;
	$fuel_surcharge *= .01;
	$fuel_surcharge *= $total_charges;
	
	return $fuel_surcharge;
	
}
sub service_code_to_ups_name
{
	my ( $self, $service ) = @_;
	
	#
	# These are the names at the top of the zone file.
	#
	
	my $translate_map = cfg()->{ service_codes_to_ups_names_in_zone_file };
	
	debug3( "translate_map = " . Dumper( $translate_map ) );
		
	if ( $translate_map->{ $service } ) {
		return $translate_map->{ $service };
	}
	else {
		return $service;
	}
}

sub ups_name_to_table
{
	my ( $self, $ups_name ) = @_;
	
	my $translate_map = cfg()->{ ups_names_in_zone_file_to_table_map };
	
	if ( $translate_map->{ $ups_name } ) {
		return $translate_map->{ $ups_name };
	}
	else {
		return $ups_name;
	}
}


sub calc_cost
{
	my ( $self, $zref ) = @_;
	
	my @data;
	my @fieldnames;
	my $i;
	my $point;
	my $zone;
	my $type 	= $self->service_code_to_ups_name(	$self->service()	);
	my $table 	= $self->ups_name_to_table(			$type 				);
	my $zip = $self->to_zip;
	my $weight = $self->weight;
	my $code = 'u';
	my $opt = {};
	$opt->{residential} ||= $self->shipment()->to_residential();
	my $Values = {};
	
	#
	# TODO: validation checks...
	# 
	# Check that the GNDRES.csv database exists.
	# Check that the zone (e.g. 450) was defined.
	# Check that we have the zone data calculated.
	#
	
	if ( ! defined $zref->{zone_data} ) {
		$self->error( "lookup for this zone failed becuase zone data could not be found" );
		return undef;
	}

	my $zdata = $zref->{zone_data};
	# UPS doesn't like fractional pounds, rounds up

	# here we can adapt for pounds/kg
	if ($zref->{mult_factor}) {
		$weight = $weight * $zref->{mult_factor};
	}
	$weight = POSIX::ceil($weight);

	unless($opt->{no_zip_process}) {
		$zip =~ s/\W+//g;
		$zip = uc $zip;
	}

	my $rawzip = $zip;

	$zip = substr($zip, 0, ($zref->{str_length} || 3));

	@fieldnames = split /\t/, $zdata->[0];
	debug( "fieldnames = " . join( ' ', @fieldnames ) );
	for($i = 2; $i < @fieldnames; $i++) {
		debug( 'fieldname = ' .  $fieldnames[ $i ] );
		next unless $fieldnames[ $i ] eq $type;
		$point = $i;
		last;
	}

	unless (defined $point) {
		$self->error("Zone '$code' lookup failed, type '$type' not found");
		return undef;
	}

	my $eas_point;
	my $eas_zone;
	if($zref->{eas}) {
		for($i = 2; $i < @fieldnames; $i++) {
			next unless $fieldnames[$i] eq $zref->{eas};
			$eas_point = $i;
			last;
		}
	}

	debug("looking in zone data.");
	for(@{$zdata}[1..$#{$zdata}]) {
		@data = split /\t/, $_;
		next unless ($zip ge $data[0] and $zip le $data[1]);
		$zone = $data[ $point ];
		$eas_zone = $data[$eas_point] if defined $eas_point;
		return 0 unless $zone;
		last;
	}
	
	if (! defined $zone) {
		$self->error( "No zone found for geo code $zip, type $type. " );
		return undef;
	}
	elsif (!$zone or $zone eq '-') {
		$Vend::Session->{ship_message} .=
			"No $type shipping allowed for geo code $zip.";
		debug( "empty zone $zone." );
		return undef;
	}

	my $cost;
	debug( "going to call record( $table, $zone, $weight ) " );
	$cost =  record( $table, $zone, $weight );
	$cost += record( $table, $zone, $eas_zone )  if defined $eas_point;
	
	if ( ! $cost ) {
		$self->error( "Zero cost returned for mode $type, geo code $zip.");
		return;
	}
		
	
		
	debug( "cost = $cost" );
	if($cost > 0) {
		if($opt->{surcharge_table}) {
			$opt->{surcharge_field} ||= 'surcharge';
			my $xarea = record(
							$opt->{surcharge_table},
							$opt->{surcharge_field},
							$rawzip);
			$cost += $xarea if $xarea;
		}
		if($opt->{residential}) {
			#
			# Not implemented in the data yet.
			#			
			my $field = $opt->{residential_field} || 'res';
			my $res_charge = record( $table, $field, $weight );
			debug3( "residential check field=$field, type=" . ( $type ? $type : '' ) 
					. " weight = " . ( $weight ? $weight : '' )
					. ", res_charge: " . ( $res_charge ? $res_charge : '' ) );
			$cost += $res_charge if $res_charge;
		}
	}
	return $cost;
}

sub calc_zone_data
{
	trace( 'called' );
	my $self = $_[ 0 ];
	my %zones = ( 
		$self->zone_name() => {},
	);
	
	for (keys %zones) {
		my $ref = $zones{$_};
		if (! $ref->{zone_data}) {
			$ref->{zone_data} = Business::Shipping::Util::readfile( $self->zone_file() );
		}
		if ( ! $ref->{zone_data} ) {
			$self->error( "Bad shipping file for zone " . $_ . ", lookup disabled." );
			next;
		}
		my ( @zone ) = grep /\S/, split /[\r\n]+/, $ref->{zone_data};
		shift @zone while @zone and $zone[0] !~ /^(Postal|Dest.*Z)/;
		if ( $zone[ 0 ] =~ /^Postal/ ) {
			debug( 'this zone (' . $zone[ 0 ] . ') =~ ^Postal' );
			$zone[ 0 ] =~ s/,,/,/;
			for ( @zone[ 1 .. $#zone ] ) {
				s/,/-/;
			}
		}
		if ( $zone[ 0 ] !~ /\t/ ) {
			my $len = $ref->{str_length} || 3;
			@zone = grep /\S/, @zone;
			@zone = grep /^[^"]/, @zone;
			$zone[0] =~ s/[^\w,]//g;
			$zone[0] =~ s/^\w+/low,high/;
			@zone = grep /,/, @zone;
			$zone[0] =~	s/\s*,\s*/\t/g;
			for(@zone[1 .. $#zone]) {
				s/^\s*(\w+)\s*,/make_three($1, $len) . ',' . make_three($1, $len) . ','/e;
				s/^\s*(\w+)\s*-\s*(\w+),/make_three($1, $len) . ',' . make_three($2, $len) . ','/e;
				s/\s*,\s*/\t/g;
			}
		}
		$ref->{zone_data} = \@zone;
	}
	
	return \%zones;
}


sub make_three {
	my ($zone, $len) = @_;
	$len = 3 if ! $len;
	while ( length($zone) < $len ) {
		$zone = "0$zone";
	}
	return $zone;
}


sub _massage_values
{
	trace '()';
	my $self = shift;
	
	
	# TODO: do table lookup to find if it is residential or not.
	if ( $self->service() =~ /GNDRES/i ) {
		$self->to_residential( 1 );
	}
	
	#
	# Cache always disabled for Offline lookups: they are so fast already, the disk I/O
	# of cache-ing is not worth it.
	#
	$self->cache( 0 );
	
	my $zone = substr( $self->from_zip(), 0, 3 );
	$self->zone_name( $zone );
	my $zone_file = Business::Shipping::Config::support_files() . "/data/$zone.csv";
	
	#
	# If you can't find the zone file on the first try, try up to 10 times.
	# (Sometimes, zips like 97214 are in a different file, like 970).
	#
	for ( my $c = 10; $c >= 1; $c-- ) {
		if ( ! -f $zone_file ) {
			$zone--;
			$zone_file = Business::Shipping::Config::support_files() . "/data/$zone.csv";
		}
	}
	
	debug( "zone file = $zone_file");
	$self->zone_file( $zone_file );

}




1;
__END__

=pod

=head1 GLOSSARY

EAS		Extended Area Surcharge (EAS)

=cut