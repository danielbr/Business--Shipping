# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#
# $Id: UPS.pm,v 1.1 2003/06/04 21:41:08 db-ship Exp $

package Business::Shipping::UPS;
use strict;
use warnings;

=head1 NAME

Business::Shipping::UPS - see Business::Shipping.

=head1 METHODS

The following methods are available:

=over 4

=cut

use vars qw( @ISA $VERSION );
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Shipping;
use Business::Shipping::UPS::Package;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use XML::Simple 2.05;
use Carp;

@ISA = qw( Business::Shipping );

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

=cut

sub new
{
	my($class, %args) = @_;	
	my $self = $class->SUPER::new();
	bless( $self, $class );
	return $self->initialize( %args );
}

sub _metadata
{
	my ( $self, $desired ) = @_;
	
	my $values = { 
		'internal' => {
			'ua'					=> LWP::UserAgent->new(),
			'xs'					=> XML::Simple->new( ForceArray => 1, KeepRoot => 1 ),
			'packages'				=> [ Business::Shipping::UPS::Package->new() ],
			'package_subclass_name'	=> 'UPS::Package',
		},
		'required' => {
			user_id			=> undef,
			password		=> undef,
			access_key		=> undef,
			pickup_type		=> undef,
			from_country	=> 'US',  # (to|from)_country are required, but they have defaults, so...?
			from_zip		=> undef,
			to_residential	=> undef,
			to_country		=> 'US',
			to_zip			=> undef,
			service			=> undef,
		},
		'optional' => {
			from_city				=> undef,
			to_city					=> undef,
			test_server				=> undef,
			no_ssl					=> undef,
		},
		'parent_defaults' => {
			test_url				=> 'https://wwwcie.ups.com/ups.app/xml/Rate',
			prod_url				=> 'https://www.ups.com/ups.app/xml/Rate',
		},
		# TODO: automatically pull in the values from Ship::UPS::Package, map whatever is used.
		'alias_to_default_package' => {
			weight					=> undef,
			packaging				=> undef,
		},
		'unique_values' => {
			pickup_type				=> undef,
			from_country			=> undef,
			from_zip				=> undef,
			to_residential			=> undef,
			to_country				=> undef,
			to_zip					=> undef,
			service					=> undef,
		},
	};
	
	my %result = %{ $values->{ $desired } };
	return wantarray ? keys( %result ) : \%result;
}

=item pickup_type()

pickup_type can be one of the following:

 * 'Daily Pickup'
 * 'Cusomter Counter'
 * 'One Time Pickup'
 * 'On Call Air'
 * 'Letter Center'
 * 'Air Service Center'

=cut
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

