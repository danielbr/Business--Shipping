#!/usr/bin/perl

use strict;
use warnings;

use Business::Ship;
use Carp;

sub test
{
	my ( %args ) = @_;
	my $shipment = new Business::Ship( 
		'shipper' => 'USPS',
		'user_id'		=> $ENV{ USPS_USER_ID },
		'password'		=> $ENV{ USPS_PASSWORD },
		'cache_enabled'	=> 0,
		'event_handlers' => ({ 
			'debug' => 'STDOUT', 
			'trace' => 'STDOUT', 
			'error' => 'STDOUT', 
		}),
	);
	die $@ if $@;
	$shipment->submit( %args ) or die $shipment->error();
	return $shipment;
}

	my $shipment;
	
=pod
	#
	# Several domestic tests on the "Test" server.
	#
	$shipment = test(
		'test_mode'	=> 1,
		'service'	=> 'EXPRESS',
		'from_zip'	=> '20770',
		'to_zip'	=> '20852',
		'weight'	=> 10,
	);
=cut
	
	#
	# Several International tests on the "Test" server.
	#
	$shipment = test(
		'test_mode'		=>	1,
		'pounds'		=>	'0',
		'ounces'		=>	1,
		'mail_type'		=>	'Postcards or Aerogrammes',
		'to_country'	=>	'Algeria',
	);
	print $shipment->total_charges();
