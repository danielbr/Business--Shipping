#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rate_request->submit(
 	#
    #to_city => 'enterprise',
    
    to_zip   => '36330',
	from_zip => '98682',
	weight   => 2.75,
	service  => 'GNDRES',
    to_residential =>               '1',
    event_handlers => {
        #debug     => 'STDERR',
        #error    => 'STDERR',
    },
) or die $rate_request->error();

print "offline = " . $rate_request->total_charges() . "\n";

=pod

Ship From: 		VANCOUVER, 98682, UNITED STATES 	
Ship To: 		ENTERPRISE, 36330, UNITED STATES 	
Shipment Date: 		Tuesday,March 9, 2004  	
Bill to UPS Account: 		Yes 	
Total Shipment Weight: 		2.8 lbs. 	
Drop-off / Pickup: 		Daily Pickup - I have a daily UPS pickup 	
Address Type: 		Residential 	
Number of Packages: 		1 	
Packaging: 		Your Packaging 	
Customs Value: 		Not Entered 	
Currency: 		USD


UPS Ground: 8.64

=cut
