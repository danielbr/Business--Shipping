#!/usr/bin/perl

use strict;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request(
	event_handlers => {
		trace 	=> 'STDERR',
		debug 	=> 'STDERR',
		error	=> 'STDERR',
	},
	from_zip	=> '98682',
	from_state	=> 'WA',
	
        shipper =>      'Offline::UPS',
        service =>      'XDM',
        to_country =>   'NO',
        weight =>       '5.9',
        to_zip =>       'N-7025',

);

$rate_request->submit() or die $rate_request->error();


print "offline = " . $rate_request->total_charges() . "\n";
