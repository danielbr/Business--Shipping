use strict;
use warnings;

use Business::Shipping;
use Data::Dumper;

Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

#$rate_request->shipment->max_weight( 70 );

# 4 packages of 50 lbs each, for example

# Need support for multiple packages before we can support hundred-weight.

$rate_request->init(
    service    => '1da', #gndres
    #weight     => '345',
    from_zip   => '98682',
    to_zip     => '98270',
);

# 300 pounds total over 5 packages.
# The following configuration resulted in the this rate at ups.com:
# 1DA = 382.70
# 1DAsaver = 334.24
# Ground = 100.11
$rate_request->shipment->add_package( weight => 105 ); # 105 x 5 = 525
$rate_request->shipment->add_package( weight => 105 );
$rate_request->shipment->add_package( weight => 105 );
$rate_request->shipment->add_package( weight => 105 );
$rate_request->shipment->add_package( weight => 105 );

$rate_request->shipment->disable_hundredweight( 1 );

# If all 5 packages were 105 pounds, the rates from ups.com are:
# 1DA = 706.30 (141.26 each package) (my code: 698.61)
# 1DAsaver = 615.95                  
# Ground = 249.85 (49.97 ea)         (my code: 268.82, 55.30 for one.)

# My code: ground zone = 2
# 1da zone = 102

# 525 pounds / 100 * 21.30 = 111.83.
# 105 / 100 * 21.30 = 22.365  ( * 3 = 111.825 ) 
# +
# 

# Minimum charge per shipment based on average weight of 15 pounds per package



my $results = $rate_request->submit() or die $rate_request->user_error();

#print Dumper( $rate_request );
print "UPS_Offline One Day Air Hundredweight = " . $rate_request->total_charges() . "\n";

# Currently $443.48 (before hundredweight support).

exit;

my %access = (
    'user_id'    => $ENV{ UPS_USER_ID },
    'password'   => $ENV{ UPS_PASSWORD },
    'access_key' => $ENV{ UPS_ACCESS_KEY }, 
);


my $rate_request2 = Business::Shipping->rate_request( shipper => 'UPS_Online' );
my $results2 = $rate_request2->submit(
    service    => '1DA',
    weight     => '345',
    from_zip   => '98682',
    to_zip     => '98270',
    %access,
    cache      => 1,
) or die $rate_request2->user_error();

#print Dumper( $rate_request );
print "UPS_Online One Day Air Hundredweight = " . $rate_request2->total_charges() . "\n";
