# Business::Shipping::Tracking - Abstract class
# 
# $Id$
# 
# Copyright (c) 2004-2007 Infogears Inc.  All rights reserved.
# Portions Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights 
# reserved. 
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Tracking;

=head1 NAME

Business::Shipping::Tracking

=head1 SYNOPSIS

=head2 Example tracking request for USPS:

use Business::Shipping::USPS_Online::Tracking;

my $tracker = Business::Shipping::USPS_Online::Tracking->new();

$tracker->init(
test_mode => 1,
);

$tracker->tracking_ids('EJ958083578US', 'EJ958083578US');

$tracker->submit() || logdie $tracker->user_error();
my $hash = $tracker->results();

use Data::Dumper;
print Data::Dumper->Dump([$hash]);

=head1 ABSTRACT

Business::Tracking is an API for tracking shipments

=cut


$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };

use strict;
use warnings;
use base ( 'Business::Shipping' );
use Data::Dumper;
use Business::Shipping::Logging;
use Business::Shipping::Config;
use Cache::FileCache;

use Class::MethodMaker 2.0
    [
      new    => [ { -hash => 1, -init => 'this_init' }, 'new' ],
      scalar => [ qw/ is_success cache invalid test_mode user_id password 
                      cache_time / ],
      hash   => [ { -static => 1 }, 'results' ],
      array  => [ 'tracking_ids' ],
      
      array  => [ { -type => 'Business::Shipping::Package' }, 'packages' ],
      scalar => [ { -static => 1, 
                    -default => 'userid, password' 
                  },
                  'Required' 
                ],
      scalar => [ { -static => 1, 
                    -default => 'prod_url, test_url' 
                  },
                  'Optional' 
                ],
      scalar => [ { -type => 'LWP::UserAgent',
                    -default_ctor => sub { LWP::UserAgent->new(); },
                  }, 'user_agent'
                ],
      scalar => [ { -type => 'HTTP::Response',
                    -default_ctor => 'new',
                  }, 'response'
                ],
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

L<Business::Shipping::UPS_Online::Tracking>
L<Business::Shipping::USPS_Online::Tracking>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004-2007 InfoGears Inc. L<http://www.infogears.com>  All rights reserved.

Portions Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut


sub submit
{
    my ( $self, %args ) = @_;
    trace( "( " . uneval( %args ) . " )" );
    
    
    $self->init( %args ) if %args;
    $self->validate() or return;

    
     my $cache = Cache::FileCache->new() if $self->cache();

    my $cache_results;
     if ( $self->cache() ) {
      trace( 'cache enabled' );    
      


      foreach my $id (@{$self->tracking_ids}) {
        my $key = $self->gen_unique_key($id);
        debug "cache key = $key\n";
        
        my $cache_result = $cache->get($key);
        
        if(defined($cache_result)) {
          $cache_results->{$id} = $cache_result;
        } else {
          trace( "Cache miss on id $id, running request manually, then add to cache." );
        }
      }
      # Save the results that we have.
      $self->results(%$cache_results);
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
        
	# Don't overwrite the result if it was pulled from the cache, otherwise the cache 
	# would never expire.
	if(exists($cache_results->{$id})) {
	  next;
	}
        my $value = $self->results_index($id);
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
