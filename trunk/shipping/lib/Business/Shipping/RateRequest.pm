# Business::Shipping::RateRequest - Abstract class for shipping cost rating.
# 
# $Id: RateRequest.pm,v 1.1 2003/07/07 21:37:59 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::RateRequest;

use strict;
use warnings;

use vars qw( @ISA $VERSION );
@ISA = ( 'Business::Shipping' );
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Shipping::Debug;
use Cache::FileCache;
use Business::Shipping::CustomMethodMaker
	new_hash_init => 'new',
	boolean => [ 'is_success', 'cache' ],
	hash => [ 'results' ],
	grouped_fields_inherit => [
		required => [ 'rate_request_required' ],
		optional => [ 'rate_request_optional' ]
	],
	object => [
		# Right now, each RateRequest has only one shipment.
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

sub required2{ ( 'shipper', 'service', shift->SUPER::required2() ) };

sub find_required { trace( '()' ); 	return ( $_[0]->required(), $_[0]->SUPER::find_required() ); }

# Look for the parent's required, then add your own.	
#sub find_required
#{
#	trace( '()' );
#	my $self = shift;
#	
#	my @required;
#
#	if ( $self->can( 'SUPER' ) ) {
#		if ( $self->SUPER::can( 'find_required' ) ) {
#			@required = $self->SUPER::find_required();
#		}
#		else {
#			debug( 'can\'t execute SUPER::find_required' );
#		}
#	}
#	else {
#		debug( 'can\'t execute SUPER' );
#	}
#	
#	return ( @required, $self->required() );
#}
#
#sub get_package { return shift->packages()->[ @_ ]; }

sub total_charges
{
	my $self = shift;
	my $total;
	
	# See note in Shipping::RateRequest::Online::UPS::_handle_response() about
	# both methods.  For now, we're using the foreach package method.
	#
	# TODO: Select one method.
	#
	my $shippers = $self->results();
	foreach my $shipper ( keys %$shippers ) {
		debug "\tshipper = $shipper\n";
		
		my $services = $self->results( $shipper );		
		foreach my $service ( keys %$services ) {
			debug "\t\tservice = $service\n";
			
			$total += $services->{ $service }->{ 'price' };
			# Optional: Get other aspects, or loop over them all.
			debug "\t\t\tprice = " . $services->{ $service }->{ 'price' } . "\n";
		}
	}
	
	#
	# COMPLETE RESET
	#
	$total = 0;
	foreach my $package ( $self->shipment->packages() ) {
		$total += $package->charges() if defined $package->charges();
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
