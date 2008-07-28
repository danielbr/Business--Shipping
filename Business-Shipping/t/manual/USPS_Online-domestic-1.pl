#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Business::Shipping;

#Business::Shipping->log_level( 'info' );

my $rate_req = Business::Shipping->rate_request(
    shipper => 'USPS_Online',
    user_id    => $ENV{ USPS_USER_ID },
    password   => $ENV{ USPS_PASSWORD },
    cache      => 0,
    service    => 'Priority',
    from_zip   => '98682',
    to_zip     => '98270',    
);

# 1st package.
$rate_req->init(
    weight     => 70,
    size       => 'LARGE',
    container  => 'Flat Rate Box',
);

$rate_req->shipment->add_package(
    weight     => 30,
    size       => 'LARGE',
    container  => 'Flat Rate Box',
);



$rate_req->submit() or die $rate_req->user_error();

#print Dumper($rate_req);
#print Dumper($results);
print $rate_req->total_charges() . "\n";
