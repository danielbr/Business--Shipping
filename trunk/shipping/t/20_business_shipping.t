#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Carp;
use Business::Shipping;

my $rate_request;

#
# Some very simple tests.
#

$rate_request = new Business::Shipping->rate_request( 'shipper' => 'Online::UPS' );
$rate_request->init( to_country	=> 'US' );
print "\tto_country = " . $rate_request->to_country() . "\n";
ok( $rate_request->to_country,			'Online::UPS init( to_country => \'US\' ) works' );

$rate_request = new Business::Shipping->rate_request( 'shipper' => 'Online::UPS' );
$rate_request->to_country( 'US' );
print "\tto_country = " . $rate_request->to_country() . "\n";
ok( $rate_request->to_country,			'Online::UPS to_country() works' );

$rate_request = new Business::Shipping->rate_request( 'shipper' => 'UPS' );
$rate_request->init( to_country	=> 'US' );
print "\tto_country = " . $rate_request->to_country() . "\n";
ok( $rate_request->to_country,			'UPS init( to_country => \'US\' ) works' );

$rate_request = new Business::Shipping->rate_request( 'shipper' => 'UPS' );
$rate_request->to_country( 'US' );
print "\tto_country = " . $rate_request->to_country() . "\n";
ok( $rate_request->to_country,			'UPS to_country() works' );

#$rate_request = new Business::Shipping->rate_request();
#$rate_request->submit();
#ok( 1, "calling submit() on an empty object doesn't die" );

#$rate_request = new Business::Shipping->rate_request( 'shipper' => 'Offline::UPS' );
#$rate_request->submit();
#ok( $rate_request->invalid, "invalid sense works correctly." );


