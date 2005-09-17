#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

#Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Online' );

my $results = $rate_request->submit(
                shipper         => 'UPS_Online',
                service         => 'GNDCOM', 
                from_zip        => 44114, #Cleveland
                to_zip          => 34050, #FPO AA
                weight          => 5,
                user_id         => $ENV{ UPS_USER_ID },
                password        => $ENV{ UPS_PASSWORD },
                access_key      => $ENV{ UPS_ACCESS_KEY },
                pickup_type     =>  'daily',
                from_country    => 'US',
                to_country      => 'US',
                to_residential  => 1,
) or die $rate_request->user_error();

use Data::Dumper;
print "UPS_Online: " . $rate_request->total_charges() . "\n";

# Should be 7.32 for non-residential.

