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
print test_domestic(
	'to_zip' => '96826',
	'weight' => '2',
	'service' => 'Priority',
);
print test_domestic(
	'to_zip' => '96826',
	'weight' => '2',
	'service' => 'Priority',
);
print test_domestic(
	'to_zip' => '96826',
	'weight' => '2',
	'service' => 'Priority',
);

#$shipment->set( 'event_handlers' => ({ 'debug' => 'STDOUT' }) );

print test_domestic(
	'to_zip' => '96826',
	'weight' => '2',
	'service' => 'Priority',
);


print test_domestic(
	'to_country' => 'United States',
	'to_zip' => '96826',
	'weight' => '2',
	'service' => 'Priority',
);

=pod
print test_domestic(
	'to_country' => 'United States',
	'service' => 'Priority',
	'to_zip' => '96826',
	'pounds' => '6.348',
	'tx_type' => 'rate',
);


print test_domestic(
	'user_id' => '539KAVOD6731',
	'to_country' => 'United States',
	'service' => 'Priority',
	'to_zip' => '96826',
	'password' => '900QZ55LW201',
	'pounds' => '2',
	'tx_type' => 'rate',
	'from_zip' => '98682',
);

=cut

print "\n";

1;
