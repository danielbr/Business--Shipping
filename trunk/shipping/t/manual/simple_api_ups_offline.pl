#!/usr/bin/perl

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request(
    event_handlers    => {
            'debug' => 'STDERR',
            'debug3' => 'STDERR',
            'trace' => 'STDERR', 
            'error' => 'STDERR',
    },
        cache => 0,
        shipper => 'UPS_Offline',
        'from_zip'            => '98682',
        'from_country'        => 'US',
        'to_country'        => 'US',    
        'service'            => '1DA',
        'to_residential'    => '1',
        'to_zip'            => '98270',
        'weight'            => '1',
);

not defined $rate_request and die $@;

$rate_request->submit() or die $rate_request->user_error();

print "\$" . $rate_request->total_charges() . "\n";
