#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rate_request->submit(
    service        => 'XPD',
    weight        => 20,
    from_zip    => '98682',
    from_state    => 'WA',
    to_zip        => 'N2H6S9',
    to_country    => 'Canada',
    event_handlers => {
        trace     => 'STDERR',
        debug     => 'STDERR',
        #debug3     => undef,
        error    => 'STDERR',
    },
) or die $rate_request->error();

print "offline = " . $rate_request->total_charges() . "\n";
