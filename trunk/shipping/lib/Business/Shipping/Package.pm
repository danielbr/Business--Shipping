# Business::Shipping::Package - Abstract class
# 
# $Id: Package.pm,v 1.4 2004/01/21 22:39:52 db-ship Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Package;

$VERSION = do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping' );

use Business::Shipping::CustomMethodMaker
	new_hash_init => 'new',
	grouped_fields_inherit => [
		required => [ 'weight' ],
		optional => [ 'id', 'charges' ],
		unique => [ 'weight' ],
	];

sub set_price
{
	my ( $self, $service, $price ) = @_;
	$self->{'price'}->{$service} = $price;
	return $self->{'price'}->{$service};	
}

sub get_charges
{
	my ( $self, $service ) = @_;	
	return $self->{ 'price' }->{ $service };	
}

sub is_empty
{
	my $self = shift;
	
#	for ( keys %options_defaults ) {
#		if (	$self->$_() 
#				and $options_defaults{ $_ }
#				and $self->$_() ne $options_defaults{ $_ } ) {
#			return 0;
#		}
#	}		
	
	return 1;
}

1;
