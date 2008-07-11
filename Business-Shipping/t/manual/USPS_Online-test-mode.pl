#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

#Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'USPS_Online' );                              

my %request_parameters = (
    user_id    => '261FDJKS2479',
    #password   => 'blah',
    test_mode  => 1,
    service    => 'EXPRESS',
    from_zip   => '10022',
    to_zip     => '20008',
    pounds     => 10,
    ounces     => 5,
    container  => 'Flat Rate Box',
    size       => 'REGULAR',
);

print "Sending request to the USPS test server...\n";

$rate_request->submit( %request_parameters ) or die $rate_request->user_error();

print "USPS online test results (total charges): " . $rate_request->total_charges() . "\n";
