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
$VERSION = sprintf("%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);
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
	|);
	
	$self->set( %default_values );
	$self->set( 'ua' => new LWP::UserAgent );
	$self->set( 'xs' => new XML::Simple(ForceArray => 1, KeepRoot => 1) );
		
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

=pod	
sub run_query 
{
	

	
	
	
}
=cut

sub submit
{
	my ( $self, %args ) = @_;
	
	#$self->validate() or return ( undef );
	
	my $request = $self->_gen_request();
	$self->response( $self->{'ua'}->request( $request ) );
	
	$self->debug( "response content = " . $self->response()->content );
	unless( $self->response()->content ) {
		$self->error( 'Repsonse empty.  HTTP response code:' . $self->response()->code() );
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
				'ZipOrigination' => [ '98682' ],
				'ZipDestination' => [ '98270' ],
				'Pounds' => [ '5' ],
				'Ounces' => [ '3' ],
				'Container' => [ 'NONE' ],
				'Size' => [ 'Regular' ],
				'Machineable' => [ 'False' ],
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
	/;
	
	$self->SUPER::build_subs( @_, @usps_required_vals, @usps_optional_vals );
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
