package Business::Shipping::UPS_Online::RateRequest;

=head1 NAME

Business::Shipping::UPS_Online::RateRequest

=head1 VERSION

Version $Rev$

=cut

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };

=head1 REQUIRED FIELDS

user_id
password
access_key

If user_id, password, and/or access_key are not defined, then the following 
shell environment variables will be used, if defiend:

UPS_USER_ID
UPS_PASSWORD
UPS_ACCESS_KEY

=head1 SERVICE TYPES

=head2 Domestic

    1DM        
    1DML    
    1DA        One Day Air
    1DAL    
    2DM    
    2DA        Two Day Air
    2DML    
    2DAL    
    3DS        Three Day Select    
    GNDCOM    Ground Commercial
    GNDRES    Ground Residential
    
=head2 International
 
    XPR        UPS Worldwide Express
    XDM        UPS Worldwide Express Plus
    UPSSTD    UPS Standard
    XPRL    UPS Worldwide Express Letter
    XDML    UPS Worldwide Express Plus Letter
    XPD        UPS Worldwide Expedited

=head1 ARGUMENTS

=head2 Required

    user_id
    password
    access_key
    pickup_type
    from_country
    from_zip
    to_country
    to_zip
    to_residential
    service
    packaging
    weight
    
=head2 Optional

    test_server
    no_ssl
    event_handlers
    from_city
    to_city

=head1 METHODS

=cut

use strict;
use warnings;
use base ( 'Business::Shipping::RateRequest::Online' );
use Business::Shipping::Logging;
use Business::Shipping::Config;
use Business::Shipping::UPS_Online::Package;
use Business::Shipping::UPS_Online::Shipment;
use Business::Shipping::Util;
use XML::Simple 2.05;
use Cache::FileCache;
use LWP::UserAgent;

=head2 access_key

=head2 test_server

=head2 no_ssl

=head2 to_city

=cut

use Class::MethodMaker 2.0
    [
      new => [ qw/ -hash new / ],
      scalar => [ 'access_key' ],
      scalar => [ { -static => 1, -default => 'access_key' }, 'Required' ],
      scalar => [ { -static => 1, -default => 'test_server, no_ssl, to_city' }, 'Optional' ],
      scalar => [ { -default => 'https://www.ups.com/ups.app/xml/Rate' }, 'prod_url' ],
      scalar => [ { -default => 'https://wwwcie.ups.com/ups.app/xml/Rate' }, 'test_url' ],      
      scalar => [ { -type    => 'Business::Shipping::UPS_Online::Shipment',
                    -default_ctor => 'new',
                    -forward => [ 
                                  'from_city',
                                  'to_city',
                                  'service', 
                                  'from_country',
                                  'from_country_abbrev',
                                  'to_country',
                                  'to_country_abbrev',
                                  'to_ak_or_hi',
                                  'from_zip',
                                  'to_zip',
                                  'packages',
                                  'weight',
                                  'shipper',
                                  'domestic',
                                  'intl',
                                  'domestic_or_ca',
                                  'from_canada',
                                  'to_canada',
                                  'from_ak_or_hi',
                                  'packaging',
                                  'to_residential',
                                ],
                   },
                   'shipment'
                 ],
      scalar => [ { -static => 1, 
                    -default => "shipment=>Business::Shipping::UPS_Online::Shipment" 
                  }, 
                  'Has_a' 
               ],
    ];

=head2 from_state()

Ignored.  For compatibility with UPS_Offline only.

=cut

sub from_state {}

=head2 pickup_type

=cut

sub pickup_type
{
    my ( $self ) = @_;
    $self->{ 'pickup_type' } = shift if @_;
    
    # Translate alphas to numeric.
    my $alpha = 1 if ( $self->{ 'pickup_type' } =~ /\w+/ );
    if ( $alpha ) { 
        my %pickup_type_map = (
            'daily pickup'       => '01',
            'customer counter'   => '03',
            'one time pickup'    => '06', 
            'on call air'        => '07', 
            'letter center'      => '19', 
            'air service center' => '20',
        );
        $self->{ 'pickup_type' } = $pickup_type_map{ $self->{ 'pickup_type' } } 
            if $pickup_type_map{ $self->{ 'pickup_type' } }
            or $pickup_type_map{ lc( $self->{ 'pickup_type' } ) };
    }

    return $self->{ 'pickup_type' };
}

=head2 _massage_values

=cut

sub _massage_values
{
    trace( 'called' );
    my ( $self ) = @_;
    
    # The following is only for online usage.
    # TODO: Move to UPS_Online/Shipment.pm
    # Translate service values.
    my %mode_map = (
        qw/
            1DM    14
            1DML    14
            1DA    01
            1DAL    01
            1DP    13
            2DM    59
            2DA    02
            2DML    59
            2DAL    02
            3DS    12
            GNDCOM    03
            GNDRES    03
            XPR    07
            XDM    54
            UPSSTD    11
            XPRL    07
            XDML    54
            XPD    08
        /
    );
    
    # Default values for residential addresses.
    if ( not $self->shipment->to_residential() ) {
        if ( $self->shipment->service =~ /(03|GNDRES)/ ) {
            $self->shipment->to_residential( 1 );
        }
        elsif ( $self->shipment->service eq 'GNDCOM' ) {
            $self->shipment->to_residential( 0 );
        }
    }

    my $service = $self->shipment->service;
    
    # Is the passed mode alpha ('1DA') or numeric ('02')?
    my $alpha = 1 unless ( $service =~ /\d\d/ );

    $service = $mode_map{ $service } if $alpha;

    $self->shipment->service( $service );
    
    $self->shipment->massage_values;
    return;
}

=head2 _gen_request_xml

