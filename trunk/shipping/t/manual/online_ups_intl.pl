#!/usr/bin/perl

use strict;
use warnings;
#use diagnostics;
use Business::Shipping;
use Data::Dumper;

my $rate_request_online1 = Business::Shipping->rate_request( shipper => 'Online::UPS' );

$rate_request_online1->init(
    cache          => 0,
    from_zip       => '98682',
    from_country   => 'USA',
    to_country     => 'UK',    
    service        => 'XDM',
    to_residential => '1',
    to_zip         => 'RH98AX',
    weight         => '3.45',
);

#
# Problem: to_country is not stored in the XML.
#

$rate_request_online1->submit() or do {
    print STDERR "error = " .  $rate_request_online1->user_error();
    print STDERR "debug string = " . $rate_request_online1->calc_debug_string();
    #print STDERR Dumper( $rate_request_online1 );
    die;
};

print "UPS online 1 = " .  $rate_request_online1->total_charges() . "\n";



        

