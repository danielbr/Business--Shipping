#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rate_request->submit(
        from_country => 'US',
        from_state   => 'WA',
        from_city    => 'Vancouver',
        from_zip     => '98682',
        
        to_country   => 'FX',
        to_zip       => '69100',
        
        service =>              'XPD',
        weight =>               '1.5',
        
        
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";


