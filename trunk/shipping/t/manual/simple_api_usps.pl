#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

print "\n\n\nTesting International USPS...\n\n";

%Business::Shipping::Debug::event_handlers =  (
    trace  => 'STDERR',
    debug  => 'STDERR',
    error  => 'STDERR',
);

my $rate_request = Business::Shipping->rate_request(
    user_id      => $ENV{ USPS_USER_ID },        
    password     => $ENV{ USPS_PASSWORD },
    shipper      => 'USPS', 
    cache        => 0,
        'cache'    => 1,
        'test_mode'        => 0,
        'service'         => 'Airmail Parcel Post',
        'weight'        => 1,
        'ounces'        => 0,
        'mail_type'        => 'Package',
        'to_country'    => 'Great Britain',
);

print STDERR "ounces = " . $rate_request->ounces;

not defined $rate_request and die " rate_request not defined: $@";

$rate_request->submit() or die $rate_request->user_error();

STDERR->print( "\$" . $rate_request->total_charges() . "\n" );



