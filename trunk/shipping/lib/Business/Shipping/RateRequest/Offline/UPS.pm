# Business::Shipping::RateRequest::Offline::UPS
#
# $Id: UPS.pm,v 1.6 2004/01/11 20:06:18 db-ship Exp $
#
# Copyright (c) 2003 Interchange Development Group
# Copyright (c) 2003 Kavod Technologies, Dan Browning. 
#
# All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 
# Portions based on the corresponding work in the Interchange project, which 
# was written by Mike Heins <mike@perusion.com>.  See http://www.icdevgroup.org
# for more info.
#

=head1 METHODS

=over 4

=cut

package Business::Shipping::RateRequest::Offline::UPS;

use strict;
use warnings;

use vars qw( $VERSION );
$VERSION = do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
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
use File::Find;
use File::Copy;

use Business::Shipping::CustomMethodMaker
	new_with_init => 'new',
	new_hash_init => 'hash_init',
	boolean => [
		'update',
		'download',
		'unzip', 
		'convert',
		'is_from_west_coast',
	],
	hash => [ 'zone' ],
	grouped_fields_inherit => [
		optional => [ 
			'zone_file', 
			'zone_name',
		],
		required => [
			'from_state',
		],
	];

use constant INSTANCE_DEFAULTS => (
);

sub init
{
	my $self   = shift;
	
	my %values = ( INSTANCE_DEFAULTS, @_ );
	$self->hash_init( %values );
	return;
}

sub to_residential { return shift->shipment->to_residential( @_ ); }
sub is_from_east_coast { return not $_[ 0 ]->is_from_west_coast(); }

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
	
	for ( @$us_origin_zones_filenames ) {
		s/\s//g;
		Business::Shipping::Util::download_to_file( "$us_origin_zones_url/$_", "$data_dir/$_" );
	}
	for ( @$us_origin_rates_filenames ) {
		s/\s//g;
		Business::Shipping::Util::download_to_file( "$us_origin_rates_url/$_", "$data_dir/$_" ) ;
	}
}

sub do_unzip
{
	for ( 
			@{ cfg()->{ ups_information }->{ us_origin_rates_filenames } },
			@{ cfg()->{ ups_information }->{ us_origin_zones_filenames } },
		)
	{
		#
		# Remove any leading spaces.
		#
		s/^\s//g;
		my $filename_without_extension = Business::Shipping::Util::filename_only( $_ );
		my $data_dir = cfg()->{ general }->{ data_dir };
		#
		# Disable splitting up the data.  I just want them in one big flat directory, for now.
		#
		#my $destionation_dir = "$filename_without_extension/";
		my $destionation_dir = '';
		debug3( "Going to unzip: $data_dir/$_ into directory $data_dir/$destionation_dir" );
		Business::Shipping::Util::_unzip_file(  "$data_dir/$_", "$data_dir/$destionation_dir" )
	}
	
	return;
}

=item * do_convert_data()

Find all data .csv files and convert them from the vanilla UPS CSV format
into one that Business::Shipping can use.

=cut
sub do_convert_data
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
		
		#
		# Now, we do translate zone files.
		#
		return if ( $File::Find::dir =~ /zone/i );
		return if ( $_ =~ /zone/i );
		return if ( $_ =~ /\d\d\d/ );
		my $cvs_files_skip_regexes = cfg()->{ ups_information }->{ csv_files_skip_regexes };
		foreach my $cvs_files_skip_regex ( @$cvs_files_skip_regexes ) {
			$cvs_files_skip_regex =~ s/\s//g;
			return if ( $_ eq $cvs_files_skip_regex );
		}
		
		
		# Only csv files
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
	
	my $cannot_convert_at_this_time = cfg()->{ ups_information }->{ cannot_convert };
	
	#
	# add the data dir
	#
	my @temp;
	for ( @$cannot_convert_at_this_time ) {
		debug( "cannot convert $_" );
		push @temp, cfg()->{ general }->{ data_dir } . "/$_";
	}
	$cannot_convert_at_this_time = \@temp;

	#
	# Remove the files that we cannot convert at this time.
	#
	@files_to_process = Business::Shipping::Util::remove_elements_of_x_that_are_in_y( \@files_to_process, $cannot_convert_at_this_time );
	
	debug3( "files_to_process = " . join( "\n", @files_to_process ) );
	for ( @files_to_process ) {
		Business::Shipping::Util::remove_windows_carriage_returns( $_ );
		convert_ups_rate_file( $_ );
		
		$_ = Business::Shipping::Util::remove_extension( $_ );
		$_ = rename_tables_that_start_with_numbers( $_);
		$_ = rename_tables_that_have_a_dash( $_ );
	}
	Business::Shipping::Util::remove_windows_carriage_returns( 'ewwzone.csv' );
	$self->convert_zone_file( 'ewwzone.csv' );
	
}

