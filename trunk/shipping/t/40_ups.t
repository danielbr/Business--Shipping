use strict;
use warnings;

use Test::More 'no_plan';
use Carp;
use Business::Shipping;


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
			#trace => 'STDERR', 
		}
	);
	$shipment->submit( %args ) or die $shipment->error();
	return $shipment;
}

sub simple_test
{
	my ( %args ) = @_;
	my $shipment = test( %args );
	$shipment->submit() or die $shipment->error();
	my $total_charges = $shipment->total_charges(); 
	my $msg = 
			"UPS Simple Test: " 
		.	( $args{ weight } ? $args{ weight } . " pounds" : ( $args{ pounds } . "lbs and " . $args{ ounces } . "ounces" ) )
		.	" to " . ( $args{ to_city } ? $args{ to_city } . " " : '' )
		.	$args{ to_zip } . " via " . $args{ service }
		.	" = " . ( $total_charges ? '$' . $total_charges : "undef" );
	ok( $total_charges,	$msg );
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
		'to_city'			=> 'Godstone',
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
	
	
	###########################################################################
	##  UPS One Day Air -- Specific cases
	###########################################################################
	my %std_opts = (
		'pickup_type'	 	=> 'daily pickup',
		'from_zip'			=> '98682',
		'to_residential'	=> '1',
		'packaging' 		=> '02',
	);
	
	simple_test(
		%std_opts,
		service				=> '1DA',
		#'to_city'			=> 'Atlantic',
		'to_zip'			=> '50022',
		'weight'			=> '5.00',
		'packaging' 		=> '02',
	);
	
	simple_test(
		%std_opts,
		'service'			=> '1DA',
		#'to_city'			=> 'Allison Park',
		'to_zip'			=> '15101',
		'weight'			=> '15.00',
	);
	
	simple_test(
		%std_opts,
		'service'			=> '1DA',
		#'to_city'			=> 'Costa Mesa',
		'to_zip'			=> '92626',
		'weight'			=> '15.00',
	);
	
	
	###########################################################################
	##  Perth, Western Australia
	###########################################################################
	simple_test(
		%std_opts,
		service			=> 'XPD', 
		to_country		=> 'AU',
		to_city			=> 'Bicton',
		to_zip			=> '6157',
		weight			=> 5.5,
	);
	
	#
	# XDM not allowed to australia?
	#
	#simple_test(
	#	%std_opts,
	#	service			=> 'XDM',
	#	to_country		=> 'AU',
	#	to_city			=> 'Bicton',
	#	to_zip			=> '6157',
	#	weight			=> 5.5,
	#);
	
	simple_test(
		%std_opts,
		service			=> 'XPR',
		to_country		=> 'AU',
		to_city			=> 'Bicton',
		to_zip			=> '6157',
		weight			=> 5.5,
	);
	
	###########################################################################
	##  Standard to Canada
	###########################################################################
	simple_test(
		%std_opts,
		service			=> 'UPSSTD', 
		to_country		=> 'CA',
		to_city			=> 'Kitchener',
		to_zip			=> 'N2H6S9',
		weight			=> 5.5,
	);
	
	simple_test(
		%std_opts,
		service			=> 'UPSSTD', 
		to_country		=> 'CA',
		to_city			=> 'Richmond',
		to_zip			=> 'V6X3E1',
		weight			=> 0.5,
	);
	
	
}

1;
