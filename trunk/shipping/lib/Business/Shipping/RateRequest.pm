# Business::Shipping::RateRequest - Abstract class
# 
# $Id: RateRequest.pm,v 1.4 2003/12/22 03:49:05 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::RateRequest;

use strict;
use warnings;

use vars qw( $VERSION );
use base ( 'Business::Shipping' );
$VERSION = do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Data::Dumper;
use Business::Shipping::Debug;
use Cache::FileCache;


use Business::Shipping::CustomMethodMaker
	new_hash_init => 'new',
	boolean => [ 'is_success', 'cache' ],
	hash => [ 'results' ],
	grouped_fields_inherit => [
		required => [ 'shipper' ],
		unique => [ 'shipper' ]
	],
	object => [
		# Right now, each RateRequest has only one shipment.
		# Eventually, maybe we'll use object_list with "shipments()->..." like packages.
		'Business::Shipping::Shipment' => {
			'slot' => 'shipment',
			'comp_mthds' => [ 
				'service', 
				'from_country',
				'to_country', 
				'from_zip',
				'to_zip',
				'packages',
				'default_package',
				'weight',
				'shipper',
			],
		}
	];

#sub get_package { return shift->packages()->[ @_ ]; }

=item $shipment->submit( [%args] )

This method sets some values (optional), generates the request, then parses the
results.

=cut
sub submit
{
	my ( $self, %args ) = @_;
	trace( "( " . uneval( %args ) . " )" );
	$self->init( %args ) if %args;
	$self->_massage_values();
	$self->validate() or return ( undef );
	
	
	my $cache = Cache::FileCache->new() if $self->cache();
	
	if ( $self->cache() ) {
		trace( 'cache enabled' );	

		my $key = $self->gen_unique_key();
		debug "cache key = $key\n";
		
		my $results = $cache->get( $key );
		if ( $results ) {
			trace( "found cached response, using that." );
			$self->results( $results );
			return 1;
		}
		else {
			trace( 'Cannot find cached results, running request manually, then add to cache.' );
		}
	}
	else {
		trace( 'cache disabled' );
	}
	
	$self->perform_action();
	
	my $results = $self->results();
	debug 'results = ' . Dumper( $results );
	
	# Only cache if there weren't any errors.
	if ( $self->_handle_response() and $self->cache() ) {	
		trace( 'cache enabled, saving results.' );
		#TODO: Allow setting of cache properties (time limit, enable/disable, etc.)
		my $key = $self->gen_unique_key();
		my $cache = Cache::FileCache->new();
		$cache->set( $key, $results, "2 days" );
	}
	else {
		trace( 'cache disabled, not saving results.' );
	}
	
	return $self->is_success();
}

sub get_unique_hash
{
	my $self = shift;
	
	my %unique;
	
	$unique{ $_ } = $self->$_() for $self->unique();
	$unique{ $_ } = $self->shipment->$_() for $self->shipment->unique();
	
	foreach my $package ( $self->shipment->packages() ) {
		foreach my $package_unique_key ( $package->unique() ) {
			$unique{ 'p1_' . $package_unique_key } = $package->$package_unique_key();
		}
	}
	return %unique;
}

sub gen_unique_key
{
	my $self = shift;
	my %unique = $self->get_unique_hash();
	my @sorted_values = $self->hash_to_sorted_values( %unique ); 
	return join( '|', @sorted_values );
	return;
}

sub hash_to_sorted_values
{
	my $self = shift;
	my ( %hash ) = @_;
	my @sorted_values;
	foreach my $key ( sort keys %hash ) {
		push @sorted_values, ( $hash{ $key } || '' );
	}
	return @sorted_values;
}

sub total_charges
{
	trace '()';
	my $self = shift;
	my $total;
	
	my $shippers = $self->results();
	foreach my $shipper ( keys %$shippers ) {
		debug "\tshipper: $shipper\n";
		
		my $packages = $self->results( $shipper );		
		foreach my $package ( @$packages ) {
			debug3 "\t" . uneval( $package );
			debug "\t\tcharges = " . $package->{ 'charges' } . "\n";
			$total += $package->{ 'charges' };
		}
	}
		
	return $total;
}

sub get_unique_keys
{
	my $self = shift;
	
	# None at the Business::Shipping level.
	my @unique_keys = ();
	
	return( @unique_keys );
}

sub _gen_unique_values
{
	trace '()';
	my ( $self ) = @_;
		
	# Now I need to get unique values for all packages.
	
	my @unique_values;
	foreach my $package ( @{$self->packages()} ) {
		push @unique_values, $package->get_unique_values();
	}
	
	# We prefer 0 in the key to represent 'undef'
	# clean it all up...
	my @new_unique_values;
	foreach my $value ( @unique_values ) {
		if ( not defined $value ) {
			$value = 0;
		}
		push @new_unique_values, $value;
	}

	return( @new_unique_values );
}

#
# This is from 0.04.
# Needs to be made compatible with the new version.
#
sub add_package
{
	my $self = shift;
	trace('called with' . uneval( @_ ) );
	
	my $new = Business::Shipping->new( 'package' => $self->package_subclass_name() );
	
	$new->set( @_ );
	
	# If the passed package has an ID, then use that.
	if ( $new->id() or ( $new->id() and $new->id() == 0 ) ) {
		trace( "Using id in passed package" );
		$self->packages()->[$new->id()] = $new;
		return 1;
	}
		
	# If the "default" package ($self->packages()->[0]) is 
	# still in "default" state (has not yet been updated),
	# then replace it with the passed package.
	trace( 'checking to see if default package is empty...' );
	if ( $self->default_package()->is_empty() ) {
		trace( 'yes, is empty.' );
		$self->packages()->[0] = $new;
		trace( 'done setting up default package.' );
		return 1;	
	}
	trace( 'no, not empty.' );
	
	# Otherwise, add the package in the second slot.
	push( @{$self->packages()}, $new );
	
	return 1;
}

1;
__END__
