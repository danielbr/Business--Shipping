=head1 NAME

Business::Shipping::USPS_Online::RateRequest 

=head1 VERSION

$Rev$

=head1 SERVICE TYPES

=head2 Domestic

    EXPRESS
    Priority
    Parcel
    Library
    BPM
    Media

=head2 International
 
    'Global Express Guaranteed Document Service',
    'Global Express Guaranteed Non-Document Service',
    'Global Express Mail (EMS)',
    'Global Priority Mail - Flat-rate Envelope (large)',
    'Global Priority Mail - Flat-rate Envelope (small)',
    'Global Priority Mail - Variable Weight Envelope (single)',
    'Airmail Letter Post',
    'Airmail Parcel Post',
    'Economy (Surface) Letter Post',
    'Economy (Surface) Parcel Post',

=head1 METHODS

=cut

package Business::Shipping::USPS_Online::RateRequest;

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };

use strict;
use warnings;
use base( 'Business::Shipping::RateRequest::Online' );
use Business::Shipping::Logging;
use Business::Shipping::USPS_Online::Shipment;
use Business::Shipping::USPS_Online::Package;
use XML::Simple 2.05;
use XML::DOM;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;

=head2 domestic

=cut

use Class::MethodMaker 2.0
    [
      new    => [ { -hash => 1 }, 'new' ],
      scalar => [ { -default => 1 }, 'domestic' ],
      scalar => [ { -default => 'http://production.shippingapis.com/ShippingAPI.dll'  }, 'prod_url' ],
      scalar => [ { -default => 'http://testing.shippingapis.com/ShippingAPItest.dll' }, 'test_url' ],
      scalar => [ { -type    => 'Business::Shipping::USPS_Online::Shipment',
                    -default_ctor => 'default_new',
                    -forward => [ 
                                  'from_city',
                                  'to_city',
                                  'ounces',
                                  'pounds',
                                  'weight',
                                  'container',
                                  'size',
                                  'machinable',
                                  'mail_type',
                                ],
                   },
                   'shipment'
                 ],
      scalar => [ { -static => 1, 
                    -default => "shipment=>Business::Shipping::USPS_Online::Shipment" 
                  }, 
                  'Has_a' 
               ],
      scalar => [ { -static => 1, -default => 'zone_file, zone_name' }, 'Optional' ],
      scalar => [ { -static => 1 }, 'Zones' ],      
    ];

=head2 _gen_request_xml

Generate the XML document.

=cut

