#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Carp;
use Business::Shipping;

my $standard_method = new Business::Shipping->rate_request( shipper => 'Online::USPS' );
ok( defined $standard_method,    'USPS standard object construction' );

my $other_method = new Business::Shipping::RateRequest::Online::USPS;
ok( defined $other_method,        'USPS alternate object construction' );

my $package = new Business::Shipping::Package::USPS;
ok( defined $package,            'USPS package object construction' );

sub test
{
    my ( %args ) = @_;
    my $shipment = Business::Shipping->rate_request( 
        shipper        => 'USPS',
        user_id        => $ENV{ USPS_USER_ID },
        password       => $ENV{ USPS_PASSWORD },
        cache          => 0,
        event_handlers => {
            #trace => 'STDERR', 
        },
    );
    $shipment->submit( %args ) or die $shipment->user_error();
    return $shipment;
}

sub simple_test
{
    my ( %args ) = @_;
    my $shipment = test( %args );
    $shipment->submit() or die $shipment->user_error();
    my $total_charges = $shipment->total_charges(); 
    my $msg = 
            "USPS Simple Test: " 
        .    ( $args{ weight } ? $args{ weight } . " pounds" : ( $args{ pounds } . "lbs and " . $args{ ounces } . "ounces" ) )
        .    " to " . ( $args{ to_city } ? $args{ to_city } . " " : '' )
        .    $args{ to_zip } . " via " . $args{ service }
        .    " = " . ( $total_charges ? '$' . $total_charges : "undef" );
    ok( $total_charges,    $msg );
}


# skip the rest of the test if we don't have username/password
SKIP: {
    skip( 'USPS: we need the username and password', 5 ) 
        unless ( $ENV{ USPS_USER_ID } and $ENV{ USPS_PASSWORD } );
    
    my $shipment;
    $shipment = test(
        'test_mode'  => 1,
        'service'    => 'EXPRESS',
        'from_zip'   => '20770',
        'to_zip'     => '20852',
        'pounds'     => 10,
        'ounces'     => 0,
        'container'  => 'None',
        'size'       => 'REGULAR',
        'machinable' => '',
    );
    ok( $shipment->total_charges(),     'USPS domestic test total_charges > 0' );
    
    $shipment = test(
        'test_mode'  => 1,
        'pounds'     => 0,
        'ounces'     => 1,
        'mail_type'  => 'Postcards or Aerogrammes',
        'to_country' => 'Algeria',
    );
    ok( $shipment->total_charges(),     'USPS intl test total_charges > 0' );
        
    $shipment = test(
        'test_mode'        => 0,
        'from_zip'         => '98682',
        'to_country'     => 'United States',
        'service'         => 'Priority',
        'to_zip'        => '96826',
        'from_country'     => 'US',
        'pounds'        => '2',
    ); 
    ok( $shipment->total_charges(),        'USPS domestic production total_charges > 0' );
    
    
    if ( 0 ) {
        # These are just more domestic production tests for "Priority Mail"
        $shipment = test(
            'from_zip'              => '98682',
            weight          => 0.2,
            to_zip          => '98270',
            service         => 'Priority',
        );
        
        print test_domestic(
                weight          => 3.5,
                to_zip          => '99501',
                service         => 'Priority',
        );
        
        print test_domestic(
                'to_zip' => '96826',
                'weight' => '2',
                'service' => 'Priority',
        );
    }
    
    $shipment = test(
        'test_mode'        => 0,
        'service'         => 'Airmail Parcel Post',
        'weight'        => 1,
        'ounces'        => 0,
        'mail_type'        => 'Package',
        'to_country'    => 'Great Britain',
        
    );
    ok( $shipment->total_charges(),        'USPS intl production total_charges > 0' );
    
    # Cache Test
    # - Multiple sequential queries should give *different* results.
    $shipment = test(
        'cache'    => 1,
        'test_mode'        => 0,
        'service'         => 'Airmail Parcel Post',
        'weight'        => 1,
        'ounces'        => 0,
        'mail_type'        => 'Package',
        'to_country'    => 'Great Britain',
    );
    
    my $total_charges_1_pound = $shipment->total_charges();
    
    $shipment = test(
        'cache'    => 1,
        'test_mode'        => 0,
        'service'         => 'Airmail Parcel Post',
        'weight'        => 10,
        'ounces'        => 0,
        'mail_type'        => 'Package',
        'to_country'    => 'Great Britain',
    );
    
    my $total_charges_5_pounds = $shipment->total_charges();
    
    ok( $total_charges_1_pound != $total_charges_5_pounds,    'USPS intl cache saves results separately' ); 

    
    ###########################################################################
    ##  Zip Code Testing
    ###########################################################################
    # Vancouver, Vermont, Alaska, Hawaii
    my @several_very_different_zip_codes = ( '98682', '22182', '99501' );
    my %charges;
    foreach my $zip ( @several_very_different_zip_codes ) {
        $shipment = test(
            'cache'    => 1,
            'test_mode'        => 0,
            'service'         => 'Priority',
            'weight'        => 5,
            'to_zip'        => $zip,
            'from_zip'        => 98682
        );
        $charges{ $zip } = $shipment->total_charges();
    }
    
    # Somehow make sure that all the values in %charges are unique.
    my $found_duplicate;
    foreach my $zip1 ( keys %charges ) {
        foreach my $zip2 ( keys %charges ) {
            
            # Skip this zip code, only testing the others.
            next if $zip2 eq $zip1;
            
            if ( $charges{ $zip1 } == $charges{ $zip2 } ) {
                $found_duplicate = $zip1;
            }
        }
    }
    
    ok( ! $found_duplicate, 'USPS different zip codes give different prices' );
    
    ##########################################################################
    ##  SPECIFIC CIRCUMSTANCES
    ##########################################################################
    
    $shipment = test(
        service     => 'Priority',
        weight        => 22.5,
        to_zip        => 27713,
        from_zip    => 98682,
    );
    #print "\ttotal charges = " . $shipment->total_charges() . "\n";
    ok( $shipment->total_charges() > 20.00,        'USPS high weight is high price' );
    
    #simple_test(
    #    from_zip    => '98682',
    #    service        => 'Airmail Parcel Post',
    #    to_country    => 'Bosnia-Herzegowina',
    #    weight        => 5,
    #);
    
    #
    # This tries to test to make sure that the shipping matches up right
    #  - So that Airmail parcel post goes to Airmail parcel post, etc.
    #
    $shipment = test(
        service         => 'Airmail Parcel Post',
        
        from_zip        => '98682',
        user_id         => $ENV{ USPS_USER_ID },        
        password         => $ENV{ USPS_PASSWORD },
        
        to_zip => 6157,
        to_country => 'Australia',
        weight => 0.50,
    );
    my $airmail_parcel_post_to_AU = $shipment->total_charges();
    ok( $airmail_parcel_post_to_AU,        'USPS australia' );
    
    
    # Test the letter service.
    $shipment = test(
        service         => 'Airmail Letter-post',
        
        from_zip        => '98682',
        user_id         => $ENV{ USPS_USER_ID },        
        password         => $ENV{ USPS_PASSWORD },
        
        to_zip => 6157,
        to_country => 'Australia',
        weight => 0.50,
    );
    my $airmail_letter_post_to_AU = $shipment->total_charges();
    #print "\ttotal charges = $airmail_letter_post_to_AU\n";
    ok( $airmail_letter_post_to_AU < $airmail_parcel_post_to_AU, 'USPS Letter is cheaper than Parcel' );
    
    
    
    #
    # Letter to Canada:
    #
    $shipment = test(
        service         => 'Airmail Letter-post',

        from_zip        => '98682',
        user_id         => $ENV{ USPS_USER_ID },        
        password         => $ENV{ USPS_PASSWORD },
        
        'to_zip' => "N2H6S9",
        to_country => 'Canada',
        'weight' => "0.25",
    );
    my $airmail_letter_post_to_CA = $shipment->total_charges();
    #print "\ttotal charges = $airmail_letter_post_to_CA\n";
    ok( $airmail_letter_post_to_CA < 7.50, 'USPS Letter to Canada is under $7.50' );
    
    
    #######################################################################
    ##  Canada Services
    #######################################################################
    
    $shipment = test(
        service         => 'Airmail Parcel Post',
        
        from_zip        => '98682',
        user_id         => $ENV{ USPS_USER_ID },        
        password         => $ENV{ USPS_PASSWORD },
        
        to_country        => 'Canada',
        to_zip            => 'N2H6S9',
        weight            => 5.5,
    );
    ok( $shipment->total_charges(), 'USPS Parcel Post to Canada' );
    
    
    
} # /skip
