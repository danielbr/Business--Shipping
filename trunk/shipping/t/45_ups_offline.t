#! perl
use strict;
use warnings;

use Test::More 'no_plan';
use Carp;
use Business::Shipping;

sub test
{
	my ( %args ) = @_;
	my $shipment = Business::Shipping->rate_request( 
		shipper 		=> 'Offline::UPS',
		cache			=> 0,
		event_handlers	=> {
			#trace => 'STDERR'
			#debug => 'STDERR',
		}
	);
	
	$shipment->submit( %args ) or die $shipment->error();
	return $shipment;
}

sub test_online
{
	my ( %args ) = @_;
	my $shipment = Business::Shipping->rate_request( 
		shipper 		=> 'Online::UPS',
		cache			=> 0,
		user_id			=> $ENV{ UPS_USER_ID },
		password		=> $ENV{ UPS_PASSWORD },
		access_key		=> $ENV{ UPS_ACCESS_KEY }, 
		cache			=> 0,
		event_handlers	=> {
			#trace => 'STDERR' 
			#debug => 'STDERR',
		}
	);
	
	$shipment->submit( %args ) or die $shipment->error();
	return $shipment;
}

my $shipment;
my $shipment_online;

my $ups_online_msg = 'UPS: we need the username, password, and access license key';
###########################################################################
##  Domestic Single-package API
###########################################################################

my %one_da_light_us = (
	service			=> '1DA',
	weight			=> '3.45',
	from_zip		=> '98682',
	to_residential	=> '0',
	to_zip			=> '98270',
);

$shipment = test( %one_da_light_us );
ok( $shipment->total_charges(),		'UPS domestic single-package API total_charges > 0' );
print "offline 1DA light close: " . $shipment->total_charges() . "\n";

SKIP: {
	skip( $ups_online_msg, 1 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	$shipment_online = test_online( %one_da_light_us );
	ok( $shipment_online->total_charges(),		'UPS domestic single-package API total_charges > 0' );
	print "online 1DA light close: " . $shipment_online->total_charges() . "\n";
}

my %ground_res_heavy_far_us = (
	service			=> 'GNDRES',
	weight			=> '45.00',
	from_zip		=> '98682',
	to_residential	=> '',
	to_zip			=> '22182',
);

$shipment = test( %ground_res_heavy_far_us );
ok( $shipment->total_charges(),		'UPS domestic single-package API total_charges > 0' );
print "Offline: GNDRES, heavy, far: " . $shipment->total_charges() . "\n";


SKIP: {
	skip( $ups_online_msg, 1 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	$shipment_online = test_online( %ground_res_heavy_far_us );
	ok( $shipment_online->total_charges(),		'UPS domestic single-package API total_charges > 0' );
	print "Online: GNDRES, heavy, far: " . $shipment_online->total_charges() . "\n";
}

my %ground_res_light_far_us = (
	service			=> 'GNDRES',
	weight			=> '3.00',
	from_zip		=> '98682',
	to_residential	=> '',
	to_zip			=> '22182',
);

$shipment = test( %ground_res_light_far_us );
ok( $shipment->total_charges(),		'UPS domestic single-package API total_charges > 0' );
print "Offline: GNDRES, light, far: " . $shipment->total_charges() . "\n";

SKIP: {
	skip( $ups_online_msg, 1 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	$shipment_online = test_online( %ground_res_light_far_us );
	ok( $shipment_online->total_charges(),		'UPS domestic single-package API total_charges > 0' );
	print "Online: GNDRES, light, far: " . $shipment_online->total_charges() . "\n";
}

my %ground_res_light_close_us = (
	service			=> 'GNDRES',
	weight			=> '3.00',
	from_zip		=> '98682',
	to_residential	=> '',
	to_zip			=> '98270',
);

$shipment = test( %ground_res_light_close_us );
ok( $shipment->total_charges(),		'UPS domestic single-package API total_charges > 0' );
print "Offline: GNDRES, light, close: " . $shipment->total_charges() . "\n";

SKIP: {
	skip( $ups_online_msg, 1 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	$shipment_online = test_online( %ground_res_light_close_us );
	ok( $shipment_online->total_charges(),		'UPS domestic single-package API total_charges > 0' );
	print "Online: GNDRES, light, close: " . $shipment_online->total_charges() . "\n";
}

my %ground_res_medium_close_us = (
	service			=> 'GNDRES',
	weight			=> '22.50',
	from_zip		=> '98682',
	to_residential	=> '1',
	to_zip			=> '22182',
);

$shipment = test( %ground_res_medium_close_us );
ok( $shipment->total_charges(),		'UPS domestic single-package API total_charges > 0' );
print "Offline: GNDRES, medium, close, residential: " . $shipment->total_charges() . "\n";

SKIP: {
	skip( $ups_online_msg, 1 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	$shipment_online = test_online( %ground_res_medium_close_us );
	ok( $shipment_online->total_charges(),		'UPS domestic single-package API total_charges > 0' );
	print "Online: GNDRES, medium, close, residential: " . $shipment_online->total_charges() . "\n";
}



