#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rate_request->submit(
		from_state	=> 'Washington',	
		shipper 		=> 'Offline::UPS',
		cache			=> 0,
		event_handlers	=> {
			trace => 'STDERR',
			debug => 'STDERR',
			error => 'STDERR',
		},

	from_state	=> 'Washington',
	from_zip	=> '98682',
	service		=> 'XDM',
	weight		=> 20,
	to_country	=> 'GB',
	to_zip		=> 'RH98AX',
		
) or die $rate_request->error();

print "offline = " . $rate_request->total_charges() . "\n";