sub convert_zone_file
{
	my ( $self, $file ) = @_;
	trace "( $file )";
	$file =  cfg()->{ general }->{ data_dir } . "/$file";
	my $file2 = "$file.new";

	open( 		ZONE_FILE,		$file			) or die "Could not open file $file. $@";
	binmode( 	ZONE_FILE 						) if $Global::Windows;
	flock( 		ZONE_FILE, 		LOCK_EX 		) or die $@;
	open( 		NEW_ZONE_FILE,	">$file2"		) or die $@;
	binmode( 	NEW_ZONE_FILE 					) if $Global::Windows;
	flock( 		NEW_ZONE_FILE,	LOCK_EX			) or die $@;
	
	my $line;

	#
	# Line ending is now \n (might have been changed to nothing ealier)
	#
	$/ = "\n";

	#
	# Remove all the lines until we get to the line with "Weight Not To Exceed"
	#
	debug( "check zone file for ExpressSM..." );
	while ( $line = <ZONE_FILE> ) {
		if ( $line =~ /ExpressSM/ ) {
			debug( "changing ExpressSM to ExpressSM_WC, etc..." );
			#
			# Change *just* the first occurrence of ExpressSM to ExpressSM
			#
			$line =~ s/ExpressSM,/ExpressSM_WC,/;
			$line =~ s/ExpeditedSM,/ExpeditedSM_WC,/;
			
			#
			# Change *just* the first occurence (which will now ignore the "WC")
			#
			$line =~ s/ExpressSM,/ExpressSM_EC,/;
			$line =~ s/ExpeditedSM,/ExpeditedSM_EC,/;
			
			#
			# Remove the space in "Express Plus"
			#
			$line =~ s/Express PlusSM/ExpressPlusSM/;
		}
		print NEW_ZONE_FILE $line;
	}
	
	flock( 	ZONE_FILE, 		LOCK_UN	) or die $@;
	close( 	ZONE_FILE 				) or die $@;
	flock(	NEW_ZONE_FILE, 	LOCK_UN	) or die $@;
	close(	NEW_ZONE_FILE 			) or die $@;
	copy( 	$file2, 		$file 	) or die $@;
	unlink( $file2 					) or die $@;

	return;
}

sub rename_tables_that_start_with_numbers
{
	my $path = shift;
	trace "( $path )";
	
	$_ = $path;
	my $new_file = $_;
	
	my ( $dir, $file ) = Business::Shipping::Util::split_dir_file( $path );
	
	if ( $file =~ /^\d/ ) {
		$new_file = "$dir/a_$file";
		debug( "renaming $path => $new_file" );
		rename( $path, $new_file );
	}
	
	return $new_file;
}

sub rename_tables_that_have_a_dash
{
	my $path = shift;
	trace "( $path )";
	
	$_ = $path;
	my $new_file = $_;
	
	my ( $dir, $file ) = Business::Shipping::Util::split_dir_file( $path );
	
	if ( $file =~ /\-/ ) {
		$file =~ s/\-/\_/g;
		$new_file = "$dir/$file";
		debug( "renaming $path => $new_file" );
		rename( $path, $new_file );
	}
	
	return $new_file;
}

