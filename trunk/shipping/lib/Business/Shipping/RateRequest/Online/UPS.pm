# Business::Shipping::RateRequest::Online::UPS - Abstract class for shipping cost rating.
# 
# $Id: UPS.pm,v 1.7 2003/10/13 18:25:14 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::RateRequest::Online::UPS;

use strict;
use warnings;

use vars qw( $VERSION );
$VERSION = do { my @r=(q$Revision: 1.7 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
#@ISA = ( 'Business::Shipping::RateRequest::Online' );
use base ( 'Business::Shipping::RateRequest::Online' );


use Business::Shipping::RateRequest::Online;
use Business::Shipping::Debug;
use Business::Shipping::Package::UPS;
use XML::Simple 2.05;
use Cache::FileCache;
use LWP::UserAgent;

use Business::Shipping::CustomMethodMaker
	new_with_init => 'new',
	new_hash_init => 'hash_init',
	#
	# Need to map 'to_residential'
	#
    #forward => {
	#	shipment => [ 'to_residential' ],
	#},
	#
	grouped_fields_inherit => [
		required => [ 'access_key' ],
		optional => [ 'test_server', 'no_ssl', 'to_city' ]
		# nothing unique here, either.
	];

sub to_residential { return shift->shipment->to_residential( @_ ); }
sub packaging { return shift->shipment->default_package->packaging( @_ ); }

use constant INSTANCE_DEFAULTS => (
	prod_url => 'https://www.ups.com/ups.app/xml/Rate', 
	test_url => 'https://wwwcie.ups.com/ups.app/xml/Rate',
);
 
sub init
{
	my $self   = shift;
	my %values = ( INSTANCE_DEFAULTS, @_ );
	$self->hash_init( %values );
	return;
}

sub pickup_type
{
	my ( $self ) = @_;
	$self->{ 'pickup_type' } = shift if @_;
	
	# Translate alphas to numeric.
	my $alpha = 1 if ( $self->{ 'pickup_type' } =~ /\w+/ );
	if ( $alpha ) { 
		my %pickup_type_map = (
			'daily pickup'			=> '01',
			'customer counter'		=> '03',
			'one time pickup'		=> '06', 
			'on call air'			=> '07', 
			'letter center'			=> '19', 
			'air service center'	=> '20',
		);
		$self->{ 'pickup_type' } = $pickup_type_map{ $self->{ 'pickup_type' } } 
			if $pickup_type_map{ $self->{ 'pickup_type' } }
			or $pickup_type_map{ lc( $self->{ 'pickup_type' } ) };
	}

	return $self->{ 'pickup_type' };
}

sub package_subclass_name { return 'UPS::Package'; }

sub _massage_values
{
	trace( 'called' );
	my ( $self ) = @_;
	
	# Translate service values.
	# Is the passed mode alpha ('1DA') or numeric ('02')?
	my $alpha = 1 unless ( $self->shipment->service =~ /\d\d/ );
	
	my %default_package_map = (
		qw/
		1DM	02
		1DML	01
		1DA	02
		1DAL	01
		2DM	02
		2DA	02
		2DML	01
		2DAL	01
		3DS	02
		GNDCOM	02
		GNDRES	02
		XPR	02
		UPSSTD	02
		XDM	02
		XPRL	01
		XDML	01
		XPD	02
		/
	);

	# Automatically assign a package type if none given, for backwards compatibility.
	if ( ! $self->shipment->default_package->packaging() ) {
		if ( $alpha and $default_package_map{ $self->service() } ) {
			$self->shipment->default_package->packaging( $default_package_map{ $self->shipment->service() } );
		} else {
			$self->shipment->default_package->packaging( '02' );
		}
	}
	
	my %mode_map = (
		qw/
			1DM	14
			1DML	14
			1DA	01
			1DAL	01
			2DM	59
			2DA	02
			2DML	59
			2DAL	02
			3DS	12
			GNDCOM	03
			GNDRES	03
			XPR	07
			XDM	54
			UPSSTD	11
			XPRL	07
			XDML	54
			XPD	08
		/
	);
	
	# Map names to codes for backward compatibility.
	$self->shipment->service( $mode_map{ $self->shipment->service } )		if $alpha;
	
	# Default values for residential addresses.
	unless ( $self->shipment->to_residential() ) {
		$self->shipment->to_residential( 1 )		if $self->shipment->service() == $mode_map{ 'GNDRES' };
		$self->shipment->to_residential( 0 )		if $self->shipment->service() == $mode_map{ 'GNDCOM' };
	}
	
	# UPS requires weight is at least 0.1 pounds.
	foreach my $package ( @{ $self->shipment->packages() } ) {
		$package->weight( 0.1 )			if ( ! $package->weight() or $package->weight() < 0.1 );
	}

	# In the U.S., UPS only wants the 5-digit base ZIP code, not ZIP+4
	$self->to_country( 'US' ) unless $self->to_country();
	if ( $self->to_zip() ) { 
		$self->to_zip() =~ /^(\d{5})/ and $self->to_zip( $1 );
	}
	
	# UPS prefers 'GB' instead of 'UK'
	$self->to_country( 'GB' ) if $self->to_country() eq 'UK';
	
	return;
}

# _gen_request_xml()
# Generate the XML document.
sub _gen_request_xml
{
	debug( 'called' );
	my ( $self ) = shift;

	die "No packages defined internally." unless ref $self->shipment->packages();
	foreach my $package ( @{$self->shipment->packages()} ) {
		#print "package $package\n";
	}
		
	my $access_tree = {
		'AccessRequest' => [
			{
				'xml:lang' => 'en-US',
				'AccessLicenseNumber' => [ $self->access_key() ],
				'UserId' => [ $self->user_id() ],
				'Password' => [ $self->password() ],
			}
		]
	};
	
	# 'Shipment' will be embedded in the $request_tree
	# It was broken out to reduce nesting.
	my %shipment_tree = (
		'Shipper' => [ {
			'Address' => [ {
				'CountryCode' => [ $self->from_country() ],
				'PostalCode' => [ $self->from_zip() ],
			} ],
		} ],
		'ShipTo' => [ {
			'Address' => [ {
				'ResidentialAddress' 	=> [ $self->to_residential() 	],
				'CountryCode' 			=> [ $self->to_country() 		],
				'PostalCode' 			=> [ $self->to_zip() 			],
				'City'					=> [ $self->to_city() 			],
			} ],
		} ],
		'Service' => [ {
			'Code' => [ $self->service() ],
		} ],
		'ShipmentServiceSelfOptions' => { },
	);
	
	my @packages;
	foreach my $package ( @{$self->packages()} ) {
		#
		# TODO: Move to a different XML generation scheme, since all the packages 
		# in a multi-package shipment will have the name "Package"
		#
		$shipment_tree{ 'Package' } = [ {
				'PackagingType' => [ {
					'Code' => [ $package->packaging() ],
					'Description' => [ 'Package' ],
				} ],
				
				'Description' => [ 'Rate Lookup' ],
				'PackageWeight' => [ {
					'Weight' => [ $package->weight() ],
				} ],
			} ],
	}
	
	my $request_tree = {
		'RatingServiceSelectionRequest' => [ { 
			'Request' => [ {
				'TransactionReference' => [ {
					'CustomerContext' => [ 'Rating and Service' ],
					'XpciVersion' => [ 1.0001 ],  
				} ],
				'RequestAction' => [ 'Rate' ],
			} ],
			'PickupType' => [ {
				'Code' => [ '01' ]
			} ],
			'Shipment' => [ {
				%shipment_tree
			} ]
		} ]
	};

	my $access_xml = '<?xml version="1.0"?>' . "\n" 
		. XML::Simple::XMLout( $access_tree, KeepRoot => 1 );

	#use Data::Dumper;
	#print Dumper ( $request_tree );
	
	my $request_xml = $access_xml . "\n" . '<?xml version="1.0"?>' . "\n"
		. XML::Simple::XMLout( $request_tree, KeepRoot => 1 );
	
	return ( $request_xml );
}



=item $ups->get_total_charges()

This method returns the total charges.

=cut
sub get_total_charges
{
	my ( $self ) = shift;
	return $self->{'total_charges'} if $self->{'total_charges'};
	return 0;
}


sub _handle_response
{
	trace( '()' );
	my ( $self ) = @_;
	
	my $response_tree = XML::Simple::XMLin( 
		$self->response()->content(), 
		ForceArray => 0, 
		KeepRoot => 0 
	);
	
	my $status_code = $response_tree->{Response}->{ResponseStatusCode};
	my $status_description = $response_tree->{Response}->{ResponseStatusDescription};
	my $error = $response_tree->{Response}->{Error}->{ErrorDescription};
	my $err_location = $response_tree->{Response}->{Error}->{ErrorLocation}->{ErrorLocationElementName} || '';
	if ( $error and $error !~ /Success/ ) {
		my $combined_error_msg = "$status_description ($status_code): $error @ $err_location"; 
		$combined_error_msg =~ s/\s{3,}/ /g;
		$self->error( $combined_error_msg );
		return ( undef );
	}
	
	my $total_charges = $response_tree->{RatedShipment}->{TotalCharges}->{MonetaryValue};
	if ( ! $total_charges ) {
		return $self->clear_is_success();
	}
	
	# This should never happen.
	for ( 'shipper', 'service' ) {
		if ( ! $self->shipment->$_() ) {
			$self->shipment->$_( 'Unknown' );
		}
	}
	
	#
	# 'return' method:
	# 1. Save a "results" hash.
	#
	# TODO: multi-package support: loop over the packages
	#
	my $packages = [
		{ 
			#description
			#package_id
			'charges' => $total_charges, 
		},
		#{
		#	#another package
		#	# 'charges' => ...
		#}
	];
	
	my $results = {
		$self->shipment->shipper() => $packages
	};
	debug3 'results = ' . uneval(  $results );
	$self->results( $results );
	
	return $self->is_success( 1 );
}


=back

=head1 SEE ALSO

	http://www.ec.ups.com

=head1 COPYRIGHT

	Copyright (c) 2003 Kavod Technologies, Dan Browning.
	All rights reserved. This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

	UPS is a registered trademark of United Parcel Service. 

=cut



=item B<new>

Required Arguments:

	user_id
	password
	
	access_key
	pickup_type
	from_country
	from_zip
	to_country
	to_zip
	to_residential
	service
	packaging
	weight
	
Optional Arguments:

	
	test_server
	no_ssl
	event_handlers
	
	from_city
	to_city

Services:

1DM		
1DML	
1DA		One Day Air
1DAL	
2DM	
2DA		Two Day Air
2DML	
2DAL	
3DS		Three Day Select	
GNDCOM	Ground Commercial
GNDRES	Ground Residential
XPR		UPS Worldwide Express
XDM		UPS Worldwide Express Plus
UPSSTD	UPS Standard
XPRL	UPS Worldwide Express Letter
XDML	UPS Worldwide Express Plus Letter
XPD		UPS Worldwide Expedited


=cut



1;

