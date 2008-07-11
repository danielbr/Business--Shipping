#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Online' );

my $FROM_ZIP = '01351'; # Montague, MA
my $to_zip = '94110';   # San Francisco, CA
my $package_weight = 5;

my $results = $rate_request->submit(
                shipper         => 'UPS_Online',
                service         => 'GNDCOM', 
                from_zip        => $FROM_ZIP,
                to_zip          => $to_zip,
                weight          => $package_weight,
                user_id         => $ENV{ UPS_USER_ID },
                password        => $ENV{ UPS_PASSWORD },
                access_key      => $ENV{ UPS_ACCESS_KEY },
                pickup_type     =>  'daily',
                from_country    => 'US',
                to_country      => 'US',
                to_residential  => 1,
                cache           => 1,
) or die $rate_request->user_error();

use Data::Dumper;
print "UPS_Online: " . $rate_request->total_charges() . "\n";

# Should be 6.51 for non-residential.
