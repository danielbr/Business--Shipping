# Business::Shipping::Package::USPS
# 
# $Id: USPS.pm,v 1.3 2003/08/20 12:58:48 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Package::USPS;

use strict;
use warnings;

use vars qw( @ISA $VERSION );
@ISA = ( 'Business::Shipping::Package' );
$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Shipping::Debug;
use Business::Shipping::CustomMethodMaker
	new_with_init => 'new',
	new_hash_init => 'hash_init',
	grouped_fields_inherit => [
		optional => [ 'container', 'size', 'machinable', 'mail_type', 'pounds', 'ounces' ],
		
		# Note that we use 'weight' as the unique value, which should convert from pounds/ounces.
		unique => [ 'container', 'size', 'machinable', 'mail_type' ]
	];

use constant INSTANCE_DEFAULTS => (
	container	=> 'None',
	size		=> 'Regular',
	machinable	=> 'False',
	mail_type	=> 'Package',
	ounces		=> 0,
);
 
sub init
{
	my $self   = shift;
	my %values = ( INSTANCE_DEFAULTS, @_ );
	$self->hash_init( %values );
	return;
}

sub weight
{
	trace '()';
	my ( $self, $in_weight ) = @_;
	
	if ( $in_weight ) {
		
		if ( $in_weight < 1.00 ) {
			# Minimum one pound for USPS.
			$in_weight = 1.00;
		}
		
		my ( $pounds, $ounces ) = $self->weight_to_imperial( $in_weight );
		
		$self->pounds( $pounds ) if $pounds;
		$self->ounces( $ounces ) if $ounces;
	}
	
	my $out_weight = $self->imperial_to_weight( $self->pounds(), $self->ounces() );
	
	# Convert back to 'weight' (i.e. one number) when returning.
	return $out_weight;
}

sub weight_to_imperial
{
	my ( $self, $in_weight ) = @_;
	
	my $pounds = $self->_round_up( $in_weight );
	my $remainder = $in_weight - $pounds;
	
	my $ounces;
	if ( $remainder ) {
		$ounces = $remainder * 16;
		$ounces = sprintf( "%1.0f", $ounces );
	}
	
	return ( $pounds, $ounces );
}

sub imperial_to_weight
{
	my ( $self, $pounds, $ounces ) = @_;
	
	my $fractional_pounds = sprintf( "%1.0f", $self->ounces() / 16 );
	
	return ( $pounds + $fractional_pounds );
}

sub _round_up
{
	my ( $self, $f ) = @_;
	return undef unless defined $f; 
	return sprintf( "%1.0f", $f );
}


1;
