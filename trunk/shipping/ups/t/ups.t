#!/usr/bin/perl

use Business::Ship;
use Business::Ship::UPS;

#my $shipment = new Business::Ship( 'shipper' => 'UPS' );

#print "$@ at $!" if $@;

my $shipment = new Business::Ship::UPS;

#defined $shipment or die "Could not build Business::Ship::UPS object.";

$shipment->set(
	'event_handlers' => (
		{
		#'debug' => 'STDOUT', 
		'trace' => 'STDOUT', 
		'error' => 'STDOUT', 
		}
	)
);

$shipment->set(
	'user_id' 		=> $ENV{UPS_USER_ID},
	'password' 		=> $ENV{UPS_PASSWORD},
	'license'		=> $ENV{ UPS_ACCESS_LICENSE_NUMBER },
	'tx_type' 		=> 'rate', 
	'test_mode'		=> 1,
	'cache_enabled'	=> 0,
);

$shipment->set(
	'pickup_type'	 	=> '06',
	'from_zip'			=> '98682',
	'from_country'		=> 'US',
	'to_country'		=> 'US',
);

$shipment->set(
	'service'		=> 'GNDRES',
	'to_residential'	=> '1',
	'to_zip'		=> '98270',
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
