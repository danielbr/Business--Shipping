# Copyright (c) 2003 Kavod Technologies, Dan Browning, 
# and Kevin Old.  
# All rights reserved. This program is free software; you can 
# redistribute it and/or modify it under the same terms as Perl 
# itself.

package Business::Ship::USPS;
use strict;
use warnings;

=head1 NAME

Business::Ship::USPS - A USPS module

=head1 SYNOPSIS

	use Business::Ship::USPS;
	my $ups = new Business::Ship::USPS;
	$ups->run_query(
		access_license_number => '248B43N8NXN1S35J',
		user_id => 'youruserid',
		password => 'yourpassword',
		pickup_type_Code => '06',
		shipper_countrycode => 'US',
		shipper_postalcode => '98682',
		ship_to_residential_address => '1',
		ship_to_country_code => 'US',
		ship_to_postal_code => '98270',
		service_code => '01',
		packaging_type_ode =>  '02',
		weight => '3.4',
	);
	my $total_charges = $ups->get_total_charges();

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

=head1 METHODS

The following methods are available:

=over 4

=cut

use vars qw($VERSION);
$VERSION = sprintf("%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use XML::Simple 2.05;
use Carp;

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
	my($class, %arg) = @_;
	
	my @required_options = qw/
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
	/;
	my @optional_options = qw/
		shipper_city
		ship_to_city
		test_server
		no_ssl
		event_handler_debug
		event_handler_error
	/;
	my @all_options = ( @required_options, @optional_options );
	my $xs = new XML::Simple( ForceArray => 1, KeepRoot => 1 );
	my $ua = new LWP::UserAgent;
	my %opt;
	my @errors;
	my %event_handlers = ( 'error' => 'STDERR' );

	my $self = bless { 
		'required_options' => \@required_options,
		'optional_options' => \@optional_options,
		'all_options' => \@all_options,
		'xs' => $xs,
		'ua' => $ua,
		'opt' => \%opt,
		'errors' => \@errors,
		'event_handlers' => \%event_handlers,
		}, $class;
	
	$self->set( %arg );
	
	return $self;
}

=item $ups->set( %args )

This method assigns internal options.

=cut

sub set
{
	my ( $self, %arg ) = @_;
	
	$self->{'event_handlers'}->{'debug'} = delete $arg{'event_handler_debug'} if $arg{'event_handler_debug'};
	$self->{'event_handlers'}->{'error'} = delete $arg{'event_handler_error'} if $arg{'event_handler_error'};
	
	# Set valid args and find unrecongnized ones.
	for ( @{$self->{all_options}} ) {
		$self->{opt}->{$_} = delete $arg{$_} if exists $arg{$_};
	}
	
	if ( %arg ) {
		$self->error( "Unrecognized options: @{[sort keys %arg]}" );
		return ( undef );
	}
	else {
		return ( 1 );
	}
}


sub validate
{
	my ( $self ) = shift;
	
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
}
	
# _gen_request_xml()
# Generate the XML document.
sub _gen_request_xml
{
	my ( $self ) = shift;

	my $access_tree = {
		'AccessRequest' => [
			{
				'xml:lang' => 'en-US',
				'AccessLicenseNumber' => [ $self->{opt}->{access_license_number} ],
				'UserId' => [ $self->{opt}->{user_id} ],
				'Password' => [ $self->{opt}->{password} ],
			}
		]
	};
	
	# 'Shipment' will be embedded in the $request_tree
	# It was broken out to reduce nesting.
	my %shipment_tree = (
		'Shipper' => [ {
			'Address' => [ {
				'CountryCode' => [ $self->{opt}->{shipper_country_code} ],
				'PostalCode' => [ $self->{opt}->{shipper_postal_code} ],
			} ],
		} ],
		'ShipTo' => [ {
			'Address' => [ {
				'ResidentialAddress' => [ $self->{opt}->{ship_to_residential_address} ],
				'CountryCode' => [ $self->{opt}->{ship_to_country_code} ],
				'PostalCode' => [ $self->{opt}->{ship_to_postal_code} ],
			} ],
		} ],
		'Service' => [ {
			'Code' => [ $self->{opt}->{service_code} ],
		} ],
		'Package' => [ {
			'PackagingType' => [ {
				'Code' => [ $self->{opt}->{packaging_type_code} ],
				'Description' => [ 'Package' ],
			} ],
			'Description' => [ 'Rate Lookup' ],
			'PackageWeight' => [ {
				'Weight' => [ $self->{opt}->{weight} ],
			} ],
		} ],
		'ShipmentServiceSelfOptions' => { },
	);
	
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
				'Code' => [ $self->{opt}->{pickup_type_code} ]
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


=item $ups->get_total_charges()

This method returns the total charges.

=cut

sub get_total_charges
{
	my ( $self ) = shift;
	return $self->{'total_charges'} if $self->{'total_charges'};
	return 0;
}

sub _gen_url
{
	my ( $self ) = shift;
	my $protocol = $self->{opt}->{no_ssl} 	? 'http://' : 'https://';
	my $host = $self->{opt}->{test_server}	? 'wwwcie' : 'www';
	my $url = $protocol . $host . '.ups.com/ups.app/xml/Rate';
	return( $url );
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

=item $ups->run_query( [%args] )

This method sets some values (optional), generates the request, then parses and
the results and assigns the total_charges amount.

=cut
	
sub run_query 
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

=item $ups->clone;

Returns a copy of the Business::Ship::UPS object

=cut

sub clone
{
	my $self = shift;
	my $copy = bless { %$self }, ref $self;
	
	# Refs have special handling
	$copy->{'opt'} = { %{$self->{'opt'}} };
	
	return $copy;
}

sub debug {
    my ( $self, $msg ) = @_;
    return $self->_log( 'debug', $msg );
}

sub error {
    my ( $self, $msg ) = @_;
	
	# Return the most recent error message if that is all they want
	return ( pop @{$self->{'errors'}} ) unless ( $msg );
	
	$msg .= "\n" unless ( $msg =~ /\n$/ );
    return $self->_log( 'error', $msg );
}

sub _log
{
    my $self = shift;
    my ( $type, $msg ) = @_;
	my( $package, $filename, $line, $sub ) = caller(2);
	$msg  = "$sub: $msg";
	if ( $type eq 'error' ) {
		push @{$self->{'errors'}}, $msg;
	}
	
	foreach my $eh ( keys %{$self->{'event_handlers'}} ) {
		my $eh_value = $self->{'event_handlers'}->{$eh};
		if ( $type eq $eh and $eh_value ) {
			print STDERR $msg if $eh_value eq "STDERR";
			print STDOUT $msg if $eh_value eq "STDOUT";
			Carp::carp   $msg if $eh_value eq "carp";
			Carp::croak  $msg if $eh_value eq "croak";
		}
	}
	
	return ( $msg );
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

Copyright (c) 2003 Kavod Technologies and Dan Browning. 
All rights reserved. This program is free software; you can 
redistribute it and/or modify it under the same terms as Perl 
itself.

UPS is a registered trademark of United Parcel Service. 

=cut

1;

