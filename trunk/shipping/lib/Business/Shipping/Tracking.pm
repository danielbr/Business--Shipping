# Business::Shipping::Tracking - Abstract class
# 
# $Id: Tracking.pm,v 1.5 2004/05/06 20:15:26 danb Exp $
# 
# Copyright (c) 2004 Infogears Inc.  All rights reserved.
# Portions Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights 
# reserved. 
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Tracking;

=head1 NAME

Business::Shipping::Tracking - API for tracking packages

=head1 SYNOPSIS

=head2 Example tracking request for USPS:

use Business::Shipping::Tracking::USPS;

my $tracker = Business::Shipping::Tracking::USPS->new();

$tracker->init(

test_mode => 1,

tracking_ids => ['EJ958083578US', 'EJ958083578US'],

);

$tracker->submit() || die $tracker->user_error();
my $hash = $tracker->results();

use Data::Dumper;
print Data::Dumper->Dump([$hash]);

=head1 ABSTRACT

Business::Tracking is an API for tracking shipments

=cut


$VERSION = do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping' );
use Data::Dumper;
use Business::Shipping::Logging;
use Business::Shipping::Config;
use Cache::FileCache;

use Business::Shipping::CustomMethodMaker
  new_hash_init => 'new',
  boolean => [ 'is_success', 'cache', 'invalid' ],
  static_hash => ['results'],
  list => ['tracking_ids'],
  boolean => [ 'test_mode' ],
  get_set => [ 'user_id', 'password', 'cache_time' ],
  grouped_fields_inherit => [
                 required => [ 'user_id', 'password'],
                 optional => [ 'prod_url', 'test_url'],
                ],
  object => [
         'LWP::UserAgent' => {
                  slot => 'user_agent',
                 },
         'HTTP::Response' => {
                  slot => 'response',
                 }
        ];


sub _delete_undefined_keys($) {
  my $hash_ref = shift;
  
  map { 
    if(defined($hash_ref->{$_}) && ref($hash_ref->{$_}) eq 'HASH') {
      _delete_undefined_keys($hash_ref->{$_});
      if(scalar(keys %{$hash_ref->{$_}}) == 0) {
    delete $hash_ref->{$_};
      }
    } elsif(defined($hash_ref->{$_}) && ref($hash_ref->{$_}) eq 'ARRAY') {
      foreach my $element (@{$hash_ref->{$_}}) {
    if(ref($element) eq 'HASH') {
      _delete_undefined_keys($element);
    }
      }
    } elsif(!defined($hash_ref->{$_})) {
      delete $hash_ref->{$_};
    }
  } keys %$hash_ref;
}



=head1 SEE ALSO

L<Business::Shipping::Tracking::UPS>
L<Business::Shipping::Tracking::USPS>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004 InfoGears Inc. L<http://www.infogears.com>  All rights reserved.

Portions Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 

Licensed under the GNU Public License (GPL).  See COPYING for more info.

=cut


sub submit
{
    my ( $self, %args ) = @_;
    trace( "( " . uneval( %args ) . " )" );
    
    
    $self->init( %args ) if %args;
    $self->validate() or return;

    
     my $cache = Cache::FileCache->new() if $self->cache();
     if ( $self->cache() ) {
      trace( 'cache enabled' );    
      
      my $cache_results;

      foreach my $id (@{$self->tracking_ids}) {
        my $key = $self->gen_unique_key($id);
        debug "cache key = $key\n";
        
        my $cache_result = $cache->get($key);
        
        if(defined($cache_result)) {
          $cache_results->{$id} = $cache_result;
        } else {
          trace( 'Cache miss on id $id, running request manually, then add to cache.' );
        }
        $self->results($cache_results);
      }
    } else {
      trace( 'cache disabled' );
    }
    

    


    my @requests = $self->_gen_request();
    
    while(my $request = shift @requests) {
      trace( 'Please wait while we get a response from the server...' );
      $self->response( $self->_get_response( $request ) );
      debug3( "response content = " . $self->response()->content() );
      
      if ( ! $self->response()->is_success() ) { 
        #
        # If we're getting http errors we should bomb out.
        #
        $self->user_error(     
             "HTTP Error. Status line: " . $self->response->status_line .
             "Content: " . $self->response->content() 
            ); 
        $self->is_success(0);
        last;
      }
    
      # Only cache if there weren't any errors.

      $self->_handle_response();

      if(scalar(@requests) > 0) {
        # Sleep 2 seconds between requests, due to recommendation in USPS tracking document.
        # Seems to be prudent for other providers too.
        trace 'sleeping for 2 seconds';
        sleep 2;
      }
    }
       
    if ($self->cache() ) {    
      trace( 'cache enabled, saving results.' );
      #TODO: Allow setting of cache properties (time limit, enable/disable, etc.)
      
      my $new_cache = Cache::FileCache->new();
      
      foreach my $id ($self->results_keys) {
        my $key = $self->gen_unique_key($id);
        
        my $value = $self->results($id);
        
        $new_cache->set( $key, $value, ($self->cache_time() || "12 hours"));
      }
    }
    else {
      trace( 'cache disabled, not saving results.' );
    }
    
    


    $self->is_success(1);

    
    return $self->is_success();
}



sub validate
{
    my ( $self ) = @_;
    trace '()';
    
    
    if(scalar(@{$self->{tracking_ids}}) == 0) {
      $self->invalid( 1 );
      $self->user_error( "No tracking ids passed to track" );
      return 0;
    }

    if(!defined($self->user_id)) {
      $self->invalid( 1 );
      $self->user_error( "No user_id specified" );
      return 0;

    }

    if(!defined($self->password)) {
      $self->invalid( 1 );
      $self->user_error( "No password specified" );
      return 0;

    }

        
    return 1;
}

sub _get_response
{
    trace '()';
    return $_[0]->user_agent->request( $_[1] );
}


1;
__END__
