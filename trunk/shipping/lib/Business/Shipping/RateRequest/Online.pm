# Business::Shipping::RateRequest::Online - Abstract class for shipping cost rating.
# 
# $Id: Online.pm,v 1.1 2003/07/07 21:38:01 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::RateRequest::Online;

use strict;
use warnings;

use vars qw( @ISA $VERSION );
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
@ISA = ( 'Business::Shipping::RateRequest' );

use Business::Shipping::Debug;
use XML::Simple;
use LWP::UserAgent;
use Class::MethodMaker
	new_hash_init => 'new',
	boolean => [ 'test_mode' ],
	grouped_fields => [
		required => [ 'user_id', 'password' ], 
		optional => [ 'prod_url', 'test_url' ],
	],
	object => [
		'LWP::UserAgent' => {
			slot => 'user_agent',
			#
		},
		'HTTP::Response' => {
			slot => 'response',
			#
		}
	];

sub find_required { trace( '()' ); 	return ( $_[0]->required(), $_[0]->SUPER::find_required() ); }

=item $shipment->submit( [%args] )

This method sets some values (optional), generates the request, then parses the
results.

=cut
sub submit
{
	my ( $self, %args ) = @_;
	trace( "( " . uneval( %args ) . " )" );
	$self->set( %args ) if %args;
	$self->_massage_values();
	$self->validate() or return ( undef );
	my $request = $self->_gen_request();
	trace( 'Please wait while we get a response from the server...' );
	$self->response( $self->_get_response( $request ) );
	
	#
	# Large debug
	#
	#debug( "response content = " . $self->response()->content() );
	#
	
	unless ( $self->response()->is_success() ) { 
		error( "HTTP Error. Status line: " . $self->response->status_line .
		"Content: " . $self->response->content() );
		return( undef ); 
	}
	return $self->_handle_response();
}

sub _gen_url
{
	trace( '()' );
	my ( $self ) = shift;
	
	return( $self->test_mode() ? $self->test_url() : $self->prod_url() );
}

sub _gen_request
{
	trace( '()' );
	my ( $self ) = shift;
	
	my $request_xml = $self->_gen_request_xml();
	
	###
	#  This is one of the *big* xml requests.
	###
	#debug( $request_xml );
	
	my $request = HTTP::Request->new( 'POST', $self->_gen_url() );
	
	$request->header( 'content-type' => 'application/x-www-form-urlencoded' );
	$request->header( 'content-length' => length( $request_xml ) );
	$request->content( $request_xml );
	
	return ( $request );
}

# This was pulled into Business::Shipping because it's likely that both
# shippers will benefit from a similar cache structure.
#
# Caches responses for speed.  Not all API users will be able to extract all
# of the pakage rates for each service at once, they will have to do it twice. 
# This helps a lot.
#
sub _get_response
{
	trace( '()' );
	my $self = shift;
	my $request = shift;
	
	
	if ( $self->cache() ) {
		my @unique_values = $self->_gen_unique_values();
		my $key = join( "|", @unique_values );
		my $response = $self->cache()->get( $key );
		if ( not defined $response ) {
			#trace( "unique_values = " . uneval( @unique_values ) );
			trace( "running request manually, then add to cache." );
			$response = $self->{'ua'}->request( $request );
			#TODO: Allow setting of cache properties (time limit, enable/disable, etc.)
			$self->cache()->set( $key, $response, "2 days" ); 
		}
		else {
			trace( "using cached response." );
		}
		return $response;
	}
	else {
		trace( 'cache disabled. Sending request...' );
		#debug( "sending this request: " . Dumper( $request ) );
		return $self->user_agent->request( $request );
	}	
}


1;