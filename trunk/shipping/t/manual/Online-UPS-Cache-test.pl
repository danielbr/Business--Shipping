#!/usr/bin/perl

#
# TODO: This test is acting as if it was always 1 pound.
#
# This probably means that the cache isn't working correctly.
#
# That is probably due to the changes in Unique().
#
#

use strict;
use warnings;
use Business::Shipping;
use Test::More 'no_plan';
use Carp;
use Business::Shipping;

`rm -Rf /tmp/FileCache/`;

$::debug = 1;
sub debug
{
    print STDERR $_[ 0 ] . "\n" if $::debug;
}
sub test
{
    my ( %args ) = @_;
    my $shipment = Business::Shipping->rate_request( 
        'shipper' => 'UPS',
        'user_id'        => $ENV{ UPS_USER_ID },
        'password'        => $ENV{ UPS_PASSWORD },
        'access_key'    => $ENV{ UPS_ACCESS_KEY }, 
        'cache'    => 0,
        event_handlers => {
            #trace => 'STDERR', 
        }
    );
    $shipment->submit( %args ) or die $shipment->user_error();
    return $shipment;
}


    my $rr1 = test(
        'cache'        => 1,
        'pickup_type'         => 'daily pickup',
        'from_zip'            => '98682',
        'from_country'        => 'US',
        'to_country'        => 'US',    
        'service'            => '1DA',
        'to_residential'    => '1',
        'to_zip'            => '98270',
        'weight'            => 2,
        'packaging'         => '02',
    );
    $rr1->submit() or die $rr1->user_error();
    my $total_charges_2_pounds = $rr1->total_charges();
    debug( "Cache test. 2 pounds = $total_charges_2_pounds" ); 
    
    my $rr2 = test(
        'cache'                => 1,
        'pickup_type'         => 'daily pickup',
        'from_zip'            => '98682',
        'from_country'        => 'US',
        'to_country'        => 'US',    
        'service'            => '1DA',
        'to_residential'    => '1',
        'to_zip'            => '98270',
        'weight'            => 9,
        'packaging'         => '02',
    );
    $rr2->submit() or die $rr2->user_error();
    my $total_charges_9_pounds = $rr2->total_charges();
    debug( "Cache test. 9 pounds = $total_charges_9_pounds" );
    ok( $total_charges_2_pounds != $total_charges_9_pounds, 'UPS domestic cache, sequential charges are different' );
 


