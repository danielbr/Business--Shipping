# Business::Shipping::RateRequest::Online - Abstract class for shipping cost rating.
# 
# $Id: Online.pm,v 1.3 2003/08/07 22:45:47 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::RateRequest::Online;

use strict;
use warnings;

use vars qw( @ISA $VERSION );
$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
@ISA = ( 'Business::Shipping::RateRequest' );

use Business::Shipping::Debug;
use XML::Simple;
use LWP::UserAgent;
use Cache::FileCache;
use Business::Shipping::CustomMethodMaker
	new_hash_init => 'new',
	boolean => [ 'test_mode' ],
	get_set => [ 'user_id', 'password' ],
	grouped_fields_inherit => [
		required => [ 'user_id', 'password' ],
		optional => [ 'prod_url', 'test_url' ],
		#unique => [ ] # nothing unique here.
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



sub perform_action
{
	my $self = shift;	
	my $request = $self->_gen_request();
	trace( 'Please wait while we get a response from the server...' );
	$self->response( $self->_get_response( $request ) );
	
	#
	# Large debug
	#
	#debug( "response content = " . $self->response()->content() );
	#
	
	if ( ! $self->response()->is_success() ) { 
		Business::Shipping::Debug::error( "HTTP Error. Status line: " . $self->response->status_line .
		"Content: " . $self->response->content() );
		return( undef ); 
	}
	# handle_response needs to set cache:
	# $self->shipment->packages->[0]->charges( $total_charges );
	
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
	
	# TODO: Finish cache.
	debug( 'cache disabled for now' );
	#$self->cache( 0 );
	
	#if ( $self->cache() and 0 ) {
	if ( 0 ) {
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