#!/usr/bin/perl

use Business::Ship::UPS;

my $shipment = new Business::Ship( 'shipper' => 'UPS' );


$shipment->set(


