# Business::Shipping::Shipment - Abstract class for shipments
# 
# $Id: Shipment.pm,v 1.2 2003/07/10 07:38:19 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Shipment;

use strict;
use warnings;

use vars qw( @ISA $VERSION );
@ISA = ( 'Business::Shipping' );
$VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Shipping::Debug( 'debug' );
use Business::Shipping::CustomMethodMaker
	new_hash_init => 'new',
	grouped_fields_inherit => [
		'required' => [
			'service',
			'from_zip',
			'shipper',	# *NEEDS* to be set, at least to some default.
		],
		'optional' => [ 
			'from_country',
			'to_country',
			'to_zip',
			'from_city',
			'to_city',						
		],
		'unique' => [
			'service',
			'from_zip',
			'from_country',
			'to_country',
			'to_zip',
			'from_city',
			'to_city',
		],
	],
	object_list => [ 
		'Business::Shipping::Package' => {
			'slot'		=> 'packages',
			#'comp_mthds'	=> [ ]
		},
	];

# Forward the weight to the default package.
sub weight { return shift->default_package->weight( @_ ); }

# Returns the weight of all packages within the shipment.
sub total_weight
{
	my $self = shift;
	
	my $total_weight;
	foreach my $package ( @{ $self->packages() } ) {
		$total_weight += $package->weight();
	}
	return $total_weight;
}

sub default_package {
	
	my $self = shift;
	
	if ( not defined $self->packages_index( 0 ) ) {
		debug( 'No default package defined yet, creating one...' );
		$self->packages_push( Business::Shipping::Package->new() );
	}
	
	$self->packages_index( 0 ); 
}

1;