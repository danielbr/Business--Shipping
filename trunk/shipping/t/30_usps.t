use strict;
use warnings;

use Test::More 'no_plan';
use Carp;
use Business::Ship;
use_ok( "Business::Ship::USPS::Package" );

my $standard_method = new Business::Ship( 'shipper' => 'USPS' );
ok( defined $standard_method,	'USPS standard object construction' );

my $other_method = new Business::Ship::USPS;
ok( defined $other_method,		'USPS alternate object construction' );

my $package = new Business::Ship::USPS::Package;
ok( defined $package,			'USPS package object construction' );

sub test
{
	my ( %args ) = @_;
	my $shipment = new Business::Ship( 
		'shipper' => 'USPS',
		'user_id'		=> $ENV{ USPS_USER_ID },
		'password'		=> $ENV{ USPS_PASSWORD },
		'cache_enabled'	=> 0,
	);
	$shipment->submit( %args ) or die $shipment->error();
	return $shipment;
}

# skip the rest of the test if we don't have username/password
SKIP: {
	skip( 'USPS: we need the username and password', 2 ) 
		unless ( $ENV{ USPS_USER_ID } and $ENV{ USPS_PASSWORD } );
	
	my $shipment;
	$shipment = test(
		'test_mode'	=> 1,
		'service'	=> 'EXPRESS',
		'from_zip'	=> '20770',
		'to_zip'	=> '20852',
		'weight'	=> 10,
	);
	ok( $shipment->total_charges(), 	'USPS domestic test total_charges > 0' );
	
	$shipment = test(
		'test_mode'		=>	1,
		'pounds'		=>	0,
		'ounces'		=>	1,
		'mail_type'		=>	'Postcards or Aerogrammes',
		'to_country'	=>	'Algeria',
	);
	ok( $shipment->total_charges(), 	'USPS intl test total_charges > 0' );
		
	$shipment = test(
		'test_mode'		=> 0,
		'from_zip' 		=> '98682',
		'to_country' 	=> 'United States',
		'service' 		=> 'Priority',
		'to_zip'		=> '96826',
		'from_country' 	=> 'US',
		'pounds'		=> '2',
	); 
	ok( $shipment->total_charges(),		'USPS domestic production total_charges > 0' );
	
	
	if ( 0 ) {
		# These are just more domestic production tests for "Priority Mail"
		$shipment = test(
			'from_zip'              => '98682',
			weight          => 0.2,
			to_zip          => '98270',
			service         => 'Priority',
		);
		
		print test_domestic(
				weight          => 3.5,
				to_zip          => '99501',
				service         => 'Priority',
		);
		
		print test_domestic(
				'to_zip' => '96826',
				'weight' => '2',
				'service' => 'Priority',
		);
	}
	
	$shipment = test(
		'test_mode'		=> 0,
		'service' 		=> 'Airmail Parcel Post',
		'weight'		=> 1,
		'ounces'		=> 0,
		'mail_type'		=> 'Package',
		'to_country'	=> 'Great Britain',
		
	); 
	ok( $shipment->total_charges(),		'USPS intl production total_charges > 0' );
	
	
	
	
	
	
	

} # /skip
