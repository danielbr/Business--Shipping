# Business::Shipping::Shipment::UPS
# 
# $Id: UPS.pm,v 1.1 2003/07/07 21:38:03 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Shipment::UPS;

use strict;
use warnings;

use vars qw( @ISA $VERSION );
@ISA = ( 'Business::Shipping::Shipment' );
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Shipping::Debug;
use Business::Shipping::Package;

use Class::MethodMaker
	new_with_init => 'new',
	new_hash_init => 'hash_init',
    grouped_fields => [
		optional => [
			'to_residential'
		],
	];

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