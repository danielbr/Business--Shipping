#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rate_request->submit(
        from_country =>                 'US',
        to_country =>           'US',
        from_state =>           'OR',
        service =>              'UPSSTD',
        to_residential =>               '1',
        weight =>               '0.6875',
        from_zip =>             '97214',
        to_zip =>               '92648',
        shipper =>              'Offline::UPS',
        cache =>                '1',

    event_handlers => {
        debug     => 'STDERR',
        error    => 'STDERR',
    },
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";