sub _gen_unique_values
{
	my ( $self ) = @_;
	
	my @unique_values = $self->SUPER::_gen_unique_values();
	push @unique_values, $self->_metadata( 'unique_values' );
	
	return @unique_values;
}
sub _massage_values
{
	# TODO: Value massaging (see ups-query.tag )
	my ( $self ) = @_;
	
	# Translate service values.
	
	# Is the passed mode alpha ('1DA') or numeric ('02')?
	my $alpha = 1 unless ( $self->service() =~ /\d\d/ );
	
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
	unless ( $self->packaging() ) {
		if ( $alpha and $default_package_map{ $self->service() } ) {
			$self->packaging( $default_package_map{ $self->service() } );
		} else {
			$self->packaging( '02' );
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
	$self->service( $mode_map{ $self->service() } )		if $alpha;
	
	# Default values for residential addresses.
	unless ( $self->to_residential() ) {
		$self->to_residential( 1 )		if $self->service() == $mode_map{ 'GNDRES' };
		$self->to_residential( 0 )		if $self->service() == $mode_map{ 'GNDCOM' };
	}
	
	# UPS requires weight is at least 0.1 pounds.
	foreach my $package ( @{ $self->packages() } ) {
		$package->weight( 0.1 )			if ( $package->weight() < 0.1 );
	}

	# In the U.S., UPS only wants the 5-digit base ZIP code, not ZIP+4
	$self->to_country( 'US' ) unless $self->to_country();
	$self->to_country() eq 'US' and $self->to_zip() =~ /^(\d{5})/ and $self->to_zip( $1 );
	
	# UPS prefers 'GB' instead of 'UK'
	$self->to_country( 'GB' ) if $self->to_country() eq 'UK';

	return;
}

# _gen_request_xml()
# Generate the XML document.
sub _gen_request_xml
{
	my ( $self ) = shift;

	die "No packages defined internally." unless ref $self->packages();
	foreach my $package ( @{$self->packages()} ) {
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
				'ResidentialAddress' => [ $self->to_residential() ],
				'CountryCode' => [ $self->to_country() ],
				'PostalCode' => [ $self->to_zip() ],
			} ],
		} ],
		'Service' => [ {
			'Code' => [ $self->service() ],
		} ],
		'ShipmentServiceSelfOptions' => { },
	);
	
	my @packages;
	foreach my $package ( @{$self->packages()} ) {
		# TODO: Move to a different XML generation scheme, since all the packages 
		# in a multi-package shipment will have the name "Package" 
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
		. $self->{xs}->XMLout( $access_tree );

	#use Data::Dumper;
	#print Dumper ( $request_tree );
	my $request_xml = $access_xml . "\n" . '<?xml version="1.0"?>' . "\n"
		. $self->{xs}->XMLout( $request_tree );
	
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
=pod
old
sub _gen_url
{
	my ( $self ) = shift;
	my $protocol = $self->{opt}->{no_ssl} 	? 'http://' : 'https://';
	my $host = $self->{opt}->{test_server}	? 'wwwcie' : 'www';
	my $url = $protocol . $host . '.ups.com/ups.app/xml/Rate';
	return( $url );
}
=cut


=item $ups->run_query( [%args] )

This method sets some values (optional), generates the request, then parses and
the results and assigns the total_charges amount.

=cut

=pod
sub submit 
{
	my ( $self, %args ) = @_;
	
	$self->set( %args ) if ( %args );
	$self->validate() or return ( undef );

	my $request = $self->_gen_request();
	my $response = $self->{'ua'}->request( $request );
	$self->debug( "response content = " . $response->content );
	unless ( $response->content ) {
		$self->error( 'Repsonse empty.  HTTP response code:' . $response->code );
		return ( undef );
	}
	
	# I get "Out of Memory" errors unless I disable KeepRoot in XML::Simple::XMLin()
	my $response_tree = $self->{xs}->XMLin( $response->content, ForceArray => 0, KeepRoot => 0 );
	my $status_code = $response_tree->{Response}->{ResponseStatusCode};
	my $status_description = $response_tree->{Response}->{ResponseStatusDescription};
	my $error = $response_tree->{Response}->{Error}->{ErrorDescription};
	if ( $error and $error !~ /Success/ ) {
		$self->error( "$status_description ($status_code): $error" );
		return ( undef );
	}
	$self->{'total_charges'} = $response_tree->{RatedShipment}->{TotalCharges}->{MonetaryValue}; 
	return ( 1 );
}
=cut

sub _handle_response
{
	my ( $self ) = @_;
	$self->trace( 'called.' );
	
	my $response_tree = $self->{xs}->XMLin( 
		$self->response()->content(), 
		ForceArray => 0, 
		KeepRoot => 0 
	);
	
	my $status_code = $response_tree->{Response}->{ResponseStatusCode};
	my $status_description = $response_tree->{Response}->{ResponseStatusDescription};
	my $error = $response_tree->{Response}->{Error}->{ErrorDescription};
	if ( $error and $error !~ /Success/ ) {
		$self->error( "$status_description ($status_code): $error" );
		return ( undef );
	}
	
	$self->total_charges( $response_tree->{RatedShipment}->{TotalCharges}->{MonetaryValue} );
	# for each RatedPackage
		# set price package->id(?)

	
	
	return ( 1 );
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

1;

