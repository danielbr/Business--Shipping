#!/usr/bin/perl

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request(
    event_handlers    => {
            'debug' => 'STDERR',
            'debug3' => undef,
            'trace' => 'STDERR', 
            'error' => 'STDERR',
    },
    
    'shipper' => "Offline::UPS",
    
    'from_state' => "Washington",
    'from_zip' => "98682",
    'from_country' => "US",
    
    'weight' => 1,
    'service' => "3DS",
    'to_country' => "US",
    'to_zip' => "28562",
    
);

not defined $rate_request and die $@;

$rate_request->submit() or die $rate_request->error();

print "\$" . $rate_request->total_charges() . "\n";
