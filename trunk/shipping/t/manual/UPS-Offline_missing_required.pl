#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

#Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );                              

my %req = (
'from_country' => "US",'from_state' => "WA",'to_country' => "US",'service' => "GNDRES",'tier' => "3",
'weight' => "10",'from_zip' => "98682",'cache' => "1",
);

$rate_request->submit( %req ) or die $rate_request->user_error();

#use Data::Dumper;
#print Dumper( $rate_request );

print "offline = " . $rate_request->total_charges() . "\n";




