#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

$rate_request->submit(
    'weight' => "3.5",'from_country' => "US",'to_country' => "Russia",'shipper' =>
    "UPS_Offline",'to_zip' => "21037",'cache' => "1",'from_zip' => "98682",'from_state' => "WA",'service'
    => "XPR",
    event_handlers => {
        debug     => 'STDERR',
        error    => 'STDERR',
        trace    => 'STDERR',
    },
    #unzip        => 1,
    #convert        => 1,
    
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";



