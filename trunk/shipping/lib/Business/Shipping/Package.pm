# Business::Shipping::Package - Abstract class for shipping cost rating.
# 
# $Id: Package.pm,v 1.2 2003/07/10 07:38:19 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Package;

use strict;
use warnings;

use vars qw( @ISA $VERSION );
@ISA = ( 'Business::Shipping' );
$VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Shipping;
use Data::Dumper;

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
