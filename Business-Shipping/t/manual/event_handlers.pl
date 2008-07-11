#!/usr/bin/perl

#
# Test event_handlers()
#

use strict;
use warnings;
use Business::Shipping;
use Test::More 'no_plan';
use Carp;

#use Log::Log4perl;
#use Data::Dumper;
#my $config_hash = Log::Log4perl::Config::config_read( 'config/log4perl.conf' );
#print Dumper( $config_hash );

#Business::Shipping->log_level( 'debug' );

my $rate_request = Business::Shipping->rate_request(
    shipper   => 'Offline::UPS',
    service   => 'GNDRES',
    from_zip  => '98682',
    to_zip    => '98270',
    weight    =>  5.00,
    #event_handlers => { debug => 'STDERR' },
);

#Business::Shipping->log_level( 'debug' );

#$rate_request->event_handlers( { debug => 'STDERR' } );

$rate_request->submit() or die $rate_request->user_error();

print $rate_request->total_charges() . "\n";

ok( $rate_request->total_charges(), 'Regular test works' );
