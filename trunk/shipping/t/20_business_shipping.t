#!perl

use strict;
use warnings;
use Test::More;
use Carp;
use Business::Shipping;

my $print = 0;
my $rate_request;

# Some very simple tests.

plan skip_all => '' if ( not Business::Shipping::Config::calc_req_mod( 'UPS_Online' ) );
plan 'no_plan';

$rate_request = Business::Shipping->rate_request( 'shipper' => 'UPS_Online' );
$rate_request->init( to_country    => 'US' );
print "\tto_country = " . $rate_request->to_country() . "\n" if $print;
ok( $rate_request->to_country,            'UPS_Online init( to_country => \'US\' ) works' );

$rate_request = Business::Shipping->rate_request( 'shipper' => 'UPS_Online' );
$rate_request->to_country( 'US' );
print "\tto_country = " . $rate_request->to_country() . "\n" if $print;
ok( $rate_request->to_country,            'UPS_Online to_country() works' );

$rate_request = Business::Shipping->rate_request( 'shipper' => 'UPS' );
$rate_request->init( to_country    => 'US' );
print "\tto_country = " . $rate_request->to_country() . "\n" if $print;
ok( $rate_request->to_country,            'UPS init( to_country => \'US\' ) works' );

$rate_request = Business::Shipping->rate_request( 'shipper' => 'UPS' );
$rate_request->to_country( 'US' );
print "\tto_country = " . $rate_request->to_country() . "\n" if $print;
ok( $rate_request->to_country,            'UPS to_country() works' );
