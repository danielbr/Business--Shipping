#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use Business::Shipping;

my $rate_request_online = Business::Shipping->rate_request( shipper => 'Online::UPS' );

$rate_request_online->submit(
    service        => 'UPSSTD',
    weight        => 20,
    from_zip    => '98682',
    to_zip        => 'N2H6S9',
    to_country    => 'Canada',
    event_handlers => {
        debug     => 'STDERR',
        error    => 'STDERR',
    },
) or die $rate_request_online->user_error();

print "online = " .  $rate_request_online->total_charges() . "\n";

