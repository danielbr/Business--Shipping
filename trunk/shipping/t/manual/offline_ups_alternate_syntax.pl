#!/usr/bin/perl

use strict;
use warnings;
#use diagnostics;

use Test::More 'no_plan';
use Carp;
use Business::Shipping;

my $shipment = Business::Shipping->rate_request( 
    shipper => 'Offline::UPS', 
    event_handlers => {
        debug => 'STDERR',
        error => 'STDERR',
    },
);

$shipment->init( 
    'from_country' => "US",
    'to_country' => "US",
    'service' => "GNDRES",
    'weight' => "5.10",
    'from_zip' => "97214",
    'to_zip' => "98270",
    'shipper' => "Offline::UPS",
    'cache' => "1",
);

$shipment->submit();


ok( $shipment->total_charges(),        '$shipment->submit() syntax OK' );


