#!/usr/bin/perl

use strict;
use warnings;
use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

my %shipping_options = (
    service        => '3DS',
    weight        => 7.5,
    from_zip    => '98662',
    from_state    => 'Washington',
    to_zip        => '22182',
    to_residential => 1
);

$rate_request->submit( %shipping_options )
    or die $rate_request->user_error();
print "offline = " . $rate_request->total_charges() . "\n";
print "offline price components = " . $rate_request->display_price_components . "\n";


my $rate_request_online = Business::Shipping->rate_request( shipper => 'UPS_Online' );
$rate_request_online->submit( %shipping_options )
    or die $rate_request_online->user_error();
print "online = " .  $rate_request_online->total_charges() . "\n";