sub _gen_request_xml
{
    trace '()';
    my $self = shift;
    
    # Note: The XML::Simple hash-tree-based generation method wont work with USPS,
    # because they enforce the order of their parameters (unlike UPS).
    #
    my $rateReqDoc = XML::DOM::Document->new(); 
    my $rateReqEl = $rateReqDoc->createElement( 
        $self->domestic() ? 'RateV2Request' : 'IntlRateRequest' 
    );
    
    $rateReqEl->setAttribute('USERID', $self->user_id() ); 
    $rateReqEl->setAttribute('PASSWORD', $self->password() ); 
    $rateReqDoc->appendChild($rateReqEl);
    
    my $package_count = 0;
    
    logdie "No packages defined internally." unless ref $self->shipment->packages();
    foreach my $package ( @{ $self->shipment->packages() } ) {

        my $id;
        $id = $package->id();
        $id = $package_count++ unless $id;
        my $packageEl = $rateReqDoc->createElement('Package'); 
        $packageEl->setAttribute('ID', $id); 
        $rateReqEl->appendChild($packageEl); 

        if ( $self->domestic() ) {
            my $serviceEl = $rateReqDoc->createElement('Service'); 
            my $serviceText = $rateReqDoc->createTextNode( $self->shipment->service() ); 
            $serviceEl->appendChild($serviceText); 
            $packageEl->appendChild($serviceEl);
        
            my $zipOrigEl = $rateReqDoc->createElement('ZipOrigination'); 
            my $zipOrigText = $rateReqDoc->createTextNode( $self->shipment->from_zip()); 
            $zipOrigEl->appendChild($zipOrigText); 
            $packageEl->appendChild($zipOrigEl); 
            
            my $zipDestEl = $rateReqDoc->createElement('ZipDestination');
            my $zipDestText = $rateReqDoc->createTextNode( $self->shipment->to_zip()); 
            $zipDestEl->appendChild($zipDestText); 
            $packageEl->appendChild($zipDestEl); 
        }
        
        my $poundsEl = $rateReqDoc->createElement('Pounds'); 
        my $poundsText = $rateReqDoc->createTextNode( $package->pounds() );
        $poundsEl->appendChild($poundsText); 
        $packageEl->appendChild($poundsEl); 
        
        my $ouncesEl = $rateReqDoc->createElement('Ounces'); 
        my $ouncesText = $rateReqDoc->createTextNode( $package->ounces() ); 
        $ouncesEl->appendChild($ouncesText); 
        $packageEl->appendChild($ouncesEl);
        
        if ( $self->domestic() ) {
            my $containerEl = $rateReqDoc->createElement('Container'); 
            my $containerText = $rateReqDoc->createTextNode( $package->container() ); 
            $containerEl->appendChild($containerText); 
            $packageEl->appendChild($containerEl); 
            
            my $oversizeEl = $rateReqDoc->createElement('Size'); 
            my $oversizeText = $rateReqDoc->createTextNode( $package->size() ); 
            $oversizeEl->appendChild($oversizeText); 
            $packageEl->appendChild($oversizeEl); 
            
	    if( defined( $package->machinable() ) )
	    {
		my $machineEl = $rateReqDoc->createElement('Machinable'); 
		my $machineText = $rateReqDoc->createTextNode( $package->machinable() ); 
		$machineEl->appendChild($machineText); 
		$packageEl->appendChild($machineEl);
	    }
        }
        else {
            my $mailTypeEl = $rateReqDoc->createElement('MailType'); 
            my $mailTypeText = $rateReqDoc->createTextNode( $package->mail_type() ); 
            $mailTypeEl->appendChild($mailTypeText); 
            $packageEl->appendChild($mailTypeEl); 
            
            my $countryEl = $rateReqDoc->createElement('Country'); 
            my $countryText = $rateReqDoc->createTextNode( $self->shipment->to_country() ); 
            $countryEl->appendChild($countryText); 
            $packageEl->appendChild($countryEl);
        }
    
    } #/foreach package
    my $request_xml = $rateReqDoc->toString();
    
    # We only do this to provide a pretty, formatted XML doc for the debug. 
    my $request_xml_tree = XML::Simple::XMLin( $request_xml, KeepRoot => 1, ForceArray => 1 );
    
    # Large debug
    debug3( XML::Simple::XMLout( $request_xml_tree, KeepRoot => 1 ) );
    
    return ( $request_xml );
}

=head2 _gen_request

=cut

sub _gen_request
{
    my ( $self ) = shift;
    trace( 'called' );
    
    my $request = $self->SUPER::_gen_request();
    # This is how USPS slightly varies from Business::Shipping
    my $new_content = 'API=' . ( $self->domestic() ? 'RateV2' : 'IntlRate' ) . '&XML=' . $request->content();
    $request->content( $new_content );
    $request->header( 'content-length' => length( $request->content() ) );

    # Large debug
    debug3( 'HTTP Request: ' . $request->as_string() );
    
    return ( $request );
}

=head2 _massage_values

=cut

sub _massage_values
{
    my $self = shift;
    
    $self->_domestic_or_intl();
    
    # Round up if United States... international can have less than 1 pound.
    if ( $self->to_country() and $self->to_country() =~ /(USA?)|(United States)/ ) {
        foreach my $package ( @{ $self->shipment->packages() } ) {
            $package->weight( 1 ) if ( $package->weight and $package->weight < 1 );
        }
    }
    
    return;
}

=head2 _handle_response

=cut

