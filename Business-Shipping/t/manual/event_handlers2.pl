#!/usr/bin/perl

#
# Simple log4perl example of what event_handlers() will eventually do.
#

use strict;
use warnings;
use Test::More 'no_plan';
use Carp;
use Log::Log4perl;
use Data::Dumper;

ok( 1, "No tests yet" );

my $config_filename = 't/manual/log4perl.conf'; 
Log::Log4perl->init( $config_filename );
my $logger = Log::Log4perl->get_logger('Business::Shipping');

package Business::Shipping;

$logger->debug('this is a debug message');
$logger->info('this is an info message');
$logger->warn('warning');
$logger->error('error');
$logger->fatal('fatal');

$ENV{ BS_LOG_LEVEL } = "DEBUG, Screen";
Log::Log4perl->init( $config_filename );
# Try reading configuration

#my $config_hash = Log::Log4perl::Config::config_read( 't/manual/log4perl.conf' );

# Change one parameter

#$config_hash->{ category }->{ Business }->{ Shipping }->{ value } = 'ERROR, Screen';
#use Data::Dumper;
#print STDERR Dumper( $config_hash );

#Log::Log4perl::init( $config_hash );

print "\n\n==========   Round Two   ============\n\n";

$logger->debug('this is a debug message');
$logger->info('this is an info message');
$logger->warn('warning');
$logger->error('error');
$logger->fatal('fatal');

