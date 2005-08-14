#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request( shipper => 'UPS_Offline' );

my %req = (
        service =>              '1da',
        from_zip =>             '98682',
        to_zip =>               '97015',
        weight =>               1,
        to_residential => 1,
);

$rate_request->submit( %req ) or die $rate_request->user_error();

use Data::Dumper;
print Dumper( $rate_request );

print "offline = " . $rate_request->total_charges() . "\n";

Business::Shipping->log_level( 'fatal' );

my %user_info = (
        'user_id'    => $ENV{ UPS_USER_ID },
        'password'   => $ENV{ UPS_PASSWORD },
        'access_key' => $ENV{ UPS_ACCESS_KEY }, 
        cache => 0,
);
my $rr_on = Business::Shipping->rate_request( shipper => 'UPS_Online' );
$rr_on->submit( %req, %user_info ) or die $rr_on->user_error();
#use Data::Dumper;
#print Dumper( $rr_on );
print "online = " . $rr_on->rate . "\n";

# BUG: Somewhere, I'm adding the residential differentaiator twice.  
# In my code, I have cost 5.12 + 1.50.  But it should be cost 3.62 + 1.50.

# residential makes it go from 5.00 to 7.32 !?!?

# $5.00 Commercial: 
  # Zone 2: 3.72
  # Delivery Area Surcharge: 1.28
  
# Residential:
  # Zone 2: 5.26
  # Delivery Area Surcharge: 2.06

# 1DA commercial
  # zone 102: 16.15
  # das: 1.37
 
# 1DA residential
  # zone 102: 18.07
  # DAS: 2.19
