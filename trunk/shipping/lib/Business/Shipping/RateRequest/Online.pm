# Business::Shipping::RateRequest::Online - Abstract class for shipping cost rating.
# 
# $Id: Online.pm,v 1.8 2004/03/08 17:13:56 danb Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::RateRequest::Online;

$VERSION = do { my @r=(q$Revision: 1.8 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping::RateRequest' );
use Business::Shipping::Debug;
use XML::Simple;
use LWP::UserAgent;
use Cache::FileCache;
use Class::MethodMaker 2.0
    [
      new    => [ { -hash => 1, -init => 'this_init' }, 'new' ],
      scalar => [ 'test_mode', 'user_id', 'password' ],
      scalar => [ { -static => 1, -default => 'user_id, password' }, 'Required' ],
      scalar => [ { -static => 1, -default => 'prod_url, test_url' }, 'Optional' ],
      scalar => [ 'response' ],
    ];

sub this_init {}

sub perform_action
{
    my $self = shift;    
    my $request = $self->_gen_request();
    trace( 'Please wait while we get a response from the server...' );
    $self->response( $self->_get_response( $request ) );
    #debug3( "response content = " . $self->response()->content() );
    
    if ( ! $self->response()->is_success() ) { 
        $self->error(     
                        "HTTP Error. Status line: " . $self->response->status_line .
                        "Content: " . $self->response->content() 
                    ); 
    }
    
    return ( undef );
}

sub _gen_url
{
    trace '()';
    my ( $self ) = shift;
    
    return( $self->test_mode() ? $self->test_url() : $self->prod_url() );
}

sub _gen_request
{
    trace '()';
    my ( $self ) = shift;
    
    my $request_xml = $self->_gen_request_xml();
    #debug3( $request_xml );
    my $request = HTTP::Request->new( 'POST', $self->_gen_url() );
    $request->header( 'content-type' => 'application/x-www-form-urlencoded' );
    $request->header( 'content-length' => length( $request_xml ) );
    $request->content( $request_xml );
    
    return ( $request );
}

sub _get_response
{
    my ( $self, $request_param ) = @_;
    trace 'called';

    my $ua = LWP::UserAgent->new; 
    my $response = $ua->request( $request_param );
    
    return $response;
}


1;