# Business::Shipping::Shipment::USPS
# 
# $Id: USPS.pm,v 1.3 2003/08/07 22:45:47 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Shipment::USPS;

use strict;
use warnings;

use vars qw( @ISA $VERSION );
@ISA = ( 'Business::Shipping::Shipment' );
$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Shipping::Debug;
use Business::Shipping::Package;


# Nothing is unique about USPS, when it comes to Shipment.
use Business::Shipping::CustomMethodMaker
	new_with_init => 'new',
	new_hash_init => 'hash_init';
	#
	# Here, we override the standard Shipping::Shipment::packages()
	# with our own, since we need to forward some stuff for USPS.
	#
	#object_list => [ 
	#	'Business::Shipping::Package::USPS' => {
	#		'slot'		=> 'packages',
	#		#'comp_mthds'	=> [ ]
	#	},
	#]
	#

use constant INSTANCE_DEFAULTS => (
	shipper => 'USPS',
	from_country => 'US',
);
 
sub init
{
	my $self   = shift;
	my %values = ( INSTANCE_DEFAULTS, @_ );
	$self->hash_init( %values );
	return;
}

#
# These methods should automatically override the ones provided for us in 
# Shipping::Shipment, by the MethodMaker module, right?
#
sub to_zip
{
	my $self = shift;
	
	if ( $_[ 0 ] ) {
		my $to_zip = shift;
		
		# Need to throw away the "plus four" of zip+four.
		$to_zip =~ /{\d,5}/ if $to_zip;
		
		$self->{ 'to_zip' } = $to_zip;
	}
	
	return $self->{ 'to_zip' };
}

sub from_country
{
	# USPS is always from US.
	return 'US';
}

sub to_country
{
	trace '( ' . uneval( @_ ) . ' )';
	my $self = shift;	
	if ( @_ ) {
		my $new_to_country = shift;
		$new_to_country = $self->_country_name_translator( $new_to_country );
		#$self->{ 'to_country' } = $new_to_country;
		#debug ( "setting country to \'$new_to_country\'" );
		$self->SUPER::to_country( $new_to_country );
	} 
	#debug ( "to_country now is " . ( $self->SUPER::to_country() || '' ) );
	return $self->SUPER::to_country();
}

#
# TODO: Move all of this, and any other data that is currently mixed with code.
# A simple, file-based configuration system would be nice, like Interchange.
# Perhaps XML::Simple Configuration files?  Other?  Shipping::Config module
# will provide parser, importer.  Any internal modules that use configuration
# will go through that module.  (it's an idea, anyway)  
#
# Translate common usages (Great Britain) into the USPS proper name
# (Great Britain and Northern Ireland).
sub _country_name_translator
{
	my ( $self, $country ) = @_;
	my %country_translator = (
		'Great Britain' => 'Great Britain and Northern Ireland',
		'United Kingdom' => 'Great Britain and Northern Ireland',
		'France, Metropolitan' => 'France',
	);
	if ( $country and $country_translator{ $country } ) {
		return $country_translator{ $country };
	}
	else {
		return $country;
	}
}

1;