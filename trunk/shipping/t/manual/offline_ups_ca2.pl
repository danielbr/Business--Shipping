#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

my $results = $rate_request->submit(
	from_zip	=> '98682',
	from_state	=> 'WA',
	event_handlers => {
		trace 	=> 'STDERR',
		debug 	=> 'STDERR',
		#debug3 	=> undef,
		error	=> 'STDERR',
	},
	
		shipper =>      'Offline::UPS',
        service =>      'XDM',
        to_country =>   'CA',
        weight =>       '0.5',
        to_zip =>       'M1V 2Z9',

) or die $rate_request->error();


print "offline = " . $rate_request->total_charges() . "\n";
