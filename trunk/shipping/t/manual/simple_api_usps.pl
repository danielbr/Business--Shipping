#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;
use Business::Shipping::Shipment;
use Business::Shipping::Shipment::UPS;
use Business::Shipping::Shipment::USPS;
use Business::Shipping::Package;
use Business::Shipping::Package::UPS;
use Business::Shipping::Package::USPS;
use Business::Shipping::RateRequest;
use Business::Shipping::RateRequest::Online;
use Business::Shipping::RateRequest::Online::UPS;
use Business::Shipping::RateRequest::Online::USPS;
my $rate_request;


###############################################################################
##  Domestic
###############################################################################
#$rate_request = Business::Shipping->rate_request(
#	shipper 		=> 'USPS', 
#	service 		=> 'Priority',
#	
#	user_id 		=> $ENV{ USPS_USER_ID },		
#	password 		=> $ENV{ USPS_PASSWORD },
#
#	from_zip		=> '98682',
#	to_zip			=> '98270',
#	
#	weight			=> '7',
#);
#
#not defined $rate_request and die $@;
#
#$rate_request->submit() or die $rate_request->error();
#
#print "\$" . $rate_request->total_charges() . "\n";

###############################################################################
##  International
###############################################################################
print "\n\n\nTesting International USPS...\n\n";
$rate_request = Business::Shipping->rate_request(
	shipper 		=> 'USPS', 
	service 		=> 'Airmail Parcel Post',
	
	cache			=> 1,
	
	user_id 		=> $ENV{ USPS_USER_ID },		
	password 		=> $ENV{ USPS_PASSWORD },

	from_zip		=> '98682',
	to_country		=> 'Great Britain',
	
	weight			=> '7',
);

not defined $rate_request and die $@;

$rate_request->submit() or die $rate_request->error();

print "\$" . $rate_request->total_charges() . "\n";
