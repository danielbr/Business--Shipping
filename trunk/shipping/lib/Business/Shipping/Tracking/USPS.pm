# Business::Shipping::Tracking::USPS - Abstract class for tracking shipments
# 
# $Id: USPS.pm,v 1.2 2004/03/03 04:07:52 danb Exp $
# 
# Copyright (c) 2004 InfoGears Inc.  All Rights Reserved.
# Portions Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public License (GPL).  See COPYING for more info.
# 

=head1 NAME

Business::Tracking::USPS - A USPS module for Tracking Packages

See Tracking.pm POD for usage information.

=head2 EXAMPLE

my $results = $tracker->results();

# The results hash will contain this type of information

{
  # Summary will contain the latest activity entry, a copy of activity->[0]
  summary => { },
  # Activity of the package in transit, newest entries first.
  activity => [
  {
    # Address information of the activity 
    address => {
       city => '...',
       state => '...',
       zip => '...',
       country => '...',
       signedforbyname => '...',
    },

    # Description of activity
    status_description => '...',
    
    # Date of activity (YYYYMMDD)
    date => '...',
    # Time of activity (HHMMSS)
    time => '...',
  }
 
  ],
}

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004 InfoGears Inc. L<http://www.infogears.com>  All rights reserved.

Portions Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 

Licensed under the GNU Public License (GPL).  See COPYING for more info.

=cut

package Business::Shipping::Tracking::USPS;

$VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base( 'Business::Shipping::Tracking' );
use Business::Shipping::Debug;
use XML::Simple 2.05;
use XML::DOM;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use Clone;
use Business::Shipping::CustomMethodMaker
  new_with_init => 'new',
  new_hash_init => 'hash_init';

use constant INSTANCE_DEFAULTS => (
    'prod_url'        => 'http://production.shippingapis.com/ShippingAPI.dll',
    'test_url'        => 'http://testing.shippingapis.com/ShippingAPItest.dll',
);
 
sub init
{
    #trace '( ' . uneval( @_ ) . ' )';
    my $self           = shift;
    my %values         = ( INSTANCE_DEFAULTS, @_ );
    
    $self->hash_init( %values );
    return;
}

# _gen_request_xml()
# Generate the XML document.
sub _gen_request_xml
{
    trace '()';
    my $self = shift;
    
    if(!grep { !$self->results_exists($_) } @{$self->tracking_ids}) {
      # All results were found in the cache
      return;
    }

    # Note: The XML::Simple hash-tree-based generation method wont work with USPS,
    # because they enforce the order of their parameters (unlike UPS).
    #
    my $trackReqDoc = XML::DOM::Document->new(); 

    my $trackReqEl = $trackReqDoc->createElement('TrackFieldRequest'); 

    
    
    $trackReqEl->setAttribute('USERID', $self->user_id() ); 
    $trackReqEl->setAttribute('PASSWORD', $self->password() ); 
    $trackReqDoc->appendChild($trackReqEl);


    # Could already have some responses cached so don't pull them from the server.

    foreach my $tracking_id (grep { !$self->results_exists($_) } @{$self->tracking_ids}) {
      my $trackIDEl = $trackReqDoc->createElement("TrackID");
      $trackIDEl->setAttribute('ID', $tracking_id);
      $trackReqEl->appendChild($trackIDEl);
    }
    
    my $request_xml = $trackReqDoc->toString();
    
    # We only do this to provide a pretty, formatted XML doc for the debug. 
    my $request_xml_tree = XML::Simple::XMLin( $request_xml, KeepRoot => 1, ForceArray => 1 );
    
    #
    # Large debug
    #
    debug3( XML::Simple::XMLout( $request_xml_tree, KeepRoot => 1 ) );
    #
    
    return ( $request_xml );
}

sub _gen_url
{
    trace '()';
    my ( $self ) = shift;
    
    return( $self->test_mode() ? $self->test_url() : $self->prod_url() );
}


