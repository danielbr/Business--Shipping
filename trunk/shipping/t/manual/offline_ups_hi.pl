#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rate_request->submit(
    service        => '1DA',
    weight        => 20,
    from_zip    => '98682',
    from_state    => 'Washington',
    to_zip        => '96826',
    event_handlers => {
        debug     => 'STDERR',
        error    => 'STDERR',
    },
    #download    => 1,
    #unzip        => 1,
    #convert        => 1,
    
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";


my $rate_request_online = Business::Shipping->rate_request( shipper => 'Online::UPS' );

$rate_request_online->submit(
    service        => '1DA',
    weight        => 20,
    from_zip    => '98682',
    to_zip        => '96826',
    event_handlers => {
        debug     => 'STDERR',
        error    => 'STDERR',
    },
) or die $rate_request_online->user_error();

print "online = " .  $rate_request_online->total_charges() . "\n";

