# Business::Shipping::RateRequest::Template - Template for cost estimation
# 
# $Id$
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::RateRequest::Online::UPS;

=head1 NAME

Business::Shipping::RateRequest::Online::UPS - Estimates shipping cost online

See Shipping.pm POD for usage information.

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

=over 4 
    
=cut

$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping::RateRequest::Online' );
use Business::Shipping::RateRequest::Online;
use Business::Shipping::Logging;
use Business::Shipping::Config;
use Business::Shipping::Package::UPS;
use XML::Simple 2.05;
use Cache::FileCache;
use LWP::UserAgent;

=item * access_key

=item * test_server

=item * no_ssl

=item * to_city

=cut

use Class::MethodMaker 2.0
    [
      new => [ qw/ -hash new / ],
      scalar => [ 'access_key' ],
      scalar => [ { -static => 1, -default => 'access_key' }, 'Required' ],
      scalar => [ { -static => 1, -default => 'test_server, no_ssl, to_city' }, 'Optional' ],
      scalar => [ { -default => 'https://www.ups.com/ups.app/xml/Rate' }, 'prod_url' ],
      scalar => [ { -default => 'https://wwwcie.ups.com/ups.app/xml/Rate' }, 'test_url' ],      
      scalar => [ { -type    => 'Business::Shipping::Shipment::UPS',
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
                                ],
                   },
                   'shipment'
                 ],
      scalar => [ { -static => 1, 
                    -default => "shipment=>Business::Shipping::Shipment::UPS" 
                  }, 
                  'Has_a' 
               ],
    ];

=back

=cut
