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
        service =>      'XDM',
        to_country =>   'MY',
        weight =>       '7',
        to_zip =>       '98000',
		
) or die $rate_request->error();

print "offline = " . $rate_request->total_charges() . "\n";


