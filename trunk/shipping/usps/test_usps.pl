#!/usr/bin/perl

print "Testing USPS...\n\n";

use Business::Ship;
use Data::Dumper;

my $shipment = new Business::Ship( 'USPS' );

$shipment->set(
	'user_id' => 'fdsjakl',
	'password' => 'fdjkasl',
);

print "shipment = " . Dumper( $shipment );

print "\n";

1;
