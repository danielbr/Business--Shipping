#!perl

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

$rate_request->submit(
    service        => 'XDM',
    weight        => 20,
    to_country    => 'GB',
    from_zip    => '98682',
    from_state    => 'Washington',
    to_zip        => 'RH98AX',
    event_handlers => {
        debug     => 'STDERR',
        error    => 'STDERR',
    },
    #unzip        => 1,
    #convert        => 1,
    
) or die $rate_request->user_error();

print "offline = " . $rate_request->total_charges() . "\n";


my $rate_request_online = Business::Shipping->rate_request( shipper => 'UPS_Online' );

$rate_request_online->submit(
    service        => 'XDM',
    weight        => 20,
    to_country    => 'GB',
    from_zip    => '98682',
    to_zip        => 'RH98AX',
    event_handlers => {
        debug     => 'STDERR',
        error    => 'STDERR',
    },
) or die $rate_request_online->user_error();

print "online = " .  $rate_request_online->total_charges() . "\n";
