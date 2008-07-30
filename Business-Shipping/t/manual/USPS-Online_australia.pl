#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'USPS_Online' );

my $results = $rate_request->submit(
    user_id    => $ENV{ USPS_USER_ID },
    password   => $ENV{ USPS_PASSWORD },    
    cache      => 0,
    #service    => 'Priority',
    service    => 'All',
    weight     => 65,  # Max weight is 44 for 'Airmail parcel post'
    from_zip   => '98682',
    to_zip     => '5041',
    to_country => 'AU',
    to_city    => 'fjdskl',
    #size       => 'LARGE',
    #container  => 'Flat Rate Box',
    #machinable => 'FALSE',
    
) or die $rate_request->user_error();

use Data::Dumper;
print Dumper( $rate_request );

