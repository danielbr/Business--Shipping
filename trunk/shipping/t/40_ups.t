use strict;
use warnings;

use Test::More 'no_plan';
use Carp;
use Business::Shipping;
use Business::Shipping::Shipment;
use Business::Shipping::Shipment::UPS;
use Business::Shipping::Shipment::USPS;
use Business::Shipping::Package;
use Business::Shipping::Package::UPS;
use Business::Shipping::Package::USPS;
use Business::Shipping::RateRequest;
use Business::Shipping::RateRequest::Online;
use Business::Shipping::RateRequest::Online::UPS;
use Business::Shipping::RateRequest::Online::USPS;

my $standard_method = new Business::Shipping->rate_request( 'shipper' => 'UPS' );
ok( defined $standard_method,	'UPS standard object construction' );

my $other_method = new Business::Shipping::RateRequest::Online::UPS;
ok( defined $other_method,		'UPS alternate object construction' );

my $package_one = new Business::Shipping::Package::UPS;
ok( defined $package_one,			'UPS package object construction' );

sub test
{
	my ( %args ) = @_;
	my $shipment = Business::Shipping->rate_request( 
		'shipper' => 'UPS',
		'user_id'		=> $ENV{ UPS_USER_ID },
		'password'		=> $ENV{ UPS_PASSWORD },
		'access_key'	=> $ENV{ UPS_ACCESS_KEY }, 
		'cache'	=> 0,
		event_handlers => {
			#trace => 'STDERR' 
		}
	);
	$shipment->submit( %args ) or die $shipment->error();
	return $shipment;
}

# skip the rest of the test if we don't have username/password
SKIP: {
	skip( 'UPS: we need the username, password, and access license key', 2 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	my $shipment;
	
	###########################################################################
	##  Domestic Single-package API
	###########################################################################

	$shipment = test(
		'pickup_type'	 	=> 'daily pickup',
		'from_zip'			=> '98682',
		'from_country'		=> 'US',
		'to_country'		=> 'US',	
		'service'			=> '1DA',
		'to_residential'	=> '1',
		'to_zip'			=> '98270',
		'weight'			=> '3.45',
		'packaging' 		=> '02',
	);
	$shipment->submit() or die $shipment->error();
	ok( $shipment->total_charges(),		'UPS domestic single-package API total_charges > 0' );
	
	###########################################################################
	##  Domestic Multi-package API
	##  TODO: Re-enable.  Currently disabled.
	###########################################################################

#	$shipment = test(
#		'pickup_type'	 	=> 'daily pickup',
#		'from_zip'			=> '98682',
#		'from_country'		=> 'US',
#		'to_country'		=> 'US',	
#		'service'			=> '1DA',
#		'to_residential'	=> '1',
#		'to_zip'			=> '98270',
#	);
#	
#	$shipment->add_package(
#		'weight'		=> '3.45',
#		'packaging' 	=>  '02',
#	);
#	
#	$shipment->add_package(
#		'weight'		=> '6.9',
#		'packaging' 	=>  '02',
#	);
#	$shipment->submit() or die $shipment->error();
#	ok( $shipment->total_charges(),	'UPS domestic multi-package API total_charges > 0' );
	
	
	###########################################################################
	##  International Single-package API
	###########################################################################

	$shipment = test(
		'pickup_type'	 	=> 'daily pickup',
		'from_zip'			=> '98682',
		'from_country'		=> 'US',
		'to_country'		=> 'GB',	
		'service'			=> 'XDM',
		'to_residential'	=> '1',
		#'to_city'			=> 'Godstone',
		'to_zip'			=> 'RH98AX',
		'weight'			=> '3.45',
		'packaging' 		=> '02',
	);
	$shipment->submit() or die $shipment->error();
	ok( $shipment->total_charges(),		'UPS intl single-package API total_charges > 0' );
	
	###########################################################################
	##  International Multi-package API
	###########################################################################
#	$shipment = test(
#		'pickup_type'	 	=> 'daily pickup',
#		'from_zip'			=> '98682',
#		'from_country'		=> 'US',
#		'to_country'		=> 'GB',	
#		'service'			=> 'XDM',
#		'to_residential'	=> '1',
#		'to_city'			=> 'Godstone',
#		'to_zip'			=> 'RH98AX',
#	);
#	
#	$shipment->add_package(
#		'weight'			=> '3.45',
#		'packaging' 		=> '02',
#	);
#	
#	$shipment->add_package(
#		'weight'		=> '6.9',
#		'packaging' 	=>  '02',
#	);
#	$shipment->submit() or die $shipment->error();
#	ok( $shipment->total_charges(),	'UPS intl multi-package API total_charges > 0' );
	
	
	###########################################################################
	##  Cache Test
	##  Multiple sequential queries should give *different* results.
	###########################################################################
	$shipment = test(
		'cache'		=> 1,
		'pickup_type'	 	=> 'daily pickup',
		'from_zip'			=> '98682',
		'from_country'		=> 'US',
		'to_country'		=> 'US',	
		'service'			=> '1DA',
		'to_residential'	=> '1',
		'to_zip'			=> '98270',
		'weight'			=> '1.0',
		'packaging' 		=> '02',
	);
	$shipment->submit() or die $shipment->error();
	my $total_charges_1_pound = $shipment->total_charges();
	
	$shipment = test(
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
	);
	$shipment->submit() or die $shipment->error();
	my $total_charges_5_pounds = $shipment->total_charges();
	ok( $total_charges_1_pound != $total_charges_5_pounds, 'UPS intl cache, sequential charges are different' );
	
	
	###########################################################################
	##  World Wide Expedited
	###########################################################################
	$shipment = test(
		'pickup_type'	 	=> 'daily pickup',
		'from_zip'			=> '98682',
		'from_country'		=> 'US',
		'to_country'		=> 'GB',	
		'service'			=> 'XPD',
		'to_residential'	=> '1',
		#'to_city'			=> 'Godstone',
		'to_zip'			=> 'RH98AX',
		'weight'			=> '3.45',
		'packaging' 		=> '02',
	);
	$shipment->submit() or die $shipment->error();
	ok( $shipment->total_charges(),		'UPS World Wide Expedited > 0' );
	
	
}