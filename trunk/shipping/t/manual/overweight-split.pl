use strict;
use warnings;

use Business::Shipping;
use Data::Dumper;

#Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

#$rate_request->shipment->max_weight( 55 );

# 4 packages of 50 lbs each, for example

my $results = $rate_request->submit(
    service    => '1DA',
    weight     => '350',
    from_zip   => '98682',
    to_zip     => '98270',
) or die $rate_request->user_error();

print Dumper( $rate_request );
print "\n\n";
print "UPS_Offline One Day Air = " . $rate_request->total_charges() . "\n";


exit;

my $rate_request3 = Business::Shipping->rate_request( shipper => 'UPS_Offline' );
$results = $rate_request3->submit(
    service    => 'GNDRES',
    weight     => '155',
    from_zip   => '98682',
    to_zip     => '98270',
) or die $rate_request3->user_error();

print "UPS_Offline Ground Residential = " . $rate_request3->total_charges() . "\n";

=pod

my $rate_request2 = Business::Shipping->rate_request( shipper => 'USPS_Online' );

$results = $rate_request2->submit(
    service    => 'Express',
    weight     => '200',
    from_zip   => '98682',
    to_zip     => '98270',
    user_id    => $ENV{ USPS_USER_ID },
    password   => $ENV{ USPS_PASSWORD },        
) or die $rate_request2->user_error();

print "USPS_Online Express = " . $rate_request2->total_charges() . "\n";

=cut
