#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

$rate_request->submit(
    from_country =>     'US',
    to_country =>       'US',
    from_state =>       'WA',
    service =>          '2DA',
    to_residential =>   '1',
    from_zip =>         '98682',
    weight =>           '4.25',
    to_zip =>           '96720-1749',
    event_handlers => {
                        debug    => 'STDERR',
                        error    => 'STDERR',
    },
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";
