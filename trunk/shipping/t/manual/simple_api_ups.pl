#!/usr/bin/perl




# Slightly less-simple API
#use Business::Shipping::RateRequest::Online::UPS;
#my $ups_online_rate_request = Business::Shipping::RateRequest::Online::UPS->new();
#
#$ups_online_rate_request->init(
#	shipper 		=> 'UPS', 
#	user_id 		=> $ENV{ UPS_USER_ID },		
#	password 		=> $ENV{ UPS_PASSWORD },
#	access_key 		=> $ENV{ UPS_ACCESS_KEY },		# UPS only
#	from_zip		=> '98682',
#	to_zip			=> '98270',
#); 
#
#$rate_request->submit() or die $rate_request->error();
#
#print "charges = " . $rate_request->get_total_charges() . "\n";
#


use Business::Shipping;
use Business::Shipping::Shipment;
use Business::Shipping::Shipment::UPS;
use Business::Shipping::Package;
use Business::Shipping::Package::UPS;
use Business::Shipping::RateRequest;
use Business::Shipping::RateRequest::Online;
use Business::Shipping::RateRequest::Online::UPS;

my $rate_request = Business::Shipping->rate_request(
	shipper 		=> 'UPS', 
	event_handlers	=> {
			'debug' => undef,
			'debug3' => undef,
			'trace' => undef, 
			'error' => 'STDERR',
	},
	cache			=> 0,
	user_id 		=> $ENV{ UPS_USER_ID },		
	password 		=> $ENV{ UPS_PASSWORD },
	access_key 		=> $ENV{ UPS_ACCESS_KEY },		# UPS only
		
		service			=> 'UPSSTD', 
		to_country		=> 'CA',
		to_city			=> 'Richmond',
		to_zip			=> 'V6X3E1',
		weight			=> 0.5,
	
	
);

not defined $rate_request and die $@;

$rate_request->submit() or die $rate_request->error();

print "\$" . $rate_request->total_charges() . "\n";
