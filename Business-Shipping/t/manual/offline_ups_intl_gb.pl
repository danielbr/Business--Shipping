#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

$rate_request->submit(
        from_country => 'US',
        from_state   => 'WA',
        from_city    => 'Vancouver',
        from_zip     => '98682',
        
        to_country   => 'UK',
        to_city      => 'Gladstone', 
        to_zip       => 'S11 9BU',
        
        service =>              'XDM',
        weight =>               '55',
        
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";


