use strict;
use warnings;
use Test::More 'no_plan';
use Carp;
use Data::Dumper;
use Business::Shipping::RateRequest;
use Business::Shipping::RateRequest::Online;
use Business::Shipping::RateRequest::Online::UPS;
use Business::Shipping::Shipment;
use Business::Shipping::Shipment::UPS;
use Business::Shipping::Package;
use Business::Shipping::Package::UPS;

my $ups_online_msg = 'UPS: we need the username, password, and access license key';

my $ups_online_rate_request = Business::Shipping::RateRequest::Online::UPS->new();
ok( defined $ups_online_rate_request, 'Business::Shipping::RateRequest::Online::UPS->new() worked' );

ok( $ups_online_rate_request->prod_url(), "Default values (prod_url)" );

my $package = Business::Shipping::Package->new();
ok( defined $package,  'Business::Shipping::Package->new()' );

$package->weight( 5.5 );
ok( $package->weight() == 5.5, 'Business::Shipping::Package->weight()' );

my $ups_package = Business::Shipping::Package::UPS->new();
ok( defined $ups_package, 'Business::Shipping::Package::UPS->new()' );

$ups_package->weight( 6.5 );
ok( $ups_package->weight() == 6.5, 'Business::Shipping::Package::UPS->weight()' );

$ups_package->packaging( 'TODO: put something here' );
ok( $ups_package->packaging() eq 'TODO: put something here', 'Business::Shipping::Package::UPS->packaging()' );

my $shipment = Business::Shipping::Shipment->new();
ok( defined $shipment, 'Business::Shipping::Shipment->new()' );

my $ups_shipment = Business::Shipping::Shipment::UPS->new();
ok( defined $ups_shipment, 'Business::Shipping::Shipment::UPS->new()' );

# Make sure it has packages
$ups_shipment->packages_push( $ups_package );

my ( $test_package ) = @{ $ups_shipment->packages() };
ok( $test_package->weight() == 6.5, 'Business::Shipping::Shipment::UPS->packages()' );

# Second package in shipment... supported?
my $ups_package2 = Business::Shipping::Package::UPS->new( 'weight' => 23 );
$ups_shipment->packages_push( $ups_package2 );

ok( $ups_shipment->total_weight() == 29.5, 'Shipment::UPS->total_weight()' );

my $abstract_rate_request = Business::Shipping::RateRequest->new();
ok( defined $abstract_rate_request, 'Business::Shipping::RateRequest->new()' ); 

$abstract_rate_request->shipment->service( 'GNDRES' );

#print Dumper( $abstract_rate_request );
#if ( ! $abstract_rate_request->can( 'service' ) ) {
#	print "Business::Shipping::RateRequest can't run service()\n";
#}

ok( $abstract_rate_request->service() eq 'GNDRES', 'Business::Shipping::RateRequest->service() remaps to Shipment->service()' );


# Test error message handling

my $shipping = Business::Shipping->new();
$shipping->event_handlers( { error => undef } );
$shipping->error( 'This is a test error message.' );

ok( $shipping->error() eq 'This is a test error message.', 'Shipping::error()' );
ok( $shipping->error_msg() eq 'This is a test error message.', 'Shipping::error_msg()' );

#Clean out the ups_shipment object
$ups_shipment = Business::Shipping::Shipment::UPS->new(
	'shipper'		=> 'UPS',
	'service'		=> 'GNDRES',
	#'from_zip'		=> '98682',
	'to_zip'		=> '98270',
);

$ups_shipment->from_zip( '98682' );

$ups_shipment->packages_push(
	Business::Shipping::Package::UPS->new( 
		'weight' => 10.5,
		#'packaging' => '',
	)
);


print Dumper $ups_online_rate_request;


=pod

my $online_rate_request = new Business::Shipping::RateRequest::Online;
my $packages = [
	Business::Shipping::Package->new( 'weight' => '10' ),
	Business::Shipping::Package->new( 'weight' => '32' ),
	Business::Shipping::Package->new( 'weight' => '5'  ),
];
my $shipment = Business::Shipping::Shipment->new();
$shipment->packages( $packages );

$rate_request->set_shipment( $shipment );
$rate_requets->set(
	user_id => 'user_id',
	password => 'password',
	# If you set the service, it will only get prices for that one service
	# If you leave out the service, it will try to get all available prices
	# service => 'GNDRES',
	
	# If you set the shipper, it will only get prices for that shipper
	# If you leave out the shipper, it will try to get all available prices
	# shipper => 'UPS'

);

$rate_request->submit() or print $rate_request->error();

# get_services() for UPS would have to do some extra stuff.
# It needs to use their services to find stuff...
# For offline... what could we do?  
#
# Does it support multiple services per request?
# USPS: domestic and international: YES
# UPS: no and no. ( but it can if you send a request first)

# combined_services_hash has "UPS Ground Residential" => 23.15
my %services = $rate_request->get_combined_services_hash();

# 

my $results = $rate_request->get_result_hashref();

# This is what the results will look like
$results = {
	'UPS' => {
		'GNDRES' => {
			'price' => 23.15,
			'description' => 'Ground Residential',
		},
		'1DA' => {
			'price' => 44.95,
			'shipping' => 40.00,
			'tax' => 4.95,
			'description' => 'One Day Air',
		},
	},
	'USPS' => {
		'Priority' => {
			'price' => 15.00,
			'description' => 'Priority Mail',
		},
		'Express' => {
			'price' => 30.00,
			'description' => 'Express Mail',
			'restrictions' => '',
		},
	},
};

%simple_hash = (
	'UPS Ground Residential' => '4.00',
	'UPS One Day Air' => '20.00',
	'USPS Priority Mail' => '5.99',
);


foreach my $shipper ( %{ $results } ) {
	foreach my $service ( keys %{ $shipper } ) {
		print $shipper . $service . $service->{ price };
	}
}
	

# For now, lets not support multiple shipments per request, until all the drivers can do it (LPW::Multiple)
# Multiple shipments per request:
# USPS International

# Multiple Packages per request:
# USPS Domestic
# UPS Domestic
# UPS International.




$rate_request->set(
	'tx_type' => 'online_rate_request',
	'user_id' => '',
);


foreach my $service ( $rate_request->find_services() ) {
}

$rate_request->submit() or die $rate_request->error();

	

my $shipping = Business::Shipping->new();

=cut
