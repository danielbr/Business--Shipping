#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $enable_online = 0;
my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rate_request->submit(
	service		=> 'UPSSTD',
	weight		=> 20,
	from_zip	=> '98682',
	from_state	=> 'WA',
	to_zip		=> 'N2H6S9',
	to_country	=> 'Canada',
	event_handlers => {
		trace 	=> 'STDERR',
		debug 	=> 'STDERR',
		#debug3 	=> undef,
		error	=> 'STDERR',
	},
	#download	=> 1,
	#unzip		=> 1,
	#convert		=> 1,
) or die $rate_request->error();

print "offline = " . $rate_request->total_charges() . "\n";

exit unless $enable_online;

my $rate_request_online = Business::Shipping->rate_request( shipper => 'Online::UPS' );

$rate_request_online->submit(
	service		=> 'UPSSTD',
	weight		=> 20,
	from_zip	=> '98682',
	to_zip		=> 'N2H6S9',
	to_country	=> 'Canada',
	event_handlers => {
		debug 	=> 'STDERR',
		error	=> 'STDERR',
	},
) or die $rate_request_online->error();

print "online = " .  $rate_request_online->total_charges() . "\n";

