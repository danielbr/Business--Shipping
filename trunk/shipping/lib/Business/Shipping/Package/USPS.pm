# Business::Shipping::Package::USPS
# 
# $Id: USPS.pm,v 1.1 2003/07/07 21:37:59 db-ship Exp $
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
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Shipping::Debug;
use Class::MethodMaker
	new_with_init => 'new',
	new_hash_init => 'hash_init',
	grouped_fields => [
		optional => [ 'container', 'size', 'machinable', 'mail_type', 'pounds', 'ounces' ],
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
		
	return $self->pounds();
}

sub _round_up
{
	my ( $self, $f ) = @_;
	return undef unless defined $f; 
	return sprintf( "%1.0f", $f );
}


1;
