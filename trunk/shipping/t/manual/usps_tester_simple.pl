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
	event_handlers	=> { trace => 'STDERR', debug => 'STDERR', debug3 => 'STDERR' },
	user_id 		=> $ENV{ USPS_USER_ID },		
	password 		=> $ENV{ USPS_PASSWORD },
	
	shipper 		=> 'USPS', 
	service 		=> 'Airmail Parcel Post',
	from_zip		=> 98682,
	#pounds			=> 0,
	#ounces			=> 1,
	weight			=> 1,
	mail_type		=> 'Postcards or Aerogrammes',
	to_country		=> 'Algeria',
);

not defined $rate_request and die $@;

$rate_request->submit() or die $rate_request->error();

my $total_charges = $rate_request->total_charges();

if ( $total_charges ) {
	print "\$$total_charges\n";
}
else {
	print "Error -- charges were \$0.00.\n";
}
	
