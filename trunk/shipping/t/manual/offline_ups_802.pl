#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rate_request->submit(
        from_country =>         'US',
        to_country =>           'CA',
        from_state =>           'OR',
        service =>              'XPR',
        to_residential =>       '1',
        from_zip =>             '97214',
        weight =>               '1',
        to_zip =>               '80210',
        cache =>                '1',
        shipper =>              'Offline::UPS',
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";
