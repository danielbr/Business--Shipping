#!/usr/bin/perl

print "Testing USPS Priority Mail...\n\n";

$shipment->set( 
	'user_id' 		=> $ENV{USPS_USER_ID},
	'password' 		=> $ENV{USPS_PASSWORD},
	'tx_type' 		=> 'rate', 
	'test_mode'		=> 0,
	'from_zip'		=> '98682',
);

print test_domestic(
	weight		=> 0.2,
	to_zip		=> '98270',
	service		=> 'Priority',
);

print test_domestic(
	weight		=> 3.5,
	to_zip		=> '99501',
	service		=> 'Priority',
);

#$shipment->set( 'event_handlers' => ({ 'debug' => 'STDOUT' }) );

print test_domestic(
	'to_zip' => '96826',
	'weight' => '2',
	'service' => 'Priority',
);

print "\n";

1;
