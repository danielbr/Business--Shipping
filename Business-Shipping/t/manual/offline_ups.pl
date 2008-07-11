#!/usr/bin/perl

use Data::Dumper;
use Business::Shipping;
use Business::Shipping::Package::UPS;
use Business::Shipping::Shipment::UPS;
use Business::Shipping::UPS_Offline::RateRequest;


my $package         = Business::Shipping::Package::UPS->new();
my $shipment        = Business::Shipping::Shipment::UPS->new();
my $rate_request    = Business::Shipping::UPS_Offline::RateRequest->new();

$shipment->packages_push( $package );
$rate_request->shipment( $shipment );
%Business::Shipping::Debug::event_handlers = (
            #'debug3' => 'STDERR',
            'trace' => 'STDERR',
            'debug' => 'STDERR',
            'error' => 'STDERR',
);
$rate_request->init(
    shipper         => 'UPS',
    cache            => 0,
    service           => 'UPSSTD', 
    to_country        => 'CA',
    to_city           => 'Richmond',
    to_zip            => 'V6X3E1',
    weight            => 0.5,
    from_state        => 'Washington', 
);

print STDERR "rate_request = " . Dumper( $rate_request ) . "\n"; 

$rate_request->submit() or die $rate_request->user_error();
print "\$" . $rate_request->total_charges() . "\n";
