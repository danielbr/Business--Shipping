# Business::Shipping::Shipment::USPS
# 
# $Id: USPS.pm,v 1.6 2003/12/22 03:49:06 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Shipment::USPS;

use strict;
use warnings;

use vars qw( $VERSION );
$VERSION = do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
use base ( 'Business::Shipping::Shipment' );

use Business::Shipping::Debug;
use Business::Shipping::Package;


# Nothing is unique about USPS, when it comes to Shipment.
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

#
# These methods automatically override the ones provided for us in 
# Shipping::Shipment by the MethodMaker module.
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
		#debug ( "setting country to \'$new_to_country\'" );
		$self->SUPER::to_country( $new_to_country );
	} 
	#debug ( "to_country now is " . ( $self->SUPER::to_country() || '' ) );
	return $self->SUPER::to_country();
}

#
# TODO: Separate code from data.
#
# Translate common usages (Great Britain) into the USPS proper name
# (Great Britain and Northern Ireland).
#
sub _country_name_translator
{
	my ( $self, $country ) = @_;
	
	return if ( ! $country );
	
	my %country_translator = (
		'American Samoa' => 'US Possession',  # Note: Requires Zip Code.
		'Bosnia And Herzegowina' => 'Bosnia-Herzegovina',  # note spelling
		'Bosnia And Herzegovina' => 'Bosnia-Herzegovina',  
		'Cocos (Keeling) Islands' => 'Australia',
		'Cook Islands' => 'New Zealand',
		'Corsica' => 'France',
		'Cote d` Ivoire (Ivory Coast)' => 'Cote d lvoire (Ivory Coast)',
		'East Timor' => 'Indonesia',
		'Falkland Islands (Malvinas)' => 'Falkland Islands',
		'France (Includes Monaco)' => 'France',
		'France, Metropolitan' => 'France',
		'French Polynesia (Tahiti)' => 'French Polynesia',
		'Georgia' => 'Georgia, Republic of',
		'Great Britain' => 'Great Britain and Northern Ireland',
		'Holy See (Vatican City State)' => 'Vatican City',
		'Ireland (Eire)' => 'Ireland',
		'Macedonia' => 'Macedonia, Republic of',
		'Madeira Islands' => 'Portugal',
		'Marshall Islands' => 'US Possession',
		'Mayotte' => 'France',
		'Micronesia, Federated States Of' => 'US Possession',
		'Moldova, Republic Of' => 'Moldova',
		'Monaco' => 'France',
		'Niue' => 'New Zealand',
		'Norfolk Island' => 'Australia',
		'Northern Mariana Islands' => 'US Possession',
		'Palau' => 'US Possession',
		'Pitcairn' => 'Pitcairn Island',
		'Puerto Rico' => 'US Possession',
		'Russian Federation' => 'Russia',
		'Saint Kitts And Nevis' => 'St. Christopher and Nevis',
		'South Georgia And The South Sand' => 'Falkland Islands',
		'South Korea' => 'Korea, Republic of (South Korea)',
		'Tahiti' => 'French Polynesia',
		'Tokelau' => 'Western Samoa',
		'United Kingdom' => 'Great Britain and Northern Ireland',
		'Virgin Islands (U.S.)' => 'US Possession',
		'Wallis and Furuna Islands' => 'Wallis and Futuna Islands',    #misspelling
		'Yugoslavia' => 'Serbia-Montenegro',
		'Zaire' => 'Congo, Democratic Republic of the',		
	);
	if ( $country_translator{ $country } ) {
		return $country_translator{ $country };
	}
	else {
		return $country;
	}
}

1;