# Business::Shipping::Shipment::UPS
# 
# $Id: UPS.pm,v 1.5 2004/01/21 22:39:54 db-ship Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Shipment::UPS;

$VERSION = do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base( 'Business::Shipping::Shipment' );
use Business::Shipping::CustomMethodMaker
	new_with_init => 'new',
	new_hash_init => 'hash_init',
    grouped_fields_inherit => [
		optional => [ 'to_residential' ],
		unique => [ 'to_residential' ],
		required => [ 'from_zip' ],
	];

#
# Why is this 'shipper' default needed for Shipping::Shipment::UPS?
#
use constant INSTANCE_DEFAULTS => (
	shipper => 'UPS',
);
 
sub init
{
	my $self   = shift;
	my %values = ( INSTANCE_DEFAULTS, @_ );
	$self->hash_init( %values );
	return;
}

	
1;