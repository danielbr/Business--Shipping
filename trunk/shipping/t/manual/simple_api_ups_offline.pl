#!/usr/bin/perl

use Business::Shipping;
use Business::Shipping::Shipment;
use Business::Shipping::Shipment::UPS;
use Business::Shipping::Package;
use Business::Shipping::Package::UPS;
use Business::Shipping::RateRequest;
use Business::Shipping::RateRequest::Offline;
use Business::Shipping::RateRequest::Offline::UPS;

my $rate_request = Business::Shipping->rate_request(
	shipper 		=> 'UPS',
	offline			=> 1,
	service 		=> 'UPSSTD',
	
	cache			=> 0,
	
	from_zip		=> '98682',
	to_zip			=> 'H3B3A7',
	to_country		=> 'CA',
	
	weight			=> '7.50',
	
	event_handlers	=> {
			'debug' => 'STDERR',
			'debug3' => 'STDERR',
			'trace' => 'STDERR', 
			'error' => 'STDERR',
	},
	
);

not defined $rate_request and die $@;

$rate_request->submit() or die $rate_request->error();

print "\$" . $rate_request->total_charges() . "\n";
