#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rate_request->submit(
        shipper =>      'Offline::UPS',
        service =>      'XPD',
        to_country =>   'CY',
        weight =>       '2',
        to_zip =>       '2024',
        from_country =>                 'US',
        from_state =>           'OR',
        from_zip =>             '97214',
        to_zip =>               '71270',
        event_handlers => {
            #debug => 'STDERR',
            error => 'STDERR',
        }
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";
