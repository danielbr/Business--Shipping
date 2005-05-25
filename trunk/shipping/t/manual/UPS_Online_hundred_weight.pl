use strict;
use warnings;

use Business::Shipping;
use Data::Dumper;

Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Online' );

my %access = (
    'user_id'    => $ENV{ UPS_USER_ID },
    'password'   => $ENV{ UPS_PASSWORD },
    'access_key' => $ENV{ UPS_ACCESS_KEY }, 
);

$rate_request->init(
    service    => 'gndres', #gndres
    #weight     => '345',
    from_zip   => '98682',
    to_zip     => '98270',
    %access
);

$rate_request->shipment->add_package( weight => 151 ); # 105 x 5 = 525
#$rate_request->shipment->add_package( weight => 105 );
#$rate_request->shipment->add_package( weight => 105 );
#$rate_request->shipment->add_package( weight => 105 );
#$rate_request->shipment->add_package( weight => 105 );

#print Dumper( $rate_request );

print "weight of shipment = " . $rate_request->shipment->weight . "\n";
#exit;

my $results = $rate_request->submit() or die $rate_request->user_error();

print "UPS_Online One Day Air Hundredweight = " . $rate_request->total_charges() . "\n";