sub _handle_response
{
    trace '()';
    my $self = shift;
    
    my $response_tree = XML::Simple::XMLin( 
        $self->response()->content(), 
        ForceArray => 0, 
        KeepRoot => 0 
    );
    
    # TODO: Handle multiple packages errors.
    # (this doesn't seem to handle multiple packagess errors very well)
    if ( $response_tree->{Error} or $response_tree->{Package}->{Error} ) {
        my $error = $response_tree->{Package}->{Error};
        $error ||= $response_tree->{Error};
        my $error_number         = $error->{Number};
        my $error_source         = $error->{Source};
        my $error_description    = $error->{Description};
        $self->user_error( "$error_source: $error_description ($error_number)" );
        return( undef );
    }
    
    #
    # This is a "large" debug.
    #
    debug3( 'response = ' . $self->response->content );
    #
    
    my $charges;
    my @services_results = ();    
    
    #
    # TODO: Get the pricing routines to work for multi-packages (not just
    # the default_package()
    #
    if ( $self->domestic() ) {
        #
        # Domestic *does* tell you the price of all services if you ask for service "ALL"
        # If you ask for a specific service, it still might send more then one price.  
        # For example if you ask for "Flat Rate Box" service, it will send you two prices,
        # one for 'Priority Mail Flat Rate Box (11.25" x 8.75" x 6")' and the other for
        # 'Priority Mail Flat Rate Box (14" x 12" x 3.5")'
        #
        
        $charges = $response_tree->{ Package }->{ Postage };

	if( defined($charges) )
	{
	    $charges = [ $charges ] if( ref $charges ne 'ARRAY' );
	    foreach my $chg (@$charges)
	    {
		next if( ref $chg ne 'HASH' );
		my $service_hash = {
		    code       => undef,
		    nick       => undef,
		    name       => $chg->{MailService},
		    deliv_days => undef,
		    deliv_date => undef,
		    charges    => $chg->{Rate},
		    charges_formatted    => Business::Shipping::Util::currency( {}, $chg->{Rate} ),
		    deliv_date_formatted => undef,
		};
		push( @services_results, $service_hash );
	    }
	}
    }
    else {
        #
        # International *does* tell you the price of all services for each package
        #
        
        foreach my $service ( @{ $response_tree->{ Package }->{ Service } } ) {
            debug( "Trying to find a matching service by service description..." );
            debug( "Charges for $service->{SvcDescription} service = " . $service->{Postage} );
            
            # BUG: you can't check if the service descriptions match, because many countries use
            # different descriptions for the same service.  So we try to match by description
            # *or* by mail_type.  (There are probably many services with the same mail_type, how 
            # do we handle those?  We could just get them based on index number (maybe all "zero" 
            # is the cheapest ground service, or...?
            
            #
            # TODO: Try searching all of them for a service that matches.  Perhaps we should
            # have a "matching" variable for each service.  Like, "Air" for "Airmail Parcel Post",
            # so that whichever service has "Air" in the description will be used first.
            #
            
            if ( $self->service() and $self->service() =~ $service->{ SvcDescription } ) {
                $charges = $service->{ 'Postage' };
            }
        }
        if ( ! $charges ) {
            # Couldn't find it by service description, try by mail_type...
            foreach my $service ( @{ $response_tree->{Package}->{Service} } ) {
                debug( "Trying to find a matching service by mail_type..." );
                if    (    $self->mail_type()    and $self->mail_type()    =~ $service->{ MailType }    ) {
                    $charges = $service->{ Postage };
                }
            }
            # Still can't find the right service...
            if ( ! $charges ) {
                my $error_msg = "The requested service (" . ( $self->service() || 'none entered by user' )
                        . ") did not match any services that was available for that country.";
                
                print STDERR $error_msg;
                $self->user_error( $error_msg );
            }
        }
	
	if( defined($charges) )
	{
	    my $service_hash = {
		    code       => undef,
		    nick       => undef,
		    name       => undef,
		    deliv_days => undef,
		    deliv_date => undef,
		    charges    => $charges,
		    charges_formatted    => Business::Shipping::Util::currency( {}, $charges ),
		    deliv_date_formatted => undef,
		};
	    push( @services_results, $service_hash );
	}
    }
    
    if ( ! $charges ) { 
        $self->user_error( 'charges are 0, error out' ); 
        return $self->is_success( 0 );
    }
    debug( 'Setting charges to ' . $charges );
    
    my $results = [
        {
            name  => $self->shipper() || 'USPS_Online', 
            rates => \@services_results,
        }
    ];
    
    $self->results( $results );
    
    trace 'returning success';
    return $self->is_success( 1 );
}

=head2 _domestic_or_intl

Decide if we are domestic or international for this run.

=cut

sub _domestic_or_intl
{
    my $self = shift;
    trace '()';
    
    if ( $self->shipment->to_country() and $self->shipment->to_country() !~ /(US)|(United States)/) {
        $self->domestic( 0 );
    }
    else {
        $self->domestic( 1 );
    }
    debug( $self->domestic() ? 'Domestic' : 'International' );
    return;
}

=head2 to_residential()

For compatibility with UPS modules.  Always returns 0.

=cut

sub to_residential { return 0; }

1;

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut
