#!/usr/bin/perl

#
# Test Cache::FileCache
#

use strict;
use warnings;

use Cache::FileCache;

my $cache = new Cache::FileCache( );
my $key = join( "|", ( 'Parcel Post', 'Germany', '5', 'Package' ) ); 
my $package = $cache->get( $key );

if ( not defined $package ) {
	sleep( 5 );
	$package = '5.99';
	$cache->set( $key, $package, "30 minutes" );
}

print "package = $package\n";
