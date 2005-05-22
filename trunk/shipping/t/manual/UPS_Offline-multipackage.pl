use strict;
use warnings;

use Business::Shipping 1.58;
use Data::Dumper;

#Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );
$rate_request->init(
    service   => '1DA',
    from_zip  => '98682',
    to_zip    => '98270',
);

# 56.39 together
$rate_request->shipment->add_package( weight => 15 ); # 31.21 by itself
$rate_request->shipment->add_package( weight => 10 ); # 27.10 by itself 

print Dumper( $rate_request ) . "\n";

$rate_request->execute() or die $rate_request->user_error();

print "UPS_Offline One Day Air Hundredweight = " . $rate_request->rate() . "\n";

