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

 * Register for the API here:
 
http://www.uspsprioritymail.com/et_regcert.html

=cut

use vars qw(@ISA $VERSION);
$VERSION = sprintf("%d.%03d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);
use Business::Ship;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use XML::Simple 2.05;
use XML::DOM;


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
		machinable	False
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

# _gen_request_xml()
# Generate the XML document.
sub _gen_request_xml
{
	my ( $self ) = shift;
	
	# Note: The XML::Simple hash-tree-based generation method wont work with USPS,
	# because they enforce the order of their parameters (unlike UPS).
	
	my $rateReqDoc = new XML::DOM::Document; 
	my $rateReqEl = $rateReqDoc->createElement('RateRequest'); 
	$rateReqEl->setAttribute('USERID', $self->user_id() ); 
	$rateReqEl->setAttribute('PASSWORD', $self->password() ); 
	$rateReqDoc->appendChild($rateReqEl); 
	my $packageEl = $rateReqDoc->createElement('Package'); 
	$packageEl->setAttribute('ID', '0'); 
	$rateReqEl->appendChild($packageEl); 
	my $serviceEl = $rateReqDoc->createElement('Service'); 
	my $serviceText = $rateReqDoc->createTextNode( $self->service() ); 
	$serviceEl->appendChild($serviceText); 
	$packageEl->appendChild($serviceEl); 
	my $zipOrigEl = $rateReqDoc->createElement('ZipOrigination'); 
	my $zipOrigText = $rateReqDoc->createTextNode( $self->from_zip()); 
	$zipOrigEl->appendChild($zipOrigText); 
	$packageEl->appendChild($zipOrigEl); 
	my $zipDestEl = $rateReqDoc->createElement('ZipDestination'); 
	my $zipDestText = $rateReqDoc->createTextNode( $self->to_zip()); 
	$zipDestEl->appendChild($zipDestText); 
	$packageEl->appendChild($zipDestEl); 
	my $poundsEl = $rateReqDoc->createElement('Pounds'); 
	my $poundsText = $rateReqDoc->createTextNode( $self->pounds() );
	$poundsEl->appendChild($poundsText); 
	$packageEl->appendChild($poundsEl); 
	my $ouncesEl = $rateReqDoc->createElement('Ounces'); 
	my $ouncesText = $rateReqDoc->createTextNode( $self->ounces() ); 
	$ouncesEl->appendChild($ouncesText); 
	$packageEl->appendChild($ouncesEl); 
	my $containerEl = $rateReqDoc->createElement('Container'); 
	my $containerText = $rateReqDoc->createTextNode( $self->container() ); 
	$containerEl->appendChild($containerText); 
	$packageEl->appendChild($containerEl); 
	my $oversizeEl = $rateReqDoc->createElement('Size'); 
	my $oversizeText = $rateReqDoc->createTextNode( $self->size() ); 
	$oversizeEl->appendChild($oversizeText); 
	$packageEl->appendChild($oversizeEl); 
	my $machineEl = $rateReqDoc->createElement('Machinable'); 
	my $machineText = $rateReqDoc->createTextNode( $self->machinable() ); 
	$machineEl->appendChild($machineText); 
	$packageEl->appendChild($machineEl); 
	
	my $request_xml = $rateReqDoc->toString();
	
	$self->debug( "request xml = \n" .  $request_xml );
	
	return ( $request_xml );
}

sub _gen_request
{
	my ( $self ) = shift;
	
	# The "API=Rate&XML=" is the only part that is different from UPS...
	my $request_xml = 'API=Rate&XML=';
	$request_xml .= $self->_gen_request_xml();

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
	
	$self->debug( "response content = " . $self->response()->content() );
	
	my $content;
	
	if ( $self->response()->is_success() ) { 
		 $content = $self->response->content; 
	}
	else { 
		$self->error( "HTTP Error.  Content = " . $content ); 
		return( undef ); 
	}	
	
	# I get "Out of Memory" errors unless I disable ForceArray in XML::Simple::XMLin()
	my $response_tree = $self->{xs}->XMLin( $self->response()->content(), ForceArray => 0, KeepRoot => 0 );
	
	# TODO: Handle multiple packages.
	if ( $response_tree->{Package}->{Error} ) {
		my $error_number 		= $response_tree->{Package}->{Error}->{Number};
		my $error_source 		= $response_tree->{Package}->{Error}->{Source};
		my $error_description	= $response_tree->{Package}->{Error}->{Description};
		$self->error( "$error_source: $error_description ($error_number)" );
		return( undef );
	}
	
	$self->total_charges( $response_tree->{Package}->{Postage} );	
	return $self->success( 1 );
}

sub build_subs
{
	my $self = shift;
	
	my @usps_required_vals = qw/
	/;
	
	my @usps_optional_vals = qw/
		ua
		xs
		container
		size
		machinable
		pounds
		ounces
	/;
	
	$self->SUPER::build_subs( @_, @usps_required_vals, @usps_optional_vals );
	
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
