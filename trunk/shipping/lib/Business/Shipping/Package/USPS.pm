# Business::Shipping::Package::USPS
# 
# $Id: USPS.pm,v 1.2 2003/07/10 07:38:20 db-ship Exp $
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
$VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

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
	my $self = shift;
	
	#
	# TODO: Need to actually do a conversion from fractional pounds to ounces.
	#
	$self->pounds( $self->_round_up( shift ) ) if @_;
	$self->ounces( 0 );
	
	# Should convert back to 'weight' when returning, *I* think.
	
	return $self->pounds();
}

sub _round_up
{
	my ( $self, $f ) = @_;
	return undef unless defined $f; 
	return sprintf( "%1.0f", $f );
}


1;
