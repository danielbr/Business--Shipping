#!/usr/bin/perl

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request(
	event_handlers	=> {
			'debug' => 'STDERR',
			'debug3' => undef,
			'trace' => 'STDERR', 
			'error' => 'STDERR',
	},
	
	'from_zip' => "98682",
	'to_country' => "MX",
	'from_state' => "Washington",
	'weight' => "2.25",
	'shipper' => "Offline::UPS",
	'service' => "XPD",
	'to_zip' => "06400",
	'cache' => "1",
	'from_country' => "US",	
	
	
);

not defined $rate_request and die $@;

$rate_request->submit() or die $rate_request->error();

print "\$" . $rate_request->total_charges() . "\n";
