#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rate_request->submit(
	from_zip	=> '98682',
	from_state	=> 'WA',
	event_handlers => {
		debug 	=> 'STDERR',
		error	=> 'STDERR',
		trace	=> 'STDERR',
		debug3	=> 'STDERR',
	},

        shipper =>      'Offline::UPS',
        service =>      'XPR',
        to_country =>   'ZA',
        weight =>       '2.5',
        to_zip =>       '7700',

		
) or die $rate_request->error();

print "offline = " . $rate_request->total_charges() . "\n";


