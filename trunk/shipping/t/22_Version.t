#!perl
use Test::More 'no_plan';
use_ok( 'Business::Shipping' );

# Test to see if $VERSION is being set correctly:

use Business::Shipping;
ok ( $Business::Shipping::VERSION > 0, "Business::Shipping::VERSION set" );

use Business::Shipping::RateRequest;
ok ( $Business::Shipping::RateRequest::VERSION > 0, "Business::Shipping::RateRequest::VERSION set" );


