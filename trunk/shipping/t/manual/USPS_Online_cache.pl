#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'USPS_Online' );

my $FROM_ZIP = '01351'; # Montague, MA
my $to_zip = '94110';   # San Francisco, CA
my $package_weight = 5;

my $results = $rate_request->submit(
                service         => 'Priority', 
                from_zip        => $FROM_ZIP,
                to_zip          => $to_zip,
                weight          => $package_weight,
                user_id         => $ENV{ USPS_USER_ID },
                password        => $ENV{ USPS_PASSWORD },
                to_residential  => 1,
                cache           => 1,
) or die $rate_request->user_error();

use Data::Dumper;
print "USPS_Online: " . $rate_request->total_charges() . "\n";

# Should be 6.51 for non-residential.
