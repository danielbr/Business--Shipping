#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rate_request->submit(
    service        => 'XPD',
    weight        => 20,
    to_country    => 'GB',
    from_zip    => '98682',
    from_state    => 'Washington',
    to_zip        => 'RH98AX',
    event_handlers => {
        debug     => 'STDERR',
        error    => 'STDERR',
    },
    #unzip        => 1,
    #convert        => 1,
    
) or die $rate_request->error();

print "offline = " . $rate_request->total_charges() . "\n";


my $rate_request_online = Business::Shipping->rate_request( shipper => 'Online::UPS' );

$rate_request_online->submit(
    service        => 'XPD',
    weight        => 20,
    to_country    => 'GB',
    from_zip    => '98682',
    to_zip        => 'RH98AX',
    event_handlers => {
        debug     => 'STDERR',
        error    => 'STDERR',
    },
) or die $rate_request_online->error();

print "online = " .  $rate_request_online->total_charges() . "\n";

