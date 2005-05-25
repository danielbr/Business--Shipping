use strict;
use warnings;
use Business::Shipping;
use Data::Dumper;

print "Testing new data format\n";

#Business::Shipping->log_level( 'debug' );

my %access = (
    'user_id'    => $ENV{ UPS_USER_ID },
    'password'   => $ENV{ UPS_PASSWORD },
    'access_key' => $ENV{ UPS_ACCESS_KEY }, 
);

my %can_req = (
    service    => 'UPSSTD',
    from_state => 'WA',
    weight     => '45',
    from_zip   => '98682',
    to_country => 'CA',
    to_zip     => 'M1V 2Z9',
);

# Also test XPR to canada.
# service =>      'XPR',

my $rate_request6 = Business::Shipping->rate_request( shipper => 'UPS_Offline' );
my $results6 = $rate_request6->submit( %can_req ) or die $rate_request6->user_error();
print "UPS_Offline Standard to Canada 45 pounds = " . $rate_request6->total_charges() . "\n";

my $rate_request5 = Business::Shipping->rate_request( shipper => 'UPS_Online' );
my $results5 = $rate_request5->submit( %can_req, %access, cache => 1 ) or die $rate_request5->user_error();
print "UPS_Online Standard to Canada 45 pounds = " . $rate_request5->total_charges() . "\n";

my %intl_req = (
    from_state  => 'Washington',
    from_zip    => '98682',
    service     => 'XPD',
    weight      => 20,
    to_country  => 'GB',
    to_zip      => 'RH98AX',
);

my $rate_request3 = Business::Shipping->rate_request( shipper => 'UPS_Offline' );
my $results3 = $rate_request3->submit( %intl_req ) or die $rate_request3->user_error();
print "UPS_Offline Expedited to Great Britain 20 pounds = " . $rate_request3->total_charges() . "\n";


my $rate_request4 = Business::Shipping->rate_request( shipper => 'UPS_Online' );
my $results4 = $rate_request4->submit( %intl_req, %access, cache => 1 ) or die $rate_request4->user_error();
print "UPS_Online Expedited to Great Britain 20 pounds = " . $rate_request4->total_charges() . "\n";

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );


#$rate_request->shipment->max_weight( 70 );

# 4 packages of 50 lbs each, for example

# Need support for multiple packages before we can support hundred-weight.


my %request = (
    service    => '1DA',
    weight     => '35',
    from_zip   => '98682',
    to_zip     => '98270',
);

my $results = $rate_request->submit( %request ) or die $rate_request->user_error();

#print Dumper( $rate_request );
print "UPS_Offline One Day Air 35 lbs = " . $rate_request->total_charges() . "\n";


# Was $443.48 before hundredweight support.



my $rate_request2 = Business::Shipping->rate_request( shipper => 'UPS_Online' );
my $results2 = $rate_request2->submit( %request, %access, cache => 1 ) or die $rate_request2->user_error();

#print Dumper( $rate_request );
print "UPS_Online One Day Air 35 lbs = " . $rate_request2->total_charges() . "\n";
#print "UPS_Online One Day Air 35 lbs = (49.28, run from cache)\n";# . $rate_request2->total_charges() . "\n";