sub auto_update
{
	my ( $self ) = @_;
	$self->update( 1 );
	$self->do_update();
}

sub do_update
{
	my ( $self ) = @_;
	
	if ( $self->update ) {
		$self->download( 1 );
		$self->unzip( 1 );
		$self->convert( 1 );
	}
	
	$self->do_download() 		if $self->download;
	$self->do_unzip() 			if $self->unzip;
	$self->do_convert_data()	if $self->convert;
	
	return;
}	

sub _handle_response
{
	my $self = $_[ 0 ];
	
	$self->do_update();
	
	#
	# Zones hash refrence not stored in object due to extreme size.
	#
	my $zones_ref = $self->calc_zone_data();
	
	my $total_charges = $self->calc_cost( $zones_ref->{ $self->zone_name() } );
	$total_charges += $self->calc_express_plus_adder();
	$total_charges += $self->calc_fuel_surcharge( $total_charges );
	$total_charges += $self->calc_residential_surcharge();
	
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
	];
	
	my $results = {
		$self->shipment->shipper() => $packages
	};
	debug3 'results = ' . uneval(  $results );
	$self->results( $results );
	
	return $self->is_success( 1 );
}

sub calc_express_plus_adder
{
	trace '()';
	my ( $self ) = @_;
	my $adder;
	
	if ( $self->service_code_to_ups_name( $self->service() ) =~ /plus/i ) {
 		$adder = cfg()->{ ups_information }->{ express_plus_adder } || 40.00;
	}
	
	return $adder || 0.00;
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
	my $key;
	my $rawzip;
	if ( $self->intl() ) {
		$key = $self->to_country();
	}
	else {
		#
		# ZIP code
		#
		$key = $self->to_zip();
		$rawzip = $self->to_zip();
		
		$key = substr($key, 0, ($zref->{str_length} || 3));
		$key =~ s/\W+//g;
		$key = uc $key;
	}
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
	debug( "table = $table" );
	if ( ! defined $zref->{zone_data} ) {
		$self->error( "lookup for this zone failed becuase zone data could not be found" );
		return 0;
	}
	
	my $zdata = $zref->{zone_data};
	# UPS doesn't like fractional pounds, rounds up

	# here we can adapt for pounds/kg
	if ($zref->{mult_factor}) {
		$weight = $weight * $zref->{mult_factor};
	}
	$weight = POSIX::ceil($weight);

	@fieldnames = split /\t/, $zdata->[0];
	
	
	#
	# Handle eastcoast / westcoast fieldnames
	#
	if ( $type eq 'ExpressSM' ) {
		$type = $self->is_from_west_coast() ? 'ExpressSM_WC' : 'ExpressSM_EC';
	}
	elsif ( $type eq 'ExpeditedSM' ) {
		$type = $self->is_from_west_coast() ? 'ExpeditedSM_WC' : 'ExpeditedSM_EC';
	}
	
	debug( "fieldnames = " . join( ' ', @fieldnames ) );
	debug( "looking for field name $type" );
	
	for($i = 2; $i < @fieldnames; $i++) {
		debug( 'fieldname = ' .  $fieldnames[ $i ] );
		next unless $fieldnames[ $i ] eq $type;
		$point = $i;
		
		last;
	}
	
	if ( ! defined $point) {
		my $error = "Zone '$code' lookup failed, type '$type' not found";
		$self->error( $error );
		return 0;
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
	debug( "point = $point" );
	debug( "looking in zone data." );
	
	for ( @{ $zdata }[ 1.. $#{ $zdata } ] ) {
		#@data = split /\t/, $_;
		@data = split /\t/, $_;
		#debug "0 = $data[0]" if $data[0];
		#debug "1 = $data[1]" if $data[1];
		#debug "2 = $data[2]" if $data[2];
		#
		if ( $self->intl() ) {
			next unless ( $data[0] and $key eq $data[0] );
			$zone = $data[ ( $point - 1 ) ];
		}
		else {
			next unless $key and $data[0] and $data[1];
			next unless ($key ge $data[0] and $key le $data[1]);
			$zone = $data[ $point ];
		}
		
		
		$eas_zone = $data[$eas_point] if defined $eas_point;
		return 0 unless $zone;
		last;
	}
	#
	# For for special Hawaii/Alaska zip codes.
	#
	
	my @hi_special_zipcodes_124_224 = split( ',', cfg()->{ups_information}->{hi_special_zipcodes_124_224} );
	my @hi_special_zipcodes_126_226 = split( ',', cfg()->{ups_information}->{hi_special_zipcodes_126_226} );
	my @ak_special_zipcodes_124_224 = split( ',', cfg()->{ups_information}->{ak_special_zipcodes_124_224} );
	my @ak_special_zipcodes_126_226 = split( ',', cfg()->{ups_information}->{ak_special_zipcodes_126_226} );
	debug3( "hawaii special zip codes = " . join( ",\t", @hi_special_zipcodes_124_224 ) );
	debug( "my zip is = " . $self->to_zip );

	if ( 
			Business::Shipping::Util::element_e_in_array_a( $self->to_zip(), @hi_special_zipcodes_124_224 )
		or
			Business::Shipping::Util::element_e_in_array_a( $self->to_zip(), @ak_special_zipcodes_124_224 )
			
		) 
	{
		
		if ( $type eq 'NextDayAir' ) {
			$zone = '124';
		}
		elsif ( $type eq '2ndDayAir' ) {
			$zone = '224';
		}
	}
	if ( 
			Business::Shipping::Util::element_e_in_array_a( $self->to_zip(), @hi_special_zipcodes_126_226 )
		or
			Business::Shipping::Util::element_e_in_array_a( $self->to_zip(), @ak_special_zipcodes_126_226 )
			
		) 
	{
		if ( $type eq 'NextDayAir' ) {
			$zone = '126';
		}
		elsif ( $type eq '2ndDayAir' ) {
			$zone = '226';
		}
	}		
	
	if (! defined $zone) {
		$self->error( "No zone found for geo code (key) $key, type $type. " );
		return 0;
	}
	elsif (!$zone or $zone eq '-') {
		$Vend::Session->{ship_message} .=
			"No $type shipping allowed for geo code (key) $key.";
		debug( "empty zone $zone." );
		return 0;
	}

	my $cost;
	debug( "zone is $zone" );
	debug( "going to call record( $table, $zone, $weight ) " );
	$cost =  record( $table, $zone, $weight );
	$cost += record( $table, $zone, $eas_zone )  if defined $eas_point;
	
	if ( ! $cost ) {
		$self->error( "Zero cost returned for mode $type, geo code (key) $key.");
		return 0;
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
	return $cost || 0;
}

=item * calc_zone_data()

Worldwide zone file: ewwzone.csv

=cut
sub calc_zone_data
{
	trace( 'called' );
	my $self = $_[ 0 ];
	my %zones = ( 
		$self->zone_name() => {},
	);
	
	#
	# World-wide:  instead of 130-139,123,345, we have:
	#                         Albania,123,345
	#
	debug( 'looking for zone_name: ' . $self->zone_name );
	
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
		shift @zone while @zone and $zone[0] !~ /^(Postal|Dest\. ZIP|Country)/;
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
=item * make_three( $zone, $len )

If a zip code doesn't have leading zeros, add them.

=cut
sub make_three {
	my ($zone, $len) = @_;
	$len = 3 if ! $len;
	while ( length($zone) < $len ) {
		$zone = "0$zone";
	}
	return $zone;
}

=item * intl()

 - uses to_country() value to calculate.

 - returns 1/0 (true/false)

=cut
sub intl
{
	my $self = $_[ 0 ];
	if ( $self->shipment->to_country() ) {
		if ( $self->shipment->to_country() !~ /(US)|(United States)/) {
			return 1;
		}
	}
	return 0;
}

=item * _gp_translator(

General Purpose Translator.  Massages keyed values (like state and country
abbreviations).

	$val	The value to be translated, if possible
	$hash	The hash populated with values to be translated
	
=cut
sub _gp_translator
{
	my ( $self, $val, $hash ) = @_; 
	return unless $val and $hash;
	return $hash->{ $val } || $val;
}

=item * _build_hash_from_ary(

Builds a hash from an array of lines containing key / value pairs.

	$ary	Key/value pairs
	$del	Delimiter for the above array (tab is default)

=cut
sub _build_hash_from_ary
{
	my ( $self, $ary, $delimiter ) = @_;
	return unless $ary;
	$delimiter ||= "\t";
	
	my $hash = {};
	foreach my $line ( @$ary ) {
		my ( $key, $val ) = split( $delimiter, $line );
		$hash->{ $key } = $val;
	}
	
	return $hash;	
}

sub _massage_values
{
	trace '()';
	my $self = shift;
	
	my $simple_translations = cfg()->{ ups_information }->{ simple_translations };
	for ( @$simple_translations ) {
		my ( $value_to_translate, $translation_config_param ) = split( "\t", $_ );
		last unless $value_to_translate and $translation_config_param;
		debug( "Going to translate $value_to_translate ( " . ( $self->$value_to_translate() || 'undef' ) . " ) using $translation_config_param" );
		my $aryref = cfg()->{ ups_information }->{ $translation_config_param };
		my $hash = $self->_build_hash_from_ary( $aryref, "\t" );
		my $new_value = $self->_gp_translator( $self->$value_to_translate(), $hash );
		debug( "Setting $value_to_translate to new value: " . ( $new_value || 'undef' ) );
		$self->$value_to_translate( $new_value );
	}
	
	
	# TODO: do table lookup to find if it is residential or not.
	if ( $self->service() =~ /GNDRES/i ) {
		$self->to_residential( 1 );
	}
	
	#
	# Cache always disabled for Offline lookups: they are so fast already, the disk I/O
	# of cache-ing is not worth it.
	#
	$self->cache( 0 );
	
	my $zone;
	my $zone_file;
	if ( $self->intl() ) {
		$zone = $self->to_country();
		$zone_file = Business::Shipping::Config::support_files() . "/data/ewwzone.csv";
	}
	else {
		$zone = substr( $self->from_zip(), 0, 3 );
		$zone_file = Business::Shipping::Config::support_files() . "/data/$zone.csv";
	}
	
	$self->zone_name( $zone );
	
	#
	# If you can't find the zone file on the first try, try up to 10 times.
	# (Sometimes, zips like 97214 are in a different file, like 970).
	# TODO: analyze all the zone files and use the metadata to build a map
	# of which zips go to which file.
	#
	for ( my $c = 10; $c >= 1; $c-- ) {
		if ( ! -f $zone_file ) {
			$zone--;
			$zone_file = Business::Shipping::Config::support_files() . "/data/$zone.csv";
		}
	}
	
	debug( "zone file = $zone_file");
	$self->zone_file( $zone_file );
	
	#
	# If this is an international order, we need to determine which state the shipper
	# is in, then if it is east or west coast.  If west, then use the first "Express" field
	# in the zone chart.  If east, then use the second.
	#
	
	if ( $self->intl() and $self->from_state() ) {
		
		my $west_coast_states_aryref = cfg()->{ ups_information }->{ west_coast_states };
		my $east_coast_states_aryref = cfg()->{ ups_information }->{ east_coast_states };
		
		for ( @$west_coast_states_aryref ) {
			if ( $_ eq $self->from_state() ) {
				$self->is_from_west_coast( 1 );
			}
		}
		for ( @$east_coast_states_aryref ) {
			if ( $_ eq $self->from_state() ) {
				$self->is_from_west_coast( 0 );
			}
		}
	}
}

1;
__END__

=head1 GLOSSARY

EAS		Extended Area Surcharge (EAS)

=cut