#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my %request = (
    from_city      => 'Vancouver',
    from_zip       => '98682',
    
    to_city        => 'Enterprise',
    to_zip         => '36330',
    to_residential => 1,
    
    weight         => 2.75,
    service        => 'GNDRES',
  
);

my $rr_off = Business::Shipping->rate_request( 
    shipper => 'Offline::UPS', 
    %request
);
$rr_off->submit or die $rr_off->user_error();
print "offline = " . $rr_off->total_charges() . "\n";
print "offline price components = " . $rr_off->display_price_components;

my $rr_on = Business::Shipping->rate_request( 
    shipper => 'Online::UPS', 
    %request
);
$rr_on->submit or die $rr_on->user_error();
print "online = " . $rr_on->total_charges() . "\n";




=pod

Manual paper lookup:

     Delivery Area Surchage (Residential): $1.75.
     Residential Differential: 1.40
     1DA/2DA: $1.15 on TOP of $1.75, if residential

From website:

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
