#!/usr/bin/perl
#
# Simulate [xps-query] usage.
#
use strict;
use warnings;

use Business::Ship;

my $mode = 'USPS';
my %opt = (
	'user_id' 		=> $ENV{USPS_USER_ID},
	'password' 		=> $ENV{USPS_PASSWORD},
	'to_country' => 'Canada',
	'service' => 'Airmail Parcel Post',
	'to_zip' => '98681',
	'pounds' => '0.25',
	'tx_type' => 'rate',
);

my $shipment = new Business::Ship( 'shipper' => $mode );
$shipment->submit( %opt ) or ( print $shipment->error() and return ( undef ) );
print $shipment->get_charges( $opt{ 'service' } );	
print "\n";

1;

