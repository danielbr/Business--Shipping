# Copyright (c) 2003 Kavod Technologies, Dan Browning.
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: UPS.pm,v 1.12 2003/05/25 00:10:05 db-ship Exp $
package Business::Ship::UPS;
use strict;
use warnings;

=head1 NAME

Business::Ship::UPS - A UPS module

=head1 SYNOPSIS

		access_license_number => '248B43N8NXN1S35J',
		
		user_id => 'youruserid',
		password => 'yourpassword',
		
		pickup_type_code => '06',
			pickup_type => 'DAILY',
		
		shipper_countrycode => 'US',
			from_country => 'United States' (or 'US', it does translation.)
		
		shipper_postalcode => '98682',
			from_zip
		
		ship_to_residential_address => '1',
			to_residential
		
		ship_to_country_code => 'US',
			to_country
		
		ship_to_postal_code => '98270',
			to_zip
			
		service_code => '01',
			service
		
		packaging_type_code =>  '02',
			packaging_type	=>	'TUBE'
			
		weight => '3.4',
	);
	my $total_charges = $ups->get_total_charges();

=head1 TODO

Need to make pickup_type codes:

01 Daily Pickup 
03 Customer Counter 
06 One Time Pickup 
07 On Call Air 
19 Letter Center 
20 Air Service Center

=head1 DESCRIPTION

In normal use, the application creates a C<Business::Ship::UPS> object, and then
configures it with values for user id, password, access key, etc.  The query is
run via the run_query() method, and the total_charges can be accessed via the
get_total_charges() method.

Note that you can set variables in the run_query() method, as used in the 
example, or via the new() constructor, or via the set() method.

=head1 ERROR/DEBUG HANDLING

The 'event_handler_error' and 'event_handler_debug' arguments tell the 
Business::Ship::UPS object how to handle error and debug conditions.  Each can
be one of four options:

 * 'STDERR'
 * 'STDOUT'
 * 'carp'
 * 'croak'
 
The default is 'STDERR' for error handling, and nothing for debug handling.
Note that you can still access error messages even with no handler, by accessing
the return values of methods.  For example:

	$usp->run_query() or print $ups->error();  

=head1 INSTALLATION

You will also need to get a User Id, Password, and Access Key from UPS.
 
 * Read about it online:
 
http://www.ec.ups.com/ecommerce/gettools/gtools_intro.html 
 
 * Sign up here:
 
https://www.ups.com/servlet/registration?loc=en_US_EC
 
 * When you recieve your information from UPS, you can enter into IC
   via catalog variables.  You can add these to your products/variables.txt
   file, like the following example, or you can add them using the Admin UI.

=head1 METHODS

The following methods are available:

=over 4

=cut

use vars qw( @ISA $VERSION );
use Business::Ship;
use Business::Ship::UPS::Package;
$VERSION = sprintf("%d.%03d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use XML::Simple 2.05;
use Carp;

@ISA = qw( Business::Ship );

=item B<new>

$ups = new Business::Ship::UPS( %options );

This class method constructs a new C<Business:Ship::UPS> object and
returns a reference to it.

Key/value pair arguments may be provided to set up the initial state
of the Business::Ship::UPS object.

Required Arguments:

	access_license_number
	user_id
	password
	pickup_type_code
	shipper_country_code
	shipper_postal_code
	ship_to_residential_address
	ship_to_country_code
	ship_to_postal_code
	service_code
	packaging_type_code
	weight

Optional Arguments:

	shipper_city
	ship_to_city
	test_server
	no_ssl
	event_handler_debug
	event_handler_error

=for testing

	$ups = new Business::Ship::UPS();
	ok( defined $ups,						'new Business::Ship::UPS' );
	ok( $ups->isa('Business::Ship::UPS'),   '  and it is the right class' );

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
			'packages'				=> [ Business::Ship::UPS::Package->new() ],
			'package_subclass_name'	=> 'UPS::Package',
		},
		'required' => {
			user_id			=> undef,
			password		=> undef,
			license			=> undef,
			pickup_type		=> undef,
			from_country	=> 'US',
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
			prod_url				=> 'https://www.ups.com/ups.app/xml/Rat',
		},
		# TODO: automatically pull in the values from Ship::UPS::Package, map whatever is used.
		'alias_to_default_package' => {
			weight					=> undef,
			packaging				=> undef,
		},
		'unique_values' => {
			pickup_type				=> undef,
		},
	};
	
	my %result = %{ $values->{ $desired } };
	return wantarray ? keys( %result ) : \%result;
}

