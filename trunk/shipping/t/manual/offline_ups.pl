#!/usr/bin/perl

use Data::Dumper;
use Business::Shipping;

my $package			= Business::Shipping::Package::UPS->new();
my $shipment		= Business::Shipping::Shipment::UPS->new();
my $rate_request	= Business::Shipping::RateRequest::Offline::UPS->new();

$shipment->packages_push( $package );
$rate_request->shipment( $shipment );
$rate_request->init(
	shipper 		=> 'UPS',
	#offline			=> 1,
	cache			=> 0,
	event_handlers	=> {
			
			#'debug3' => 'STDERR',
			#'trace' => 'STDERR',
			#'debug' => 'STDERR',
			'error' => 'STDERR',
	},
	#zone_file		=> '450.csv',
	#auto_update		=> 1,
	#disable_download	=> 1,
	#disable_unzip	=> 1,
	
		service			=> 'UPSSTD', 
		to_country		=> 'CA',
		to_city			=> 'Richmond',
		to_zip			=> 'V6X3E1',
		weight			=> 0.5,
);

print STDERR "rate_request = " . Dumper( $rate_request ) . "\n"; 

$rate_request->submit() or die $rate_request->error();
print "\$" . $rate_request->total_charges() . "\n";
