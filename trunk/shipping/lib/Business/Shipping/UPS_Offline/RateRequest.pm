# Copyright (c) 2003 Interchange Development Group
# Copyright (c) 2003, 2004 Kavod Technologies, Dan Browning. 
#
# All rights reserved. 
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
#
# Portions based on the corresponding work in the Interchange project, which 
# was written by Mike Heins <mike@perusion.com>.  See http://www.icdevgroup.org
# for more info.

package Business::Shipping::UPS_Offline::RateRequest;

=head1 NAME

Business::Shipping::UPS_Offline::RateRequest

=head1 VERSION

$Rev$

=head1 GLOSSARY

=over 4

=item * EAS    Extended Area Surcharge

=item * DAS    Delivery Area Surcharge (same as EAS)

=back

=head1 METHODS

=cut

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };

use strict;
use warnings;
use base ( 'Business::Shipping::RateRequest::Offline' );
use Business::Shipping::UPS_Offline::Shipment;
use Business::Shipping::UPS_Offline::Package;
use Business::Shipping::Logging;
use Business::Shipping::Data;
use Business::Shipping::Util;
use Business::Shipping::Config;
use Data::Dumper;
use POSIX ( 'ceil' );
use Fcntl ':flock';
use File::Find;
use File::Copy;
use Math::BaseCnv;

=head2 update

=head2 download

=head2 unzip

=head2 convert

=head2 is_from_west_coast

=head2 is_from_east_coast

=head2 to_residential

=head2 Zones

Hash.  Format:

    $self->Zones() = (
        'Canada' => {
            'zone_data' => [
                'low    high    service1    service2',
                '004    005        208            209',
                '006    010        208            209',
                'Canada    Canada    504            504',
            ]
        }
    )

=head2 zone_file

=head2 zone_name

  - For International, it's the name of the country (e.g. 'Canada')
  - For Domestic, it is the first three of a zip (e.g. '986')
  - For Canada, it is...?

=cut

use Class::MethodMaker 2.0
    [ 
      new    => [ { -init => '_this_init' }, 'new' ],
      scalar => [
                  'update',
                  'download',
                  'unzip', 
                  'convert',
                  'is_from_west_coast',
                  'zone_file',
                  'zone_name',
                ],
                #
                # The forward is just for a shortcut.
                #
      scalar => [ { -type    => 'Business::Shipping::UPS_Offline::Shipment',
                    -default_ctor => 'new',
                    -forward => [ 
                                    'from_country',
                                    'from_country_abbrev',
                                    'to_country',
                                    'to_country_abbrev',
                                    'to_ak_or_hi',
                                    'from_zip',
                                    'to_zip',
                                    'packages',
                                    'weight',
                                    'shipper',
                                    'domestic',
                                    'intl',
                                    'domestic_or_ca',
                                    'from_canada',
                                    'to_canada',
                                    'from_ak_or_hi',
                                    'from_state',
                                    'from_state_abbrev',
                                ],
                   },
                   'shipment'
                 ],
      scalar => [ { -static => 1, 
                    -default => "shipment=>Business::Shipping::Shipment::UPS" 
                  }, 
                  'Has_a' 
               ],
      scalar => [ { -static => 1, -default => 'zone_file, zone_name' }, 'Optional' ],
      scalar => [ { -static => 1 }, 'Zones' ],
    ];

sub _this_init
{
    $_[ 0 ]->Zones(   {}    );
    return;
}
sub to_residential { return shift->shipment->to_residential( @_ ); }
sub is_from_east_coast { return not shift->is_from_west_coast(); }

=head2 convert_ups_rate_file

=cut


=head2 validate

=cut

