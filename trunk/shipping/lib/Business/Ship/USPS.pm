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

Documentation forthcoming.

=cut

use vars qw(@ISA $VERSION);
$VERSION = sprintf("%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);
use Business::Ship;
use LWP::UserAgent ();
use HTTP::Request ();
use HTTP::Response ();
use XML::Simple ();


use Data::Dumper;

@ISA = qw( Business::Ship );

sub set_defaults
{
	my $self = shift;

	$self->SUPER::set_defaults();
	
	my %default_values = (qw|
		test_url	http://testing.shippingapis.com/ShippingAPItest.dll
		prod_url	http://production.shippingapis.com/ShippingAPI.dll
		test_mode	1
		container	NONE
		size		Regular
		machineable	False
		ounces		0
	|);
	
	$self->set( %default_values );
	$self->set( 'ua' => new LWP::UserAgent );
	$self->set( 'xs' => new XML::Simple(ForceArray => 1, KeepRoot => 1) );
	
	# NOTE!  I need to somehow convert weight to pounds/ounces.
	
    return;
}

sub _gen_url
{
	my ( $self ) = shift;
	return( $self->test_mode() ? $self->test_url() : $self->prod_url() );
}

sub _gen_request
{
	my ( $self ) = shift;
	
	# The "API=Rate&XML=" is the only part that is different from UPS...
	my $request_xml = 'API=Rate&XML=' . $self->_gen_request_xml();

	
=pod  This is an example of a working request
<RateRequest USERID="539KAVOD6731" PASSWORD="900QZ55LW201">
	<Package ID="0">
		<Service>BPM</Service>
		<ZipOrigination>29708</ZipOrigination>
		<ZipDestination>28278</ZipDestination>
		<Pounds>1</Pounds>
		<Ounces>0</Ounces>
		<Container>NONE</Container>
		<Size>Regular</Size>
		<Machinable>False</Machinable>
	</Package>
</RateRequest>
=cut

	$request_xml = qq{API=Rate&XML=
	<RateRequest USERID="539KAVOD6731" PASSWORD="900QZ55LW201">
		<Package ID="0">
			<Service>BPM</Service>
			<ZipOrigination>29708</ZipOrigination>
			<ZipDestination>28278</ZipDestination>
			<Pounds>1</Pounds>
			<Ounces>0</Ounces>
			<Container>NONE</Container>
			<Size>Regular</Size>
			<Machinable>False</Machinable>
		</Package>
	</RateRequest>
	};
	
	my $request = new HTTP::Request 'POST', $self->_gen_url();
	
	$request->header( 'content-type' => 'application/x-www-form-urlencoded' );
	$request->header( 'content-length' => length( $request_xml ) );
	
	$request->content(  $request_xml );
	
	return ( $request );
}


sub _massage_values
{
	my $self = shift;
	$self->_set_pounds_ounces();
	return;
}
	
=item $shipment->submit( [%args] )

This method sets some values (optional), generates the request, then parses and
the results and assigns the total_charges amount.

=cut

sub submit
{
	my ( $self, %args ) = @_;
	
	$self->set( %args ) if %args;
	
	$self->_massage_values();
	#$self->validate() or return ( undef );
	
	my $request = $self->_gen_request();
	$self->response( $self->{'ua'}->request( $request ) );
	
	$self->debug( "response content = " . $self->response()->content );
	unless( $self->response()->content() ) {
		$self->error( 'Repsonse empty.  HTTP response code:' . $self->response()->code() );
		return( undef );
	}
	
	if ( $self->response()->content() =~ /HTTP Error/ ) {
		$self->error( "HTTP Error.  Content = " . $self->response()->content() );
		return( undef );
	}
	
	# I get "Out of Memory" errors unless I disable KeepRoot in XML::Simple::XMLin()
	my $response_tree = $self->{xs}->XMLin( $self->response()->content(), ForceArray => 0, KeepRoot => 0 );
	my $status_code = $response_tree->{Response}->{ResponseStatusCode};
	my $status_description = $response_tree->{Response}->{ResponseStatusDescription};
	my $error = $response_tree->{Response}->{Error}->{ErrorDescription};
	if ( $error and $error !~ /Success/ ) {
		$self->error( "$status_description ($status_code): $error" );
		return ( undef );
	}
	
	$self->total_charges( $response_tree->{RatedShipment}->{TotalCharges}->{MonetaryValue} );	
	
	return $self->success( 1 );
}

# _gen_request_xml()
# Generate the XML document.
sub _gen_request_xml
{
	my ( $self ) = shift;

	my $request_tree = {
		'RateRequest' => [{
			'USERID' => $self->user_id(),
			'PASSWORD' => $self->password(),
			'Package' => [{
				'ID' => '0',
				'Service' => [ $self->service() ],
				'ZipOrigination' => [ $self->from_zip() ],
				'ZipDestination' => [ $self->to_zip() ],
				'Pounds' => [ $self->pounds() ],
				'Ounces' => [ $self->ounces() ],
				'Container' => [ $self->container() ],
				'Size' => [ $self->size() ],
				'Machineable' => [ $self->machineable() ],
			}]
		}]
	};

	my $request_xml = '<?xml version="1.0"?>' . "\n"
		. $self->{xs}->XMLout( $request_tree );

	$self->debug( "request xml = \n" . $request_xml );
	
	return ( $request_xml );
}

sub build_subs
{
	my $self = shift;
	
	my @usps_required_vals = qw/
		usps_custom1
		usps_custom2
	/;
	
	my @usps_optional_vals = qw/
		usps_custom3
		usps_custom4
		ua
		xs
		container
		size
		machineable
		pounds
		ounces
	/;
	
	$self->SUPER::build_subs( @_, @usps_required_vals, @usps_optional_vals );
	
	# build these sub	
}

sub _set_pounds_ounces
{
	my $self = shift;
	unless( $self->pounds() ) {
		$self->pounds( $self->weight() );
	}
	
	# Can pounds be a fraction?  Or do we need to calc the ounces?
}

=head1 SEE ALSO

	http://www.uspswebtools.com/

=head1 AUTHOR

	Initially developed by Kevin Old, later rewritten by Dan Browning.
	
	Dan Browning <db@kavod.com>
	Kavod Technologies
	http://www.kavod.com
	
	Kevin Old <kold@carolina.rr.com>

=head1 COPYRIGHT

Copyright (c) 2003 Kavod Technologies, Dan Browning,
and Kevin Old. 
All rights reserved. This program is free software; you can 
redistribute it and/or modify it under the same terms as Perl 
itself. 

=cut

1;
