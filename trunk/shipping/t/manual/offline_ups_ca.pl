#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

my $enable_online = 0;
my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

$rate_request->submit(
    service        => 'UPSSTD',
    weight         => 20,
    from_zip       => '98682',
    from_state     => 'WA',
    to_zip         => 'N2H6S9',
    to_country     => 'Canada',
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";

exit unless $enable_online;

my $rate_request_online = Business::Shipping->rate_request( shipper => 'UPS_Online' );

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