sub validate
{
    my ( $self ) = @_;
    trace '()';
    
    return if ( ! $self->SUPER::validate );
    
    if ( $self->service_nick ) {
        if ( $self->service_nick eq 'GNDRES' and $self->to_ak_or_hi ) {
            $self->user_error( "Invalid Rate Request: Ground Residential to AK or HI." );
            $self->invalid( 1 );
            return 0;
        }
        
        if ( $self->service_nick eq 'UPSSTD' and not $self->to_canada ) {
            $self->user_error( "UPS Standard service is available to Canada only." );
            $self->invalid( 1 );
            return 0;
        }
    }
    
    if ( $self->to_canada and $self->to_zip and $self->to_zip =~ /\d\d\d\d\d/ ) {
        $self->user_error( "Cannot use US-style zip codes when sending to Canada" );
        $self->invalid( 1 );
        return 0;
    }

    return 1;
}

=head2 _handle_response
    
=cut

sub _handle_response
{
    my $self = $_[ 0 ];
    
    my $out;
    for ( qw/ weight / ) {
        $out .= "$_ = " . $self->$_();
    }
    #error( $out );
    
    my $total_charges;
    $self->calc_zone_data();
    
    # The fuel surcharge also applies to the following accessorial charges:
    #  * On-Call Pickup Charges
    #  * UPS Next Day Air Early A.M./UPS Express Plus Charges
    #  * International Extended Area Charges
    #  * Remote Delivery Charges
    #  * Saturday Delivery
    #  * Saturday Pickup
    # In other words, it applies *after* all the other surcharges have been added.
    
    my @price_components = (
        {
            component   => 'cost',
            description => 'Cost',
            fatal       => 1,
        },
        {
            component   => 'express_plus_adder',
            description => 'Express Plus',
        },
        {
            component   => 'delivery_area_surcharge',
            description => 'Delivery Area Surcharge',
        },
        {
            component   => 'fuel_surcharge',
            description => 'Fuel Surcharge',
        }
    );
    
    my $final_price_components;
    
    # This is where, for example, calc_cost, calc_fuel_surcharge, etc. get executed.
    foreach my $price_component ( @price_components ) {
        
        my $fn = "calc_" . $price_component->{ component };
        
        my $price;
        if ( $self->can( $fn ) ) { $price = $self->$fn(); }
        if ( ! $price ) {
            if ( $price_component->{ fatal } ) {
                return $self->is_success( 0 );
            }
            else {
                next;
            }
        }
        debug3 "adding price $price to final_components";
        
        push @$final_price_components, {
            price       => $price,
            description => $price_component->{ description }
        };
        $self->_increase_total_charges( $price );
    }
    
    $self->price_components( $final_price_components );

    $total_charges = Business::Shipping::Util::currency( 
        { no_format => 1 }, 
        $self->_total_charges 
    );
    
    my $name = $self->shipper();
    
    debug "total_charges = $total_charges";
    
    my $results = [
        {
            name  => $name,
            rates => [
                {
                    charges   => $total_charges,
                    charges_formatted => Business::Shipping::Util::currency( {}, $total_charges ),
                },
            ]
        }
    ];
    
    #debug3 'results = ' . uneval( $results );
    $self->results( $results );
    
    return $self->is_success( 1 );
}

=head2 $self->_increase_total_charges( $amount )

Increase the _total_charges by an amount.

=cut

sub _increase_total_charges
{
    my ( $self, $increase ) = @_;
    
    $self->_total_charges( ( $self->_total_charges || 0 ) + $increase );
    
    return;
}

=head2 calc_express_plus_adder

=cut

sub calc_express_plus_adder
{

    my ( $self ) = @_;
    
    if ( $self->service_name =~ /plus/i ) {
         return cfg()->{ ups_information }->{ express_plus_adder } || 40.00 
    }
    
    return 0;
}


=head2 calc_delivery_area_surcharge

The "Delivery Area Surcharge" is also known as "Extended Area Surcharge", but 
does not include special residential charges that apply to some services (air
services, for example).

=cut

# TODO: Instead of always applying this, only apply it if the zip is found
# in xarea.

# TODO: Calculate the delivery area surcharge amount from the accessorials.csv

sub calc_delivery_area_surcharge
{
    my ( $self ) = @_;
    
    if ( $self->domestic ) {
        return 1.75 if $self->to_residential;
        return 1.00;
    }
    
    return 0.00;
}