sub package_subclass_name { return 'UPS::Package'; }

sub _gen_unique_values
{
	my ( $self ) = @_;
	
	return ( $self->_metadata( 'unique_values' ) );
	
=pod
	##NOTE: This is from Business::Ship::USPS... perhaps consolidate them both.
	
	# Nothing unique at this level either, try the USPS::Package level...
	my @unique_values;
	foreach my $package ( @{$self->packages()} ) {
		push @unique_values, $package->get_unique_values()
	}
	
	# We prefer 0 in the key to represent 'undef'
	# clean it all up...
	my @new_unique_values;
	foreach my $value ( @unique_values ) {
		if ( not defined $value ) {
			$value = 0;
		}
		push @new_unique_values, $value;
	}

=cut
	
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
	$self->to_country() eq 'US' and $self->to_zip() =~ /^(\d{5})/ and $self->to_zip( $1 );
	
	# UPS prefers 'GB' instead of 'UK'
	$self->to_country( 'GB' ) if $self->to_country() eq 'UK';

	return;
}

sub validate
{
	my ( $self ) = shift;
=pod
	# TODO: implement required_options() function, and use in new()
	# Find missing arguments
	my @missing_args;
	for ( @{$self->{required_options}} ) {
		push( @missing_args, $_ )
			unless $self->{opt}->{$_};
	}

    if ( @missing_args ) {
        $self->error( "Missing required arguments: @missing_args" );
        return ( undef );
    }
    else {
        return 1;
    }
=cut
	return 1;
}
	
# _gen_request_xml()
# Generate the XML document.
sub _gen_request_xml
{
	my ( $self ) = shift;

	die "No packages defined internally." unless ref $self->packages();
	foreach my $package ( @{$self->packages()} ) {
		print "package $package\n";
	}
		
	my $access_tree = {
		'AccessRequest' => [
			{
				'xml:lang' => 'en-US',
				'AccessLicenseNumber' => [ $self->license() ],
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
				'Code' => [ $self->pickup_type() ]
			} ],
			'Shipment' => [ {
				%shipment_tree
			} ]
		} ]
	};

	my $access_xml = '<?xml version="1.0"?>' . "\n" 
		. $self->{xs}->XMLout( $access_tree );

	my $request_xml = $access_xml . "\n" . '<?xml version="1.0"?>' . "\n"
		. $self->{xs}->XMLout( $request_tree );

	$self->debug( "request xml = \n" . $request_xml );
	
	return ( $request_xml );
}


sub _gen_request
{
	my ( $self ) = shift;
	
	my $request_xml = $self->_gen_request_xml();
	my $request = new HTTP::Request 'POST', $self->_gen_url();
	
	$request->header( 'content-type' => 'application/x-www-form-urlencoded' );
	$request->header( 'content-length' => length( $request_xml ) );
	$request->content( $request_xml );
	
	return ( $request );
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

=head1 AUTHOR

	Dan Browning
	Kavod Technologies
	<db@kavod.com>
	http://www.kavod.com

=head1 COPYRIGHT

	Copyright (c) 2003 Kavod Technologies, Dan Browning.
	All rights reserved. This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

	UPS is a registered trademark of United Parcel Service. 

=cut

1;

