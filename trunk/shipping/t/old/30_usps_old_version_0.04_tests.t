#!/usr/bin/perl

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

my $standard_method = new Business::Shipping( 'shipper' => 'USPS' );
ok( defined $standard_method,	'USPS standard object construction' );

my $other_method = new Business::Shipping::USPS;
ok( defined $other_method,		'USPS alternate object construction' );

my $package = new Business::Shipping::USPS::Package;
ok( defined $package,			'USPS package object construction' );

sub test
{
	my ( %args ) = @_;
	my $shipment = new Business::Shipping( 
		'shipper' => 'USPS',
		'user_id'		=> $ENV{ USPS_USER_ID },
		'password'		=> $ENV{ USPS_PASSWORD },
		'cache_enabled'	=> 0,
		#'event_handlers' => ({ 'debug' => 'STDOUT', }),
	);
	$shipment->submit( %args ) or die $shipment->error();
	return $shipment;
}

# skip the rest of the test if we don't have username/password
SKIP: {
	skip( 'USPS: we need the username and password', 5 ) 
		unless ( $ENV{ USPS_USER_ID } and $ENV{ USPS_PASSWORD } );
	
	my $shipment;
	$shipment = test(
		'test_mode'	=> 1,
		'service'	=> 'EXPRESS',
		'from_zip'	=> '20770',
		'to_zip'	=> '20852',
		'pounds'	=> 10,
		'ounces'	=> 0,
		'container'	=> 'None',
		'size'		=> 'REGULAR',
		'machinable'	=> '',
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
	
	# Cache Test
	# - Multiple sequential queries should give *different* results.
	$shipment = test(
		'cache_enabled'	=> 1,
		'test_mode'		=> 0,
		'service' 		=> 'Airmail Parcel Post',
		'weight'		=> 1,
		'ounces'		=> 0,
		'mail_type'		=> 'Package',
		'to_country'	=> 'Great Britain',
	);
	
	my $total_charges_1_pound = $shipment->total_charges();
	
	$shipment = test(
		'cache_enabled'	=> 1,
		'test_mode'		=> 0,
		'service' 		=> 'Airmail Parcel Post',
		'weight'		=> 5,
		'ounces'		=> 0,
		'mail_type'		=> 'Package',
		'to_country'	=> 'Great Britain',
	);
	
	my $total_charges_5_pounds = $shipment->total_charges();
	
	ok( $total_charges_1_pound != $total_charges_5_pounds,	'USPS intl cache saves results separately' ); 

	
	###########################################################################
	##  Zip Code Testing
	###########################################################################
	# Vancouver, Vermont, Alaska, Hawaii
	my @several_very_different_zip_codes = ( '98682', '22182', '99501', '96826' );
	my %charges;
	foreach my $zip ( @several_very_different_zip_codes ) {
		$shipment = test(
			'cache_enabled'	=> 1,
			'test_mode'		=> 0,
			'service' 		=> 'Priority',
			'weight'		=> 5,
			'to_zip'		=> $zip,
			'from_zip'		=> 98682
		);
		$charges{ $zip } = $shipment->total_charges();
	}
	
	# Somehow make sure that all the values in %charges are unique.
	my $found_duplicate;
	foreach my $zip ( keys %charges ) {
		foreach my $zip2 ( keys %charges ) {
			
			# Skip this zip code, only testing the others.
			next if $zip2 eq $zip;
			
			if ( $charges{ $zip } == $charges{ $zip2 } ) {
				$found_duplicate = $zip;
			}
		}
	}
	
	ok( ! $found_duplicate, 'USPS different zip codes give different prices' );
	
		
		
		
		
	
	
	

} # /skip
