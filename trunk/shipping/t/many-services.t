#!/usr/bin/perl

use Business::Ship;

my $shipment = new Business::Ship( 'shipper' => 'UPS' );
print "$@ at $!" if $@;

$shipment->set(
	'event_handlers' => (
		{
		#'debug' => 'STDOUT', 
		#'trace' => 'STDOUT', 
		#'error' => 'STDOUT', 
		}
	)
);

$shipment->set(
	'user_id' 		=> $ENV{UPS_USER_ID},
	'password' 		=> $ENV{UPS_PASSWORD},
	'access_key'	=> $ENV{ UPS_ACCESS_KEY },
	'tx_type' 		=> 'rate', 
	'test_mode'		=> 1,
	'cache_enabled'	=> 0,
);

$shipment->set(
	'pickup_type'	 	=> 'daily pickup',
	'from_zip'			=> '98682',
	'from_country'		=> 'US',
	'to_country'		=> 'US',
);

$shipment->set(
	'service'			=> '1DA',
	'to_residential'	=> '1',
	'to_zip'			=> '98270',
);

$shipment->add_package(
	'weight'		=> '3.45',
	'packaging' 	=>  '02',
);

$shipment->add_package(
	'weight'		=> '6.9',
	'packaging' 	=>  '02',
);


=pod
$shipment->submit(
	'to_zip'		=> '98270',
	'service'		=> 'GNDRES',
	'weight'		=> '3.45',
	'to_residential'	=> '1',
	'weight' 		=> '3.4',
	'packaging' 	=>  '02',	
) or die $shipment->error();
=cut

$shipment->submit() or die $shipment->error();

print $shipment->total_charges() . "\n";
