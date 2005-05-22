use strict;
use warnings;
use Business::Shipping;
use Data::Dumper;

print "Testing new data format\n";


Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

#$rate_request->shipment->max_weight( 70 );

# 4 packages of 50 lbs each, for example

# Need support for multiple packages before we can support hundred-weight.

my $results = $rate_request->submit(
    service    => '1DA',
    weight     => '35',
    from_zip   => '98682',
    to_zip     => '98270',
) or die $rate_request->user_error();

#print Dumper( $rate_request );
print "UPS_Offline One Day Air Hundredweight = " . $rate_request->total_charges() . "\n";


# Was $443.48 before hundredweight support.



