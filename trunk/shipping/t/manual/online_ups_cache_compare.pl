#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use Business::Shipping;

my $rate_request_online1 = Business::Shipping->rate_request( shipper => 'Online::UPS' );

$rate_request_online1->submit(
	user_id			=> $ENV{ UPS_USER_ID },
	password		=> $ENV{ UPS_PASSWORD },
	access_key		=> $ENV{ UPS_ACCESS_KEY }, 
	cache			=> 0,
	event_handlers 	=> {
		debug 		=> 'STDERR',
		error		=> 'STDERR',
		trace		=> 'STDERR',
		debug3		=> undef,
	},
	
		'cache'				=> 1,
		'pickup_type'	 	=> 'daily pickup',
		'from_zip'			=> '98682',
		'from_country'		=> 'US',
		'to_country'		=> 'US',	
		'service'			=> '1DA',
		'to_residential'	=> '1',
		'to_zip'			=> '98270',
		'weight'			=> '1.0',
		'packaging' 		=> '02',
	
) or die $rate_request_online1->error();

print "UPS online 1 = " .  $rate_request_online1->total_charges() . "\n";

my $rate_request_online2 = Business::Shipping->rate_request( shipper => 'UPS' );

$rate_request_online2->submit(
	user_id			=> $ENV{ UPS_USER_ID },
	password		=> $ENV{ UPS_PASSWORD },
	access_key		=> $ENV{ UPS_ACCESS_KEY }, 
	cache			=> 0,
	event_handlers 	=> {
		debug 		=> 'STDERR',
		error		=> 'STDERR',
	},
	
		'cache'				=> 1,
		'pickup_type'	 	=> 'daily pickup',
		'from_zip'			=> '98682',
		'from_country'		=> 'US',
		'to_country'		=> 'US',	
		'service'			=> '1DA',
		'to_residential'	=> '1',
		'to_zip'			=> '98270',
		'weight'			=> '5',
		'packaging' 		=> '02',
	
) or die $rate_request_online2->error();

print "UPS online 2 = " .  $rate_request_online2->total_charges() . "\n";
