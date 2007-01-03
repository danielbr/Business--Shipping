#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

#Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Online' );

my $FROM_ZIP = '98682'; # Montague, MA
my $to_zip = '50000';   # San Francisco, CA
my $package_weight = 2.0;

#calculated at $53.65 for Worldwide Expedited and the actual price was $75.14.

my $results = $rate_request->submit(
                shipper         => 'UPS_Online',
                service         => 'XPR', 
                from_zip        => $FROM_ZIP,
                to_zip          => $to_zip,
                weight          => $package_weight,
                user_id         => $ENV{ UPS_USER_ID },
                password        => $ENV{ UPS_PASSWORD },
                access_key      => $ENV{ UPS_ACCESS_KEY },
                pickup_type     => 'daily',
                from_country    => 'US',
                to_country      => 'MX',
                to_city         => 'Toluca',
                to_residential  => 1,
) or die $rate_request->user_error();

use Data::Dumper;
print "UPS_Online: " . $rate_request->total_charges() . "\n";

# Should be 7.32 for non-residential.

