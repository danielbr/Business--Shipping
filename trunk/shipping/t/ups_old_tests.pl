#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping::UPS;
use Carp ();

print "\nTesting UPSTools Module...\n\n";

my $ups = new Business::Shipping::UPS;

# If you are not using any of the STDERR or Carp error methods,
# You may use this calling structure to get at error messages:
# $ups->method_name() or print $ups->error();


$ups->set(
	#test_server => 1,
	#event_handler_debug => 'STDOUT',
	#ssl => 1,
);
$ups->set(
	access_license_number => ${ENV{UPS_LICENSE_NUMBER}},
	user_id => ${ENV{UPS_USER_ID}},
	password => ${ENV{UPS_PASSWORD}},
	shipper_country_code => 'US',
	shipper_postal_code => '98682',
	pickup_type_code => '06',
	ship_to_residential_address => '1',
	weight => '3.4',
	packaging_type_code =>  '02',
) or print $ups->error();

$ups->set(
	ship_to_residential_address => '1',
	ship_to_country_code => 'US',
	ship_to_postal_code => '98270',
	service_code => '01',
	packaging_type_code =>  '02',
) or print $ups->error();

=pod
print "UPS XDM 98682 to UK";
$ups->set(
	ship_to_country_code => 'UK',
	ship_to_postal_code => 'RH98AX',
	service_code => '54',
);
( $amount, $error ) = $ups->get_rate();
print "amount = $amount, error = $error\n\n";

=cut

$ups->run_query(
	ship_to_country_code => 'GB',
	ship_to_city => 'Godstone',
	ship_to_postal_code => 'RH98AX',
	service_code => '54',
);

my $rate = $ups->get_total_charges();
print "rate = $rate\n\n";


1;
#!/usr/bin/perl

use Business::Shipping;
use Business::Shipping::UPS;

#my $shipment = new Business::Shipping( 'shipper' => 'UPS' );

#print "$@ at $!" if $@;

my $shipment = new Business::Shipping::UPS;

#defined $shipment or die "Could not build Business::Shipping::UPS object.";

$shipment->set(
	'event_handlers' => (
		{
		'debug' => 'STDOUT', 
		'trace' => 'STDOUT', 
		'error' => 'STDOUT', 
		}
	)
);

$shipment->set(
	'user_id' 		=> $ENV{UPS_USER_ID},
	'password' 		=> $ENV{UPS_PASSWORD},
	'access_key'		=> $ENV{ UPS_ACCESS_KEY },
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