sub _gen_request
{
    my ( $self ) = shift;
    trace( 'called' );

    my $request_xml = $self->_gen_request_xml();
    if(!$request_xml) {
      return undef;
    }
    my $request = HTTP::Request->new('POST', $self->_gen_url());

    $request->header( 'content-type' => 'application/x-www-form-urlencoded' );
    $request->header( 'content-length' => length( $request_xml ) );

    # This is how USPS slightly varies from Business::Shipping
    my $new_content = 'API=TrackV2' . '&XML=' . $request_xml;
    $request->content( $new_content );
    $request->header( 'content-length' => length( $request->content() ) );
    #
    # Large debug
    #
    debug( 'HTTP Request: ' . $request->as_string() );
    #
    return ( $request );
}


sub cleanup_xml_hash($) {
  my $hash_ref = shift;

  map { $hash_ref->{$_} = undef; } grep { ref($hash_ref->{$_}) eq 'HASH' && scalar(keys %{$hash_ref->{$_}}) == 0 } keys %$hash_ref;
}

sub _handle_response
{
    trace '()';
    my $self = shift;
    
    my $response_tree = XML::Simple::XMLin( 
        $self->response()->content(), 
        ForceArray => 0, 
        KeepRoot => 1, 
    );
    
    # TODO: Handle multiple packages errors.
    # (this doesn't seem to handle multiple packagess errors very well)
    if ( $response_tree->{Error} ) {
        my $error = $response_tree->{Error};
        my $error_number         = $error->{Number};
        my $error_source         = $error->{Source};
        my $error_description    = $error->{Description};
        $self->error( "$error_source: $error_description ($error_number)" );
        return( undef );
    }
    
    #
    # This is a "large" debug.
    #
    debug3( 'response = ' . $self->response->content );
    #

    $response_tree = $response_tree->{TrackResponse};

    my $results;

    foreach my $trackInfo (
                   ((ref($response_tree->{TrackInfo}) eq 'ARRAY') ? (@{$response_tree->{TrackInfo}}) : $response_tree->{TrackInfo})
                  ) {
      my $id = $trackInfo->{'ID'};


      
      if(exists($trackInfo->{'Error'})) {
        $self->results({$id => {
                    error => 1,
                    error_description => $trackInfo->{Error}->{Description},
                    error_source => $trackInfo->{Error}->{Source},
                       }});
      } else {
        cleanup_xml_hash($trackInfo->{TrackSummary});


        my @activity_array;

        
        
        
        if(ref($trackInfo->{TrackDetail}) eq 'ARRAY') {
          @activity_array = @{$trackInfo->{TrackDetail}};
        } else {
          @activity_array = ($trackInfo->{TrackDetail});
        }

        if(exists($trackInfo->{TrackSummary})) {
          unshift @activity_array, $trackInfo->{TrackSummary};
        }
        
        my $i = 1;
        my %month_name_hash = map { ($_ => sprintf("%0.2d", $i++)) } qw(January February March April May June July August September October November December);
        
        my @activity_entries;

        foreach my $activity (@activity_array) {
          my $date = $activity->{EventDate};
          
          $date =~ s/([A-z]+)\s+(\d+),\s+(\d+)/$3 . $month_name_hash{$1} . sprintf("%0.2d", $2)/e;
          

          my $time = $activity->{EventTime};
          
          $time =~ s/(\d+):(\d+)\s+(am|pm)/
        my $h = $1;
        if($3 eq 'pm') {
          $h += 12;
        }
          sprintf("%0.2d", $h) . $2 . "00"/e;

          my $activity_hash = {
                   address => {
                           zip => $activity->{EventZIPCode},
                           state => $activity->{EventState},
                           country => $activity->{EventCountry},
                           city => $activity->{EventCity},
                           signedforbyname => $activity->{Name},
                           company => $activity->{FirmName},
                          },
                   date => $date,
                   status_description => $activity->{Event},
                   time => $time,
                  };
          
          push @activity_entries, $activity_hash;
          
        }
        

        my $summary;
        if(scalar(@activity_entries) > 0) {
          $summary = Clone::clone($activity_entries[0]);
        }

        my $result = {
              (($summary) ? (summary => $summary) : ()),
              activity => \@activity_entries,
             };


        Business::Shipping::Tracking::_delete_undefined_keys($result);

        
        
        $self->results({$id => $result});
      }
    }

    trace 'returning success';
    return $self->is_success( 1 );
}

sub gen_unique_key {
  my $self = shift;
  my $id = shift;

  return 'Tracking:USPS:' . $id;
}



1;

