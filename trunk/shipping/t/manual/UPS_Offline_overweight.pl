use strict;
use warnings;

use Business::Shipping;
use Data::Dumper;

#Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

#$rate_request->shipment->max_weight( 70 );

$rate_request->init(
    service    => 'gndres', #gndres
    weight     => '175',
    from_zip   => '98682',
    to_zip     => '98270',
);

my $results = $rate_request->submit() or die $rate_request->user_error();
#print Dumper( $rate_request );
print "UPS_Offline One Day Air Hundredweight = " . $rate_request->total_charges() . "\n";

