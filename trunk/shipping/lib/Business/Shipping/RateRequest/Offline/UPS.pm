# Business::Shipping::RateRequest::Offline::UPS
#
# $Id: UPS.pm,v 1.17 2004/02/08 00:42:24 db-ship Exp $
#
# Copyright (c) 2003 Interchange Development Group
# Copyright (c) 2003,2004 Kavod Technologies, Dan Browning. 
#
# All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 
# Portions based on the corresponding work in the Interchange project, which 
# was written by Mike Heins <mike@perusion.com>.  See http://www.icdevgroup.org
# for more info.
#

package Business::Shipping::RateRequest::Offline::UPS;

$VERSION = do { my @r=(q$Revision: 1.17 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping::RateRequest::Offline' );
use Business::Shipping::Shipment::UPS;
use Business::Shipping::Package::UPS;
use Business::Shipping::Debug;
use Business::Shipping::Data;
use Business::Shipping::Util( 'element_in_array' );
use Business::Shipping::Config;
use Data::Dumper;
use POSIX;
use Fcntl ':flock';
use File::Find;
use File::Copy;
use Math::BaseCnv;
use Scalar::Util 1.10;
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
	],
	#
	# Class Attributes
	#
	hash => [ '-static', 'Zones' ],
	;

use constant INSTANCE_DEFAULTS => ();
sub init
{
	my $self   = shift;
	my %values = ( INSTANCE_DEFAULTS, @_ );
	$self->hash_init( %values );
	return;
}


=head1 NAME

Offline::UPS - Calculates UPS rates from tables.

=head1 SPECIAL INFO

Countries that do not have Express Plus:

CA  Canada (it is possible to calculate the rate, but you have to call UPS to 
           find out if it is available).
NO  Norway

=head1 METHODS

=over 4

=item * zone_name()

  - For International, it's the name of the country (e.g. 'Canada')
  - For Domestic, it is the first three of a zip (e.g. '986')
  - For Canada, it is...?
  
=cut


sub to_residential { return shift->shipment->to_residential( @_ ); }
sub is_from_east_coast { return not shift->is_from_west_coast(); }

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
	
	if ( $line ) {
		# Remove "Weight Not To " from this line
		$line =~ s/^Weight Not To//;
		
		# Remove all occurences of "Zone" from this line
		$line =~ s/Zone//g;
		
		# Remove all the left-over spaces.
		$line =~ s/ //g;
		
		# Now-adjusted Header
		print NEW_RATE_FILE $line;
	}
	
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
	#
	# Convert the ewwzone.csv file manually, since it is skipped, above.
	#
	Business::Shipping::Util::remove_windows_carriage_returns( 
		cfg()->{ general }->{ data_dir } . '/ewwzone.csv' 
	);
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

sub validate
{
	my ( $self ) = @_;
	trace '()';
	
	return if ( ! $self->SUPER::validate );
	if ( $self->service and $self->service eq 'GNDRES' and $self->to_ak_or_hi ) {
		$self->error( "Invalid Rate Request" );
		$self->invalid( 1 );
	}
	
	return 1;
}

sub _handle_response
{
	my $self = $_[ 0 ];
	
	my $total_charges;
	$self->do_update();
	$self->calc_zone_data();
	$total_charges  = $self->calc_cost();
	$total_charges += $self->calc_express_plus_adder( $total_charges );
	$total_charges += $self->calc_fuel_surcharge( $total_charges );
	$total_charges += $self->calc_residential_surcharge( $total_charges );
	
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

	my ( $self, $total_charges ) = @_;
	trace "( $total_charges )";
	return 0 unless $total_charges;
	
	if ( $self->service_code_to_ups_name( $self->service() ) =~ /plus/i ) {
 		return cfg()->{ ups_information }->{ express_plus_adder } || 40.00;
	}
	
	return 0.00;
}

#
# TODO: Lookup the zip code in the xzones.csv chart, if found, add the $1.17
#
# For now, all it does is go by the user's specification.
#
sub calc_residential_surcharge
{
	my ( $self, $total_charges ) = @_;
	
	#
	# We must have some amount to add it to, before we add it.
	#
	if ( $self->to_residential and $total_charges ) {
		return 1.17;
	}
	else {
		return 0;
	}
}

sub calc_fuel_surcharge
{
	my ( $self, $total_charges ) = @_;
	
	my $fuel_surcharge = cfg()->{ ups_information }->{ fuel_surcharge } || do { $self->error( "fuel surcharge rate not found" ); return; };
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

=item * calc_zone_data()

* Modifies the class attribute Zones(), and adds data for the zone like so...

	$self->Zones() = (
		'Canada' => {
			'zone_data' => [
				'low	high	service1	service2',
				'004	005		208			209',
				'006	010		208			209',
				'Canada	Canada	504			504',
			]
		}
	)
	
=cut
sub calc_zone_data
{
	trace( 'called' );
	my ( $self ) = @_;
	
	my $zone_name = $self->zone_name;
	if ( ! $zone_name ) {
		$self->error( "No $zone_name, exiting..." );
		return;
	}
	
	#
	# Don't recalculate it if it already exists, unless overridden by configuration.
	#
	if 	(	
				$self->Zones( $zone_name ) 
			and ! cfg()->{ ups_information }->{ always_calc_zone_data }
		)
	{
		debug( "Zone $zone_name already defined, skipping." );
		return;
	}
	
	#
	# Initialize this zone
	#
	$self->Zones( $zone_name => {} );
	
	#
	# World-wide:  instead of 130-139,123,345, we have:
	#                         Albania,123,345
	#
	debug( 'looking for zone_name: ' . $zone_name . ", with zone_file: " . $self->zone_file );
	
	for ( keys %{ $self->Zones() } ) {
		my $this_zone = $self->Zones( $_ );
		if ( ! $this_zone->{ zone_data } ) {
			$this_zone->{ zone_data } = Business::Shipping::Util::readfile( $self->zone_file() );
		}
		if ( ! $this_zone->{ zone_data } ) {
			$self->error( "Bad shipping file for zone " . $_ . ", lookup disabled." );
			next;
		}
		my ( @zone ) = grep /\S/, split /[\r\n]+/, $this_zone->{ zone_data };
		shift @zone while @zone and $zone[0] !~ /^(Postal|Dest\. ZIP|Country)/;
		if ( $zone[ 0 ] and $zone[ 0 ] =~ /^Postal/ ) {
			debug3( 'this zone (' . $zone[ 0 ] . ') =~ ^Postal' );
			$zone[ 0 ] =~ s/,,/,/;
			for ( @zone[ 1 .. $#zone ] ) {
				s/,/-/;
			}
		}
		
		if ( $zone[ 0 ] and $zone[ 0 ] !~ /\t/ ) {
			@zone = grep /\S/, @zone;
			@zone = grep /^[^"]/, @zone;
			$zone[0] =~ s/[^\w,]//g;
			$zone[0] =~ s/^\w+/low,high/;
			@zone = grep /,/, @zone;
			$zone[0] =~	s/\s*,\s*/\t/g;
			
			#
			# Split into a tab-separated format.
			#
			my $count;
			for(@zone[1 .. $#zone]) {
				#debug( "before = $_" );
				my @columns = split( ',', $_ );
				if ( $columns[ 0 ] =~ /-/ ) {
					#
					# "601-605" =>	"601,605"
					#
					my ( $low, $high ) = split( '-', $columns[ 0 ] );
					splice( @columns, 0, 1, ( $low, $high ) );

				}
				else {
					#
					# Copy the country name (or zip with no range) into the second field.
					# "601" =>		"601,601"
					#
					splice( @columns, 1, 0, ( $columns[ 0 ]) );
				}
				$_ = join( ',', @columns );
				
				#
				# ","		=>	"	"
				#
				s/\s*,\s*/\t/g;

				#debug( "after = $_" );
				
				
			}
		}
		$this_zone->{ zone_data } = \@zone;
		
		#
		# TODO: Do I need to copy the $this_zone back into the Zones() hash?
		# Or does copying the reference, then modifying the reference do the
		# same thing?
		#
		# $self->Zones( $zone_name => $this_zone )
		#
	}
	
	return;
}

=item * determine_keys()

Decides what unique keys will be used to locate the zone record.  

 * The first key ("key") is a shortened version (the zip code "98682" becomes
   "986") to locate the zone file and the range that it fits into.
   
 * The second key ("raw_key") is the actual key, for looking up the record
   in the correct zone file once it has been found.

Returns ( $key, $raw_key )

=cut
sub determine_keys
{
	my ( $self ) = @_;
	
	my $key;
	my $raw_key;
	if ( $self->domestic_or_ca ) {
		#
		# Domestic and Canada - by ZIP code
		#
		$raw_key = $self->to_zip;
		$key = $self->to_zip;
		$key = substr($key, 0, 3);
		$key =~ s/\W+//g;
		$key = uc $key;
	}
	elsif ( $self->intl ) {
		#
		# International - by country name 
		#
		$key = $self->to_country;
		$raw_key = $key;
	}
	
	return ( $key, $raw_key );
}

=item * rate_table_exceptions

WorldWide methods use different tables for Canada

=cut
sub rate_table_exceptions
{
	my ( $self, $type, $table ) = @_;
	
	return $table unless $self->to_country;
	my $exceptions_cfg = cfg()->{ ups_names_in_zone_file_to_table_map_exceptions }->{ $self->to_country };
	return $table unless $exceptions_cfg;
	
	my $exceptions_hash = $self->config_to_hash( $exceptions_cfg ); 
	debug3( "type = $type, table = $table, looking for type in exceptions hash..." );
	
	if ( $exceptions_hash->{ $type } ) {
		$table = $exceptions_hash->{ $type };
		debug( "table exception found: $table" );
	}
	else {
		debug3( "No table exception found.  Returning regular table $table" );
	}
	
	return $table;
}

=item * calc_cost( )

* Modifies the class attribute $Zones, and adds data for the zone like so...

	$Zones => {
		'Canada' => {
			'zone_data' => [
				'first line of zone file',
				'second line',
				'etc.',
			]
		}
	}
	
=cut
sub calc_cost
{
	my ( $self ) = @_;
	
	my $zone_name 	= $self->zone_name;
	my $zref 		= $self->Zones( $zone_name );
	my $type 		= $self->service_code_to_ups_name(	$self->service()	);
	my $table 		= $self->ups_name_to_table(			$type 				);
	$table 			= $self->rate_table_exceptions( $type, $table );
	
	
	my ( $key, $raw_key ) = $self->determine_keys; 
	my @data;
	my @fieldnames;
	my $i;
	my $point;
	my $zone;
	
	my $rawzip;
	
	
	my $weight = $self->weight;
	my $code = 'u';
	my $opt = {};
	$opt->{residential} ||= $self->shipment()->to_residential();
	
	#
	# TODO: validation checks...
	# 
	# Check that the GNDRES.csv database exists.
	# Check that the zone (e.g. 450) was defined.
	# Check that we have the zone data calculated.
	#
	debug( "rate table = $table, zone_name = $zone_name" );
	if ( ! defined $zref->{zone_data} ) {
		$self->error( "zone data could not be found" );
		return 0;
	}
	
	my $zdata = $zref->{zone_data};
	
	#
	# Here we can adapt for pounds/kg
	#
	if ($zref->{mult_factor}) {
		$weight = $weight * $zref->{mult_factor};
	}
	
	#
	# Tables don't cover fractional pounds, so round up.
	#
	$weight = POSIX::ceil($weight);

	#
	# Handle eastcoast / westcoast fieldnames
	# Except for Canada.
	#
	if ( $self->to_canada ) {
		#
		# Remove the 'SM' from the end, Canada doesn't have that silliness.
		#
		$type =~ s/SM$//;
	}
	else {
		#
		# The only other Express/Expedited methods are intl.
		#
		if ( $type eq 'ExpressSM' ) {
			$type = $self->is_from_west_coast() ? 'ExpressSM_WC' : 'ExpressSM_EC';
		}
		elsif ( $type eq 'ExpeditedSM' ) {
			$type = $self->is_from_west_coast() ? 'ExpeditedSM_WC' : 'ExpeditedSM_EC';
		}
	}
	
	@fieldnames = split( /\t/, $zdata->[ 0 ] ) if $zdata->[ 0 ];
	debug( "Looking for $type in fieldnames: " . ( join( ' ', @fieldnames ) || 'undef' ) );
	
	for($i = 0; $i < @fieldnames; $i++) {
		debug( "checking $fieldnames[$i] eq $type" );
		next unless $fieldnames[ $i ] eq $type;
		$point = $i;
		last;
	}
	if ( ! defined $point) {
		$self->error( "Zone '$code' lookup failed, type '$type' not found" );
		return 0;
	}
	else {
		#
		# We have to add one because the International files don't have a "low	high", just "country".
		#
		$point++ if ! $self->domestic_or_ca;

		debug( "point (i.e. field index) found!  It is $point.  Fieldname referenced by point is $fieldnames[$point]" );
	}
	
	debug( "point = $point, looking in zone data..." );
	for ( @{ $zdata }[ 1.. $#{ $zdata } ] ) {
		@data = split /\t/, $_;
		debug( "data = " . join( ',', @data ) );
		if ( $self->current_shipment->domestic_or_ca ) {

			my $low		= $data[0];
			my $high	= $data[1];
			my $goal	= $key;
			
			if ( $self->current_shipment->to_canada ) {
				#
				# Canada uses a base-36 (0-10 + A-Z) zip number system.
				# Use a base converter to convert the numbers to base-10
				# just for the sake of comparison.
				#
				$low	= cnv( $low, 36, 10 );
				$high	= cnv( $high, 36, 10 );
				$goal	= cnv( $goal, 36, 10 );
			}
			#debug( "checking if $goal is between $low and $high" );
			next unless $goal and $low and $high;
			next unless $goal ge $low and $goal le $high;
			debug( "setting zone to $data[$point] (the line was: " . join( ',', @data ) . ")" );
			$zone = $data[ $point ];
		}
		else {
			next unless ( $data[0] and $key eq $data[0] );
			$zone = $data[ ( $point - 1) ];
			debug( "found key! data = " . join( ',', @data ) );
		}
		last;
	}
	
	$zone = $self->special_zone_hi_ak( $type, $zone );
	
	if (! defined $zone) {
		$self->error( "No zone found for geo code (key) $key, type $type. " );
		return 0;
	}
	elsif ( ! $zone or $zone eq '-') {
		$self->error( "No $type shipping allowed for $key." );
		$self->invalid( 1 );
		return 0;
	}

	my $cost;
	debug( "zone=$zone, going to call record( $table, $zone, $weight ) " );
	$cost =  record( $table, $zone, $weight );
	
	if ( ! $cost ) {
		$self->error( "Zero cost returned for mode $type, geo code (key) $key.");
		return 0;
	}
		
	debug( "cost = $cost" );
	#
	# TODO: Surcharge table + Surcharge_field?
	# TODO: Residential field (same table)?
	#
		
	return $cost || 0;
}

=item * special_zone_hi_ak( $type )

 $type	Type of service.
 
Hawaii and Alaska have special per-zipcode zone exceptions for 1da/2da.

=cut
sub special_zone_hi_ak
{
	my ( $self, $type, $zone ) = @_;
	trace( '( ' . ( $type ? $type : 'undef' ) . ', ' . ( $zone ? $zone : 'undef' ) . ' )' );
	
	return $zone unless $type and ( $type eq 'NextDayAir' or $type eq '2ndDayAir' ); 
	
	my @hi_special_zipcodes_124_224 = split( ',', ( cfg()->{ups_information}->{hi_special_zipcodes_124_224} or '' ) );
	my @hi_special_zipcodes_126_226 = split( ',', ( cfg()->{ups_information}->{hi_special_zipcodes_126_226} or '' ) );
	my @ak_special_zipcodes_124_224 = split( ',', ( cfg()->{ups_information}->{ak_special_zipcodes_124_224} or '' ) );
	my @ak_special_zipcodes_126_226 = split( ',', ( cfg()->{ups_information}->{ak_special_zipcodes_126_226} or '' ) );
	debug3( "zip=" . $self->to_zip . ".  Hawaii special zip codes = " . join( ",\t", @hi_special_zipcodes_124_224 ) );

	if ( 
			element_in_array( $self->to_zip(), @hi_special_zipcodes_124_224 )
		or
			element_in_array( $self->to_zip(), @ak_special_zipcodes_124_224 )
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
			element_in_array( $self->to_zip(), @hi_special_zipcodes_126_226 )
		or
			element_in_array( $self->to_zip(), @ak_special_zipcodes_126_226 )
		) 
	{
		if ( $type eq 'NextDayAir' ) {
			$zone = '126';
		}
		elsif ( $type eq '2ndDayAir' ) {
			$zone = '226';
		}
	}
	
	return $zone;
}

=item * calc_zone_info()

Determines which zone (zone_name), and which zone file to use for lookup.

=cut
sub calc_zone_info
{
	trace '()';
	my ( $self ) = @_;
	
	my $zone;
	my $zone_file;
	if ( $self->domestic ) {
		debug( "domestic" );
		$zone = $self->make_three( $self->from_zip );
		$zone_file = "/data/$zone.csv";
	}
	elsif ( $self->to_canada ) {
		debug( "to canada" );
		$zone = $self->make_three( $self->to_zip );
		
		if ( $self->service =~ /UPSSTD/i ) {
			#
			# TODO: Build a list of state names => "UPS Standard zone file names"
			# 
			if ( $self->from_ak_or_hi ) {
				#
				# An Alaska or Hawaii source has it's own complete set of data. :-(				
				#
				$self->error( "UPS Standard from Alaska or Hawaii not supported." ) and return;
			}
			my $state_to_upsstd_zone_file = cfg()->{ ups_information }->{ state_to_upsstd_zone_file };
			my $states = $self->config_to_hash( $state_to_upsstd_zone_file );
			debug( "my from_state = " . $self->from_state  );
			if ( $states->{ $self->from_state } ) {
				$zone_file = "/data/" . $states->{ $self->from_state };	
				debug3(	"Found state in the state to upsstd_zone_file configuration "
						. "parameter, zone_file = $zone_file " );
			}
			else {
				$self->error(
					"could not find state in \'state to UPS Standard zone file \' converter."
				);
				return;
			}
		}
		else {
			#
			# WorldWide Expedited/Express uses the 'canww' zone file.
			#
			$zone_file = "/data/canww.csv";
		}
	}
	else {
		$zone = $self->to_country();
		$zone_file = "/data/ewwzone.csv";
	}
	$zone_file = Business::Shipping::Config::support_files() . $zone_file;
	
	#
	# If you can't find the zone file on the first try, try up to 10 times.
	# (Sometimes, zips like 97214 are in a different file, like 970).
	# TODO: analyze all the zone files and use the metadata to build a map
	# of which zips go to which file.
	#
	# Only apply if the zone is purly numeric.
	#
	if ( Scalar::Util::looks_like_number( $zone ) ) {
		for ( my $c = 10; $c >= 1; $c-- ) {
			if ( ! -f $zone_file ) {
				debug( "zone_file $zone_file doesn't exist, trying others nearby..." );
				$zone--;
				$zone_file = Business::Shipping::Config::support_files() . "/data/$zone.csv";
			}
		}
	}
	
	debug( "zone_name = $zone, zone file = $zone_file");
	$self->zone_name( $zone );
	$self->zone_file( $zone_file );
	
	return;
}

=item * determine_coast

If this is an international order, we need to determine which state the shipper
is in, then if it is east or west coast.  If west, then use the first "Express" field
in the zone chart.  If east, then use the second.

=cut
sub determine_coast
{
	my ( $self ) = @_;
	
	#
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
	
	return;
}

	

=item * _massage_values()

Performs some final value modification just before the submit.

=cut
sub _massage_values
{
	my ( $self ) = @_;
	trace '()';
	
	#	
	# TODO: do table lookup to find if it is residential or not.
	# Currently, we just always assume it is residential.
	#
	$self->to_residential( 1 );
	$self->calc_zone_info;
	$self->determine_coast;
	
	return;
}

1;
__END__

=head1 GLOSSARY

EAS		Extended Area Surcharge (EAS)

=cut