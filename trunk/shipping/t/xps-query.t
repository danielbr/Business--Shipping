#!/usr/bin/perl

use Business::Ship;

my $shipment = new Business::Ship( shipper => UPS );

$shipment->set(
	cache_enabled => 0,
	event_handlers => ({ trace => STDOUT, debug => STDOUT }), 
);

$shipment->set(
	user_id => $ENV{ UPS_USER_ID },
	access_key => $ENV{ UPS_ACCESS_KEY },
	password => $ENV{ UPS_PASSWORD }	,
	
	#from_country => US,
	#to_country => 'United States',
	weight => 6,
	tx_type => rate,
	
	from_zip => 98682,
	to_zip => 98270,
	service => GNDRES,
	to_residential => 1,
	pickup_type => 'daily pickup',
) or print $shipment->error();

$shipment->submit() or print $shipment->error();
print $shipment->total_charges();