=head2 $self->calc_residential_surcharge()

Note that this is different than the delivery area surcharge
sub calc_residential_surcharge.  It is listed as "Residential Differential"
in the accessorials.csv file.

Currently $1.40.

=cut

sub calc_residential_surcharge
{
    my ( $self ) = @_;
    
    # I think the services that are excluded from this calculation are the 
    # following.
    # TODO: Residential surcharge: confirm that all the right services are 
    # included/excluded

    my $ups_service_name = $self->service_name;
    my @exempt_services = qw/
        Ground Commercial
        Ground Residential
        Ground Hundredweight Service
        Standard
    /;    
    
    return 1.40 if $self->to_residential;
    return 0;
}
    
=head2 calc_fuel_surcharge

=cut

sub calc_fuel_surcharge
{
    my ( $self ) = @_;
    
    # http://www.ups.com/content/us/en/resources/find/cost/fuel_surcharge.html
    # The surcharge applies to all domestic and International transportation 
    # charges except UPS Ground Commercial, UPS Ground Residential, UPS Ground
    # Hundredweight Service, and UPS Standard to Canada.
    
    my $ups_service_name = $self->service_name;
    
    # There are no exempt services as of Jan 3, 2005: everything has a fuel 
    # surcharge.
    #my @exempt_services = qw/
    #    Ground Commercial
    #    Ground Residential
    #    Ground Hundredweight Service
    #    Standard
    #/;
    #return 0 if grep /$ups_service_name/i, @exempt_services;
    
    my @ground_services = qw/
        Ground Commercial
        Ground Residential
        Ground Hundredweight Service
        Standard
    /;
    my $is_ground_svc = 0;
    $is_ground_svc = 1 if grep /$ups_service_name/i, @ground_services;
    
    my $fuel_surcharge_filename = Business::Shipping::Config::support_files 
    . '/config/fuel_surcharge.txt';
    
    my $fuel_surcharge_contents = readfile( $fuel_surcharge_filename );
    my ( $line1, undef, $line3 ) = split( "\n", $fuel_surcharge_contents );
    my ( undef, $g_fuel_surcharge ) = split( ': ', $line1 );
    my ( undef, $a_fuel_surcharge ) = split( ': ', $line3 );
    my $fuel_surcharge;
    if ( $is_ground_svc ) 
        { $fuel_surcharge = $g_fuel_surcharge; }
    else 
        { $fuel_surcharge = $a_fuel_surcharge; }
    
    $fuel_surcharge ||= 0;
    $fuel_surcharge  *= .01;
    $fuel_surcharge  *= $self->_total_charges;
    
    return $fuel_surcharge;
}

=head2 ups_name_to_table

=cut

sub ups_name_to_table
{
    my ( $self, $ups_name ) = @_;
    
    if ( ! $ups_name ) {
        $self->user_error( "Need ups_name parameter." );
        return;
    }
    
    my $translate_map = cfg()->{ ups_names_in_zone_file_to_table_map };
    
    if ( $translate_map->{ $ups_name } ) {
        my $name = $translate_map->{ $ups_name };
        if ( $name eq 'gndres' and ! $self->to_residential ) {
            return 'gndcomm';
        }
        return $name;
    }
    else {
        return $ups_name;
    }
}

=head2 calc_zone_data()

* Modifies the class attribute Zones(), and adds data for the zone like so...

    $self->Zones() = (
        'Canada' => {
            'zone_data' => [
                'low    high    service1    service2',
                '004    005        208            209',
                '006    010        208            209',
                'Canada    Canada    504            504',
            ]
        }
    )
    
=cut

