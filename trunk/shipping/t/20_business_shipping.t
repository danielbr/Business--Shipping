#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Carp;
use Business::Shipping;

my $print = 0;

my $rate_request;

#
# Some very simple tests.
#

$rate_request = new Business::Shipping->rate_request( 'shipper' => 'Online::UPS' );
$rate_request->init( to_country    => 'US' );
print "\tto_country = " . $rate_request->to_country() . "\n" if $print;
ok( $rate_request->to_country,            'Online::UPS init( to_country => \'US\' ) works' );

$rate_request = new Business::Shipping->rate_request( 'shipper' => 'Online::UPS' );
$rate_request->to_country( 'US' );
print "\tto_country = " . $rate_request->to_country() . "\n" if $print;
ok( $rate_request->to_country,            'Online::UPS to_country() works' );

$rate_request = new Business::Shipping->rate_request( 'shipper' => 'UPS' );
$rate_request->init( to_country    => 'US' );
print "\tto_country = " . $rate_request->to_country() . "\n" if $print;
ok( $rate_request->to_country,            'UPS init( to_country => \'US\' ) works' );

$rate_request = new Business::Shipping->rate_request( 'shipper' => 'UPS' );
$rate_request->to_country( 'US' );
print "\tto_country = " . $rate_request->to_country() . "\n" if $print;
ok( $rate_request->to_country,            'UPS to_country() works' );


my $shipper = 'USPS_Online';

use Business::Shipping::USPS_Online::Package;
my $package_usps = Business::Shipping::USPS_Online::Package->new;
ok ( defined $package_usps,                    "$shipper" . "::Package constructor" );

use Business::Shipping::USPS_Online::Shipment;
my $shipment_usps = Business::Shipping::USPS_Online::Package->new;
ok ( defined $shipment_usps,                    $shipper . '::Shipment constructor' );

# Test to see if $VERSION is being set correctly:

use Business::Shipping;
ok ( $Business::Shipping::VERSION > 0, "Business::Shipping::VERSION set" );

use Business::Shipping::RateRequest;
ok ( $Business::Shipping::RateRequest::VERSION > 0, "Business::Shipping::RateRequest::VERSION set" );

