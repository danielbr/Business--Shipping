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


use Business::Shipping::Package::UPS;
my $package_ups = Business::Shipping::Package::UPS->new;
ok ( defined $package_ups,                    'Package::UPS constructor' );

use Business::Shipping::Shipment::UPS;
my $shipment_ups = Business::Shipping::Shipment::UPS->new;
ok ( defined $shipment_ups,                    'Shipment::UPS constructor' );

my $shipper = 'UPS';
my $ups_package2  = Business::Shipping->new_subclass( 'Package::'  . $shipper );
ok ( defined $ups_package2,                     "new_subclass() constructor: Package::$shipper" );
my $ups_shipment2 = Business::Shipping->new_subclass( 'Shipment::' . $shipper );
ok ( defined $ups_shipment2,                    "new_subclass() constructor: Shipment::$shipper" );
my $ups_rron2     = Business::Shipping->new_subclass( 'RateRequest::Online::' . $shipper );
ok ( defined $ups_rron2,                        "new_subclass() constructor: RateRequest::Online::$shipper" );
my $ups_rroff2    = Business::Shipping->new_subclass( 'RateRequest::Offline::' . $shipper );
ok ( defined $ups_rroff2,                       "new_subclass() constructor: RateRequest::Offline::$shipper" );
$ups_shipment2->packages_push( $ups_package2 ) ;
ok ( $ups_shipment2->packages_count == 1,       "Shipment::UPS::packages_push " );



$shipper = 'USPS';

use Business::Shipping::Package::USPS;
my $package_usps = Business::Shipping::Package::USPS->new;
ok ( defined $package_usps,                    "Package::$shipper constructor" );

use Business::Shipping::Shipment::USPS;
my $shipment_usps = Business::Shipping::Package::USPS->new;
ok ( defined $shipment_usps,                    "Shipment::$shipper constructor" );

my $usps_package2  = Business::Shipping->new_subclass( 'Package::'  . $shipper );
ok ( defined $usps_package2,                     "new_subclass() constructor: Package::$shipper" );
my $usps_shipment2 = Business::Shipping->new_subclass( 'Shipment::' . $shipper );
ok ( defined $usps_shipment2,                    "new_subclass() constructor: Shipment::$shipper" );
my $usps_rron2     = Business::Shipping->new_subclass( 'RateRequest::Online::' . $shipper );
ok ( defined $usps_rron2,                        "new_subclass() constructor: RateRequest::Online::$shipper" );
$usps_shipment2->packages_push( $usps_package2 ) ;
ok ( $usps_shipment2->packages_count == 1,       "Shipment::" . $shipper . "::packages_push " );






