#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

$rate_request->submit(
    shipper    => 'UPS_Offline',    
    from_state => 'Washington',    
    cache      => 0,
    from_state => 'Washington',
    from_zip   => '98682',
    service    => 'XDM',
    weight     => 20,
    to_country => 'UK',
    to_zip     => 'RH98AX',
        
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";


