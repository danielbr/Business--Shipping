#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rate_request->submit(
	'to_country' => "FR",'service' => "XPD",'from_country' => "US",'from_state' =>
"Washington",'to_zip' => "38000",'weight' => "2.25",'shipper' => "Offline::UPS",'cache' =>
"1",'from_zip' => "98682",
	event_handlers => {
		debug 	=> 'STDERR',
		error	=> 'STDERR',
		trace	=> 'STDERR',
	},
) or die $rate_request->error();

print "offline = " . $rate_request->total_charges() . "\n";


