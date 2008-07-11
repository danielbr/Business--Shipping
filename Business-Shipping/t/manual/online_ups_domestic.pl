#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use Business::Shipping;

my $rate_request_online = Business::Shipping->rate_request( shipper => 'UPS' );

$rate_request_online->submit(
    user_id            => $ENV{ UPS_USER_ID },
    password        => $ENV{ UPS_PASSWORD },
    access_key        => $ENV{ UPS_ACCESS_KEY }, 
    cache            => 0,
    event_handlers     => {
        debug         => 'STDERR',
        error        => 'STDERR',
    },
    service            => '1DA',
    weight            => 3.45,
    from_zip        => '98682',
    to_zip            => '98270',
    to_country        => 'US',
    from_country     => 'US',
    to_residential     => 1,
    packaging        => '02',
) or die $rate_request_online->user_error();

print "UPS online domestic = " .  $rate_request_online->total_charges() . "\n";

