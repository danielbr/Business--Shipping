# Business::Shipping::Shipment::USPS
# 
# $Id: USPS.pm,v 1.7 2004/01/21 22:39:54 db-ship Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Shipment::USPS;

=head1 DESCRIPTION

Shipping::Shipment::USPS is not very unique, just a few modifications to to_zip
and to_country.

=head1 TODO

Move the country translator data into configuration.

=over 4 METHODS

=cut

$VERSION = do { my @r=(q$Revision: 1.7 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping::Shipment' );
use Business::Shipping::Debug;
use Business::Shipping::Config;
use Business::Shipping::Package;
use Business::Shipping::CustomMethodMaker
	new_with_init => 'new',
	new_hash_init => 'hash_init';

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

sub from_country { return 'US'; }

=item * to_zip( $to_zip )

Overrides Shipping::Shipment::to_zip() to throw away the "four" from zip+four.

=cut
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

=item * to_country( $to_country ) 

Uses the name translaters of Shipping::Shipment::to_country(), then applies its
own translations.  The former may not be necessary, but the latter is.

=cut
sub to_country
{
	trace '( ' . uneval( \@_ ) . ' )';
	my ( $self, $to_country ) = @_;	
	
	if ( defined $to_country ) {
		#
		# Apply any Shipping::Shipment conversions, then apply our own.
		#
		$to_country = $self->SUPER::to_country( $to_country );
		my $countries = $self->config_to_hash(
			cfg()->{ usps_information }->{ usps_country_name_translations }
		);
		$to_country = $countries->{ $to_country } || $to_country; 
		
		debug3( "setting to_country to \'$to_country\'" );
		$self->{ to_country } = $to_country;
	} 
	debug3( "SUPER::to_country now is " . ( $self->SUPER::to_country() || '' ) );
	
	return $self->{ to_country };
}

1;