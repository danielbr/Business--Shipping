#! perl
use strict;
use warnings;

use Test::More 'no_plan';
use Carp;
use Business::Shipping;


my %test;
my $this_test_desc;
sub test
{
	my ( %args ) = @_;
	my $shipment = Business::Shipping->rate_request( 
		from_state	=> 'Washington',	
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


my %ground_res_medium_close_us_98075 = (
	service			=> 'GNDRES',
	weight			=> '22.50',
	from_zip		=> '98682',
	to_residential	=> '1',
	to_zip			=> '98075',
);

$shipment = test( %ground_res_medium_close_us_98075 );
ok( $shipment->total_charges(),		'UPS domestic single-package API total_charges > 0' );
print "Offline: GNDRES, medium, close, residential: " . $shipment->total_charges() . "\n";


###########################################################################
##  International
###########################################################################
%test = (
	from_state	=> 'Washington',
	from_zip	=> '98682',
	service		=> 'XPD',
	weight		=> 20,
	to_country	=> 'GB',
	to_zip		=> 'RH98AX',
);

$shipment = test( %test );
ok( $shipment->total_charges(),		'UPS offline intl to gb' );
print "Offline: intl to gb " . $shipment->total_charges() . "\n";

SKIP: {
	skip( $ups_online_msg, 1 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	$shipment_online = test_online( %test );
	ok( $shipment_online->total_charges(),		'UPS intl to gb' );
	print "Online: intl to gb: " . $shipment_online->total_charges() . "\n";
}

%test = (
	from_state	=> 'Washington',
	from_zip	=> '98682',
	service		=> 'XPR',
	weight		=> 20,
	to_country	=> 'GB',
	to_zip		=> 'RH98AX',
);

$shipment = test( %test );
ok( $shipment->total_charges(),		'UPS offline intl to gb' );
print "Offline: intl to gb " . $shipment->total_charges() . "\n";

SKIP: {
	skip( $ups_online_msg, 1 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	$shipment_online = test_online( %test );
	ok( $shipment_online->total_charges(),		'UPS intl to gb' );
	print "Online: intl to gb: " . $shipment_online->total_charges() . "\n";
}

%test = (
	from_state	=> 'Washington',
	from_zip	=> '98682',
	service		=> 'XDM',
	weight		=> 20,
	to_country	=> 'GB',
	to_zip		=> 'RH98AX',
);

$shipment = test( %test );
ok( $shipment->total_charges(),		'UPS offline intl to gb' );
print "Offline: intl to gb " . $shipment->total_charges() . "\n";

SKIP: {
	skip( $ups_online_msg, 1 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	$shipment_online = test_online( %test );
	ok( $shipment_online->total_charges(),		'UPS intl to gb' );
	print "Online: intl to gb: " . $shipment_online->total_charges() . "\n";
}

###########################################################################
##  Hawaii / Alaska
###########################################################################

%test = (
	service		=> '2DA',
	weight		=> 20,
	from_zip	=> '98682',
	from_state	=> 'Washington',
	to_zip		=> '96826',
);
$this_test_desc = "Hawaii 2DA: ";

$shipment = test( %test );
ok( $shipment->total_charges(),	 "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";

SKIP: {
	skip( $ups_online_msg, 1 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	$shipment_online = test_online( %test );
	ok( $shipment_online->total_charges(),	"UPS Online: " . $this_test_desc );
	"UPS Online: " . $this_test_desc . $shipment_online->total_charges() . "\n";
}

%test = (
	service		=> '1DA',
	weight		=> 20,
	from_zip	=> '98682',
	from_state	=> 'Washington',
	to_zip		=> '96826',
);
$this_test_desc = "Hawaii 1DA: ";

$shipment = test( %test );
ok( $shipment->total_charges(),	 "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";

SKIP: {
	skip( $ups_online_msg, 1 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	$shipment_online = test_online( %test );
	ok( $shipment_online->total_charges(),	"UPS Online: " . $this_test_desc );
	"UPS Online: " . $this_test_desc . $shipment_online->total_charges() . "\n";
}

%test = (
	service		=> '2DA',
	weight		=> 20,
	from_zip	=> '98682',
	from_state	=> 'Washington',
	to_zip		=> '99501',
);
$this_test_desc = "Alaska 2DA: ";

$shipment = test( %test );
ok( $shipment->total_charges(),	 "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";

SKIP: {
	skip( $ups_online_msg, 1 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	$shipment_online = test_online( %test );
	ok( $shipment_online->total_charges(),	"UPS Online: " . $this_test_desc );
	"UPS Online: " . $this_test_desc . $shipment_online->total_charges() . "\n";
}

%test = (
	service		=> '1DA',
	weight		=> 20,
	from_zip	=> '98682',
	from_state	=> 'Washington',
	to_zip		=> '99501',
);
$this_test_desc = "Alaska 1DA: ";

$shipment = test( %test );
ok( $shipment->total_charges(),	 "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";

SKIP: {
	skip( $ups_online_msg, 1 ) 
		unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

	$shipment_online = test_online( %test );
	ok( $shipment_online->total_charges(),	"UPS Online: " . $this_test_desc );
	"UPS Online: " . $this_test_desc . $shipment_online->total_charges() . "\n";
}


