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
		error		=> 'croak',
		trace		=> undef,
		debug3		=> undef,
	},
	
		'pickup_type'	 	=> 'daily pickup',
		'from_zip'			=> '98682',
		'from_country'		=> 'USA',
		'to_country'		=> 'GB',	
		'service'			=> 'XPR',
		'to_residential'	=> '1',
		'to_city'			=> 'Godstone',
		'to_zip'			=> 'RH98AX',
		'weight'			=> '3.45',
		'packaging' 		=> '02',
	
) or die $rate_request_online1->error();

print "UPS online 1 = " .  $rate_request_online1->total_charges() . "\n";



		

