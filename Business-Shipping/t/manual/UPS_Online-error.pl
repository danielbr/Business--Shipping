#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

#Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'Online::UPS' );

my $results = $rate_request->submit(
                #shipper         => 'UPS_Online',
                cache => 0,
    from_state    => 'Washington',
    from_zip    => '98682',
    service        => 'XPR',
    weight        => 20,
    to_country    => 'GB',
    to_zip        => 'RH98AX',
                user_id         => $ENV{ UPS_USER_ID },
                password        => $ENV{ UPS_PASSWORD },
                access_key      => $ENV{ UPS_ACCESS_KEY },
                #pickup_type     =>  'daily',
                #to_residential  => 1,
) or die $rate_request->user_error();

use Data::Dumper;
print "UPS_Online: " . $rate_request->total_charges() . "\n";

# Should be 7.32 for non-residential.