sub calc_zone_data
{
    trace( 'called' );
    my ( $self ) = @_;
    
    my $zone_name = $self->zone_name;
    if ( not defined $zone_name ) {
        $self->user_error( "Need zone_name" );
        return;
    }
    
    #
    # Don't recalculate it if it already exists, unless overridden by configuration.
    #
    debug( "zone_name = $zone_name" );
    debug( "Zones = " . $self->Zones );
    
    if     (    
            $self->Zones->{ $zone_name } 
            and ! cfg()->{ ups_information }->{ always_calc_zone_data }
        )
    {
        debug( "Zone $zone_name already defined, skipping." );
        return;
    }
    
    #
    # Initialize this zone
    #
    $self->Zones->{ $zone_name } = {};
    
    #
    # World-wide:  instead of 130-139,123,345, we have:
    #                         Albania,123,345
    #
    debug( 'looking for zone_name: ' . $zone_name . ", with zone_file: " . $self->zone_file );
    
    for ( keys %{ $self->Zones } ) {
        my $this_zone = $self->Zones->{ $_ };
        if ( ! $this_zone->{ zone_data } ) {
            $this_zone->{ zone_data } = Business::Shipping::UPS_Offline::RateRequest::readfile( $self->zone_file() );
        }
        if ( ! $this_zone->{ zone_data } ) {
            $self->user_error( "Bad shipping file for zone " . $_ . ", lookup disabled." );
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
            $zone[0] =~    s/\s*,\s*/\t/g;
            
            #
            # Split into a tab-separated format.
            #
            my $count;
            for(@zone[1 .. $#zone]) {
                #debug( "before = $_" );
                my @columns = split( ',', $_ );
                if ( not $columns[ 0 ] ) {
                    debug "Nothing in the first column, zone was expected.";
                    next;
                }
                
                if ( $columns[ 0 ] =~ /-/ ) {
                    #
                    # "601-605" =>    "601,605"
                    #
                    my ( $low, $high ) = split( '-', $columns[ 0 ] );
                    splice( @columns, 0, 1, ( $low, $high ) );

                }
                else {
                    #
                    # Copy the country name (or zip with no range) into the second field.
                    # "601" =>        "601,601"
                    #
                    splice( @columns, 1, 0, ( $columns[ 0 ]) );
                }
                $_ = join( ',', @columns );
                
                #
                # ","        =>    "    "
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

=head2 determine_keys()

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
        
        if ( ! $self->to_zip ) {
            $self->user_error( "Need to_zip." );
            return;
        }
        
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

=head2 rate_table_exceptions

WorldWide methods use different tables for Canada

=cut

sub rate_table_exceptions
{
    my ( $self, $type, $table ) = @_;
    
    return $table unless $self->to_country;
    my $exceptions_cfg = cfg()->{ ups_names_in_zone_file_to_table_map_exceptions }->{ $self->to_country };
    return $table unless $exceptions_cfg;
    
    my $exceptions_hash = config_to_hash( $exceptions_cfg ); 
    debug3( "type = $type, table = $table, looking for type in exceptions hash..." );
    
    if ( $exceptions_hash->{ $type } ) {
        $table = $exceptions_hash->{ $type };
        debug3( "table exception found: $table" );
    }
    else {
        debug3( "No table exception found.  Returning regular table $table" );
    }
    
    return $table;
}

=head2 calc_cost( )

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
    
    if ( ! $self->zone_name ) {
        $self->user_error( "Need zone_name" );
        return;
    }
    if ( ! $self->shipment->service_nick2 ) {
        $self->user_error( "Need service" );
        return;
    }
    
    my $zone_name = $self->zone_name;
    my $zref      = $self->Zones->{ $zone_name };
    my $type      = $self->shipment->service_nick2;
    my $table     = $self->ups_name_to_table(        $type            );
    $table        = $self->rate_table_exceptions(    $self->shipment->service_nick, $table    );
    
    
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
    debug( "rate table = " . ( $table ? $table : 'undef' ) . ", zone_name = " . ( $zone_name ? $zone_name : 'undef' ) );
    if ( ! defined $zref->{zone_data} ) {
        $self->user_error( "zone data could not be found" );
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
        $self->user_error( "Zone '$code' lookup failed, type '$type' not found" );
        return 0;
    }
    else {
        #
        # We have to add one because the International files don't have a "low    high", just "country".
        #
        $point++ if ! $self->domestic_or_ca;

        debug( "point (i.e. field index) found!  It is $point.  Fieldname referenced by point is $fieldnames[$point]" );
    }
    
    debug( "point = $point, looking in zone data..." );
    for ( @{ $zdata }[ 1.. $#{ $zdata } ] ) {
        @data = split /\t/, $_;
        debug3( "data = " . join( ',', @data ) );
        if ( $self->shipment->domestic_or_ca ) {

            my $low        = $data[0];
            my $high    = $data[1];
            my $goal    = $key;
            
            if ( $self->shipment->to_canada ) {
                #
                # Canada uses a base-36 (0-10 + A-Z) zip number system.
                # Use a base converter to convert the numbers to base-10
                # just for the sake of comparison.
                #
                $low  = cnv( $low, 36, 10 );
                $high = cnv( $high, 36, 10 );
                $goal = cnv( $goal, 36, 10 );
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
    
    if ( not defined $zone ) {
        $self->user_error( 
            "No zone found for geo code (key) " . ( $key || 'undef' ) . ", " 
            . "type " . ( $type || 'undef' ) . '.' 
        );
        return 0;
    }
    elsif ( ! $zone or $zone eq '-') {
        $self->user_error( "No $type shipping allowed for $key." );
        $self->invalid( 1 );
        return 0;
    }

    # Some UPS files (ww_xpr) do not have a record for every weight (e.g. 55). 
    # To solve the problem, add 1 to the weight, and try again.

    my $cost;
    for ( my $tries = 0; $tries <= 5; $tries++ ) {
        debug( "zone=$zone, going to call record( $table, $zone, " . ( $weight + $tries ) . " ) " );
        $cost = record( $table, $zone, $weight + $tries );
        last if $cost;
    }
    
    if ( ! $cost ) {
        $self->user_error( "Zero cost returned for mode $type, geo code (key) $key.");
        return 0;
    }
   
    debug "cost = $cost";
    #
    # TODO: Surcharge table + Surcharge_field?
    # TODO: Residential field (same table)?
    #
    
    return $cost || 0;
}

=head2 special_zone_hi_ak( $type )

 $type    Type of service.
 
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

    my $to_zip = $self->to_zip;
    if ( grep( /^$to_zip$/, @hi_special_zipcodes_124_224, @ak_special_zipcodes_124_224 ) ) {
        if ( $type eq 'NextDayAir' ) {
            $zone = '124';
        }
        elsif ( $type eq '2ndDayAir' ) {
            $zone = '224';
        }
    }
    if ( grep( /^$to_zip$/, @hi_special_zipcodes_126_226, @ak_special_zipcodes_126_226 ) ) {
        if ( $type eq 'NextDayAir' ) {
            $zone = '126';
        }
        elsif ( $type eq '2ndDayAir' ) {
            $zone = '226';
        }
    }
    
    return $zone;
}

=head2 calc_zone_info()

Determines which zone (zone_name), and which zone file to use for lookup.

=cut

sub calc_zone_info
{
    trace '()';
    my ( $self ) = @_;
    
    my $zone;
    my $zone_file;
    my $data_dir_name = Business::Shipping::Config::data_dir_name();
    if ( $self->domestic ) {
        debug( "domestic" );
        if ( ! $self->from_zip ) {
            $self->user_error( "Need from_zip" );
            return;
        }
        debug( "from_zip = " . $self->from_zip );
        $zone = $self->make_three( $self->from_zip );
        #debug( "!!!!!!!!!!!!!") ;
        $zone_file = "$zone.csv";
    }
    elsif ( $self->to_canada ) {
        debug( "to canada" );
        $zone = $self->make_three( $self->to_zip );
        
        if ( $self->service_nick eq 'UPSSTD' ) {
            #
            # TODO: Build a list of state names => "UPS Standard zone file names"
            # 
            if ( $self->from_ak_or_hi ) {
                #
                # An Alaska or Hawaii source has it's own complete set of data. :-(                
                #
                $self->user_error( "UPS Standard from Alaska or Hawaii not supported." ) and return;
            }
            my $state_to_upsstd_zone_file = cfg()->{ ups_information }->{ state_to_upsstd_zone_file };
            my $states = config_to_hash( $state_to_upsstd_zone_file );

            if ( $self->from_state_abbrev and $states->{ $self->from_state_abbrev } ) {
                $zone_file = $states->{ $self->from_state_abbrev };    
                debug3(    "Found state in the state to upsstd_zone_file configuration "
                         . "parameter, zone_file = $zone_file " );
            }
            else {
                $self->user_error(
                    "could not find state in \'state to UPS Standard zone file\' converter."
                );
                return;
            }
        }
        else {
            #
            # WorldWide Expedited/Express uses the 'canww' zone file.
            #
            $zone_file = "canww.csv";
        }
    }
    else {
        $zone = $self->to_country();
        
        $zone_file = 'ewwzone.csv';
    }
    my $data_dir = Business::Shipping::Config::data_dir();
    $zone_file = "$data_dir/$zone_file";
    
    # If you can't find the zone file on the first try, try up to 10 times.
    # (Sometimes, zips like 97214 are in a different file, like 970).
    # TODO: analyze all the zone files and use the metadata to build a map
    # of which zips go to which file.
    #
    # Only apply if the zone is purly numeric.

    if ( Business::Shipping::Util::looks_like_number( $zone ) ) {
        for ( my $c = 10; $c >= 1; $c-- ) {
            if ( ! -f $zone_file ) {
                debug( "zone_file $zone_file doesn't exist, trying others nearby..." );
                $zone--;
                $zone_file = "$data_dir/$zone.csv";
            }
        }
    }
    
    debug( "zone_name = $zone, zone file = $zone_file");
    $self->zone_name( $zone );
    $self->zone_file( $zone_file );
    
    return;
}

=head2 determine_coast

If this is an international order, we need to determine which state the shipper
is in, then if it is east or west coast.  If west, then use the first "Express" field
in the zone chart.  If east, then use the second.

=cut

sub determine_coast
{
    my ( $self ) = @_;
    
    if ( $self->intl() and $self->from_state() ) {
        
        my @west_coast_states_abbrev = split( ',', cfg()->{ ups_information }->{ west_coast_states } );
        my @east_coast_states_abbrev = split( ',', cfg()->{ ups_information }->{ east_coast_states } );
        
        for ( @west_coast_states_abbrev ) {
            if ( $_ eq $self->from_state_abbrev() ) {
                $self->is_from_west_coast( 1 );
            }
        }
        for ( @east_coast_states_abbrev ) {
            if ( $_ eq $self->from_state_abbrev() ) {
                $self->is_from_west_coast( 0 );
            }
        }
    }
    
    return;
}

=head2 * readfile( $file )

Note: this is not an object-oriented method.

=cut

sub readfile
{
    my ( $file ) = @_;
    
    return undef unless open( READIN, "< $file" );
    
    # TODO: Use English;
    
    undef $/;
    
    my $contents = <READIN>;
    close( READIN );
    
    return $contents;
}

=head2 * writefile( $filename, $filecontents )

Note: this is not an object-oriented method.

=cut

sub writefile
{
    my ( $filename, $contents ) = @_;
    
    return unless open( OUT, "> $filename" );
    
    # TODO: Use English;
    
    undef $/;
    
    print OUT $contents;
    
    return $contents;
}


=head2 _massage_values()

Performs some final value modification just before the submit.

=cut

sub _massage_values
{
    my ( $self ) = @_;
    trace '()';

    # In order to share the Shipment::UPS object between both UPS_Online and
    # UPS_Offline, we do a little magic.  If it gets more complex than this,
    # subclass it instead.

    $self->shipment->offline( 1 );
    
    # Default is residential: yes.

    if ( not defined $self->to_residential ) { $self->to_residential( 1 ); }
    $self->calc_zone_info;
    $self->determine_coast;
    
    return;
}

1;

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut

