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
        'shipper'    => 'UPS_Online',
        'user_id'    => $ENV{ UPS_USER_ID },
        'password'   => $ENV{ UPS_PASSWORD },
        'access_key' => $ENV{ UPS_ACCESS_KEY }, 
        'cache'      => 0,
    );
    $shipment->submit( %args ) or die $shipment->user_error();
    return $shipment;
}

    my %similar = (
        'service'        => '1DA',
        'from_zip'       => '98682',
        'to_zip'         => '98270',
    );
    my $rr1 = test(
        %similar,
        'cache'          => 1,
        'weight'         => 2,
    );
    $rr1->submit() or die $rr1->user_error();
    my $total_charges_2_pounds = $rr1->total_charges();
    debug( "Cache test. 2 pounds = $total_charges_2_pounds" ); 
    
    my $rr2 = test(
        %similar,
        'cache'          => 1,
        'weight'         => 12,
    );
    $rr2->submit() or die $rr2->user_error();
    my $total_charges_12_pounds = $rr2->total_charges();
    debug( "Cache test. 12 pounds = $total_charges_12_pounds" );
    ok( $total_charges_2_pounds != $total_charges_12_pounds, 'UPS domestic cache, sequential charges are different' );
    
