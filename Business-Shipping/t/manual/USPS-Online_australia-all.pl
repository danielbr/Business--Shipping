#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

#Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'USPS_Online' );

my $results = $rate_request->submit(
    user_id    => $ENV{ USPS_USER_ID },
    password   => $ENV{ USPS_PASSWORD },    
    cache      => 0,
    service    => 'Airmail Parcel Post',
    weight     => 12,
    from_zip   => '98682',
    to_zip     => '5041',
    to_country => 'AU',
) or die $rate_request->user_error();

#use Data::Dumper;
#print Dumper( $rate_request );
print $rate_request->total_charges();

