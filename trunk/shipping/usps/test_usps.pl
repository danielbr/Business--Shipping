#!/usr/bin/perl

print "Testing USPS...\n\n";

use Business::Ship;
use Data::Dumper;

my $shipment = new Business::Ship( 'USPS' );

$shipment->set(
	'event_handlers' => ({ 'debug' => 'STDOUT' }),
	'user_id' 		=> $ENV{USPS_USER_ID},
	'password' 		=> $ENV{USPS_PASSWORD},
	'tx_type' 		=> 'rate',
	'test_mode'		=> 0,
	'service'		=> 'BPM',
	'weight'		=> 3,
	'from_zip'		=> '98682',
	'to_zip'		=> '98270',
);

$shipment->submit();

$shipment->success() or print "Error = " .  $shipment->error_msg();

#$shipment->set(
#	'event_handlers' => ({ 'debug' => 'croak' })
#);

#print "shipment = " . Dumper( $shipment );

print "\n";

1;
