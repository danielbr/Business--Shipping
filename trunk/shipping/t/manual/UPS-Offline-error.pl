#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

my $results = $rate_request->submit(
    service        => '2DA',
    weight        => 20,
    from_zip    => '98682',
    to_zip        => '97015',
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";