Generate the XML document.

=cut

sub _gen_request_xml
{
    debug( 'called' );
    my ( $self ) = shift;

    logdie "No packages defined internally." unless ref $self->shipment->packages();
    foreach my $package ( @{$self->shipment->packages()} ) {
        #print "package $package\n";
    }
        
    my $access_tree = {
        'AccessRequest' => [
            {
                'xml:lang' => 'en-US',
                'AccessLicenseNumber' => [ $self->access_key() ],
                'UserId' => [ $self->user_id() ],
                'Password' => [ $self->password() ],
            }
        ]
    };
    
    # 'Shipment' will be embedded in the $request_tree
    # It was broken out to reduce nesting.
    my %shipment_tree = (
        'Shipper' => [ {
            'Address' => [ {
                'CountryCode' => [ $self->from_country_abbrev() ],
                'PostalCode' => [ $self->from_zip() ],
            } ],
        } ],
        'ShipTo' => [ {
            'Address' => [ {
                'ResidentialAddress'     => [ $self->to_residential()     ],
                'CountryCode'             => [ $self->to_country_abbrev()    ],
                'PostalCode'             => [ $self->to_zip()             ],
                'City'                    => [ $self->to_city()             ],
            } ],
        } ],
        'Service' => [ {
            'Code' => [ $self->service() ],
        } ],
        'ShipmentServiceSelfOptions' => { },
    );
    
    my @packages;
    foreach my $package ( $self->shipment->packages() ) {
        #
        # TODO: Move to a different XML generation scheme, since all the packages 
        # in a multi-package shipment will have the name "Package"
        #
        $shipment_tree{ 'Package' } = [ {
                'PackagingType' => [ {
                    'Code' => [ $package->packaging() ],
                    'Description' => [ 'Package' ],
                } ],
                
                'Description' => [ 'Rate Lookup' ],
                'PackageWeight' => [ {
                    'Weight' => [ $package->weight() ],
                } ],
            } ],
    }
    
    my $request_tree = {
        'RatingServiceSelectionRequest' => [ { 
            'Request' => [ {
                'TransactionReference' => [ {
                    'CustomerContext' => [ 'Rating and Service' ],
                    'XpciVersion' => [ 1.0001 ],  
                } ],
                'RequestAction' => [ 'Rate' ],
            } ],
            'PickupType' => [ {
                'Code' => [ '01' ]
            } ],
            'Shipment' => [ {
                %shipment_tree
            } ]
        } ]
    };

    my $access_xml = '<?xml version="1.0"?>' . "\n" 
        . XML::Simple::XMLout( $access_tree, KeepRoot => 1 );

    my $request_xml = $access_xml . "\n" . '<?xml version="1.0"?>' . "\n"
        . XML::Simple::XMLout( $request_tree, KeepRoot => 1 );
    
    debug3( $request_xml );
    
    return ( $request_xml );
}

=head2 get_total_charges()

Returns the total charges.

=cut

#
# TODO: redundant?
#
sub get_total_charges
{
    my ( $self ) = shift;
    return $self->{'total_charges'} if $self->{'total_charges'};
    return 0;
}

=head2 _handle_response

=cut

sub _handle_response
{
    trace '()';
    my ( $self ) = @_;
    
    debug3( "response = " . $self->response()->content() );
    
    my $response_tree = XML::Simple::XMLin( 
        $self->response()->content(), 
        ForceArray => 0, 
        KeepRoot => 0 
    );
    
    my $status_code = $response_tree->{Response}->{ResponseStatusCode};
    my $status_description = $response_tree->{Response}->{ResponseStatusDescription};
    my $error = $response_tree->{Response}->{Error}->{ErrorDescription};
    my $err_location = $response_tree->{Response}->{Error}->{ErrorLocation}->{ErrorLocationElementName} || '';
    if ( $error and $error !~ /Success/ ) {
        my $combined_error_msg = "$status_description ($status_code): $error @ $err_location"; 
        $combined_error_msg =~ s/\s{3,}/ /g;
        $self->user_error( $combined_error_msg );
        return;
    }
    
    my $total_charges = $response_tree->{RatedShipment}->{TotalCharges}->{MonetaryValue};
    if ( ! $total_charges ) {
        return $self->clear_is_success();
    }
    
    # This should never happen.
    for ( 'shipper', 'service' ) {
        if ( ! $self->shipment->$_() ) {
            $self->shipment->$_( 'Unknown' );
        }
    }
    
    #
    # 'return' method:
    # 1. Save a "results" hash.
    #
    # TODO: multi-package support: loop over the packages
    #
    my $packages = [
        { 
            #description
            #package_id
            'charges' => $total_charges, 
        },
        #{
        #    #another package
        #    # 'charges' => ...
        #}
    ];
    
    my $results = {
        $self->shipment->shipper() => $packages
    };
    debug3 'results = ' . uneval(  $results );
    $self->results( $results );
    
    return $self->is_success( 1 );
}

no warnings 'redefine';

=head2 to_country_abbrev()

We have to override the to_country_abbrev function becuase Online::UPS
likes its own spellings of certain country abbreviations (GB, etc.).

Redefines attribute.

=cut

sub to_country_abbrev
{
    my ( $self ) = @_;
    
    return unless $self->to_country;
    
    # Do the UPS translations
    
    my $online_ups_country_to_abbrev = cfg()->{ ups_information }->{ online_ups_country_to_abbrev };
    my $countries = config_to_hash( $online_ups_country_to_abbrev );
    my $to_country_abbrev = $countries->{ $self->to_country } || $self->SUPER::to_country_abbrev();
    
    return $to_country_abbrev || $self->to_country;
}
use warnings; # end redefine

1;

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut
