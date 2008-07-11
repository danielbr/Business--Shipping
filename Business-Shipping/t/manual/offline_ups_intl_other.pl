#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

$rate_request->submit(
        from_country => 'US',
        from_state   => 'WA',
        from_city    => 'Vancouver',
        from_zip     => '98682',

        to_country   => 'XS',
        #to_city      => 'Abu Dhabi',
        to_zip =>               '564',

        service      => 'XDM',
        weight       => '2',
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";


