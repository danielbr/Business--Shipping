#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use Business::Shipping;

my $rate_request_online = Business::Shipping->rate_request( shipper => 'Online::UPS' );

$rate_request_online->submit(
        service        => 'UPSSTD', 
        weight         => 5,
        to_residential => 1,
        packaging      => '02',
        
        from_country   => 'CA',
        from_city      => 'Richmond',
        from_zip       => 'V6X3E1',
        
        to_country     => 'CA',
        to_city        => 'Kitchener',
        to_zip         => 'N2H6S9',
) or print STDERR $rate_request_online->user_error();

print "from_country_abbrev = " . $rate_request_online->from_country_abbrev || '' ;
print "from_country = " . $rate_request_online->from_country || '' ;

print "online = " .  $rate_request_online->total_charges() . "\n";

