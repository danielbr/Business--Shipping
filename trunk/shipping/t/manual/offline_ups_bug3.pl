#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

$rate_request->submit(
        from_country =>                 'US',
        to_country =>           'US',
        from_state =>           'OR',
        service =>              'UPSSTD',
        to_residential =>               '1',
        from_zip =>             '97214',
        weight =>               '8',
        to_zip =>               '71270',
        cache =>                '1',
        shipper =>              'UPS_Offline',
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";
