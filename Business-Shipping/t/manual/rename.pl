use strict;
use warnings;
use Test::More 'no_plan';

use_ok( 'Business::Shipping' );

=pod

my $rate_request = Business::Shipping->rate_request(
    shipper    => 'UPS_Online',
    service    => 'GNDRES',
    from_zip   => '98682',
    to_zip     => '98270',
    weight     => 10.00,
    user_id    => $ENV{ UPS_USER_ID },
    password   => $ENV{ UPS_PASSWORD },
    access_key => $ENV{ UPS_ACCESS_KEY }, 
);    

$rate_request->submit() or die $rate_request->user_error();
print 'Total Charges = $' . $rate_request->total_charges() . "\n";


my $rate_request2 = Business::Shipping->rate_request(
    shipper    => 'UPS_Offline',
    service    => 'GNDRES',
    from_zip   => '98682',
    to_zip     => '98270',
    weight     => 10.00,
);    

$rate_request2->submit() or die $rate_request2->user_error();

print 'Total Charges = $' . $rate_request2->total_charges() . "\n";

=cut

my $rate_request = Business::Shipping->rate_request(
    shipper    => 'USPS_Online',
    service    => 'Priority',
    from_zip   => '98682',
    to_zip     => '98270',
    weight     => 10.00,
    user_id    => $ENV{ USPS_USER_ID },
    password   => $ENV{ USPS_PASSWORD },
);    

$rate_request->go() or die $rate_request->user_error();
print 'Total Charges = $' . $rate_request->total_charges() . "\n";

