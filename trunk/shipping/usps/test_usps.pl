#!/usr/bin/perl

print "Testing USPS...\n\n";

use Business::Ship;
use Data::Dumper;

my $shipment = new Business::Ship( 'USPS' );

$shipment->set(
	'user_id' => 'fdsjakl',
	'password' => 'fdjkasl',
	'tx_type' => 'rate',
	'event_handlers' => ({ 'debug' => 'STDOUT' })
);

$shipment->submit();

$shipment->success() or print "Error = " .  $shipment->error_msg();

#$shipment->set(
#	'event_handlers' => ({ 'debug' => 'croak' })
#);

print "shipment = " . Dumper( $shipment );

print "\n";

1;
