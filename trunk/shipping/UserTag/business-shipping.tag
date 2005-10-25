# [business-shipping] - Interchange Usertag for Business::Shipping
#
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.

ifndef DEF_USERTAG_BUSINESS_SHIPPING
Variable DEF_USERTAG_BUSINESS_SHIPPING     1
Message -i Loading [business-shipping]...
Require Module Business::Shipping
UserTag  business-shipping  Order         shipper
UserTag  business-shipping  AttrAlias     mode    shipper
UserTag  business-shipping  AttrAlias     carrier shipper
UserTag  business-shipping  AddAttr
UserTag  business-shipping  Documentation <<EOD
=head1 NAME

[business-shipping] - Interchange usertag for Business::Shipping

=head1 VERSION

[business-shipping] usertag:    $Rev$

Requires Business::Shipping:     Revision: 1.90+

=head1 AUTHOR 

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.
    
=head1 SYNOPSIS

[business-shipping 
    shipper=UPS_Offline
    service='Ground Residential'
    from_zip=98682
    to_zip=98270
    weight=5.00
]

=head1 REQUIRED MODULES

The following modules are required for offline UPS rate estimation.  See doc/INSTALL.

 Business::Shipping::DataFiles (any)
 Class::MethodMaker::Engine (any)
 Config::IniFiles (any)
 Log::Log4perl (any)

=head1 OPTIONAL MODULES

The following modules are used by online rate estimation and tracking.  See doc/INSTALL.

 Cache::FileCache (any)
 Clone (any)
 Crypt::SSLeay (any)
 LWP::UserAgent (any)
 XML::DOM (any)
 XML::Simple (2.05)
 
=head1 INSTALLATION

Here is a general outline for installing [business-shipping] in Interchange.

 * Follow the instructions for installing Business::Shipping.
    - (http://www.kavod.com/Business-Shipping/latest/doc/INSTALL.html)
 
 * Copy the business-shipping.tag global usertag into one of these directories:
    - interchange/usertags (IC 4.8.x)
    - interchange/code/UserTags (IC 4.9+)
   The directory will be found in /usr/lib/interchange/ if you are using the LSB
   or RPM installation.

 * Add any shipping methods that are needed to catalog/products/shipping.asc
   (examples below)
 
 * Add the following Interchange variables to provide default information.
   These can be added by copying/pasting into the variable.txt file, then
   restarting Interchange.
   
   Note that "BSHIPPING" is used to denote fields that can be used for any 
   Business::Shipping shipper.  Note that there should be one tab separating
   each of the three columns below.
   
   UPS_TIER is the pricing tier.

 BSHIPPING_LOG_INVALID_REQUESTS	1	Shipping
 BSHIPPING_DEBUG	0	Shipping
 BSHIPPING_GEN_INCIDENTS	0	Shipping
 BSHIPPING_FROM_COUNTRY	US	Shipping
 BSHIPPING_FROM_STATE	WA	Shipping
 BSHIPPING_FROM_ZIP	98682	Shipping
 BSHIPPING_MAX_WEIGHT	0	Shipping
 BSHIPPING_TO_COUNTRY_FIELD	country	Shipping
 BSHIPPING_TO_CITY_FIELD	city	Shipping
 BSHIPPING_TO_ZIP_FIELD	zip	Shipping
 UPS_ACCESS_KEY	AB12CDEF345G6	Shipping 
 UPS_USER_ID	userid	Shipping
 UPS_PASSWORD	mypassword	Shipping
 UPS_PICKUP_TYPE	Daily Pickup	Shipping
 UPS_TIER	8	Shipping
 USPS_USER_ID	123456ABCDE7890	Shipping
 USPS_PASSWORD	abcd1234d5	Shipping
    
 * Sample shipping.asc entry:

UPS_GROUND: UPS Ground
    criteria    weight
    min         0
    max         2000
    cost        f [business-shipping mode="UPS_Offline" service="Ground Residential" weight="@@TOTAL@@"]

=head1 UPGRADE from [ups-query]

If you already use [ups-query], you can replace it with the version here to be
able to re-use all of your old shipping.asc entries.  It is untested, so 
please report any bugs. 

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut

EOD

UserTag  business-shipping  Routine <<EOR
use Business::Shipping 1.90;

sub business_shipping_tag {
    my ( $shipper, $opt ) = @_;
    
    my $debug = delete $opt->{ debug } || $Variable->{ BSHIPPING_DEBUG } || 0;
    
    $shipper ||= delete $opt->{ shipper } || '';
    
    ::logDebug( "[business-shipping $shipper" . Vend::Util::uneval_it( $opt ) . " ]") if $debug;
    my $try_limit = delete $opt->{ 'try_limit' } || 2;
    
    delete $opt->{ shipper };
    
    unless ( $shipper and $opt->{weight} and $opt->{ 'service' }) {
        Log ( "mode, weight, and service required" );
        return;
    }
    
    # We pass the options mostly unmodifed to the underlying library, so here we
    # take out anything Interchange-specific that isn't necessary using a hash
    # slice.

    delete @{ $opt }{ 'reparse', 'mode', 'hide', 'shipper' };
    
    # Business::Shipping takes a hash.

    my %opt = %$opt;
    $opt = undef;

    my $to_country_default = $Values->{ $Variable->{ BSHIPPING_TO_COUNTRY_FIELD } || 'country' };
    
    # STDOUT goes to the IC debug files (usually '/tmp/debug')
    # STDERR goes to the global error log (usually 'interchange/error.log').
    #
    # Defaults: Cache enabled.  Log errors only.
    
    my $defaults = {
        'All' => {
            'to_country'        => $Values->{ 
                $Variable->{ BSHIPPING_TO_COUNTRY_FIELD } || 'country' 
            },
            'to_zip'            => $Values->{ $Variable->{ BSHIPPING_TO_ZIP_FIELD } || 'zip' },
            'to_city'           => $Values->{ $Variable->{ BSHIPPING_TO_CITY_FIELD } || 'city' },
            'from_country'      => $Variable->{ BSHIPPING_FROM_COUNTRY },
            'from_zip'          => $Variable->{ BSHIPPING_FROM_ZIP },
            'cache'             => ( defined $opt{ cache } ? $opt{ cache } : 1 ), # Allow 0
        },
        'USPS_Online' => {
            'user_id'           => $Variable->{ "USPS_USER_ID" },
            'password'          => $Variable->{ "USPS_PASSWORD" },
            'to_country' => $Tag->data( 
                'country', 
                'name', 
                $Variable->{ BSHIPPING_TO_COUNTRY_FIELD } || 'country'
            ),
        },
        'UPS_Online' => {
            'access_key'        => $Variable->{ UPS_ACCESS_KEY },
            'user_id'           => $Variable->{ UPS_USER_ID },
            'password'          => $Variable->{ UPS_PASSWORD },
        },
        'UPS_Offline' => { 
            'from_state'        => $Variable->{ BSHIPPING_FROM_STATE },
            'cache'             => 0,
        },
    };
    
    if ( my $tier = $Variable->{ UPS_TIER } ) {
        if ( $tier >= 1 and $tier <= 7 ) {
            $defaults->{UPS_Offline}{tier} = $tier;
        }
    }
    
    # Apply all of the above defaults.  Sorting the hash keys causes 'all' to
    # be applied first, which allows each shipper to override the default.
    # For example, USPS_Online overrides the to_country method.

    foreach my $shipper_key ( sort keys %$defaults ) {
        if ( $shipper_key eq $shipper or $shipper_key eq 'All' ) {
            #::logDebug( "shipper_key $shipper_key matched shipper $shipper, or was \'all\'.  Looking into defualts..." ) if $debug;
            
            my $shipper_defaults = $defaults->{ $shipper_key };
            
            for ( keys %$shipper_defaults ) {
                #::logDebug( "shipper default: $_ => " . $shipper_defaults->{ $_ } ) if $debug;
                my $value = $shipper_defaults->{ $_ };
                $opt{ $_ } ||= $value if ( $_ and defined $value );
            }
        }
    }
    
    my $rate_request;
    eval { $rate_request = Business::Shipping->rate_request( 'shipper' => $shipper ); };
    if ( ! defined $rate_request or $@ ) {
        Log( "[business-shipping] Error during Business::Shipping->rate_request(): $@ " );
        return;
    }
    
    ::logDebug( "Initializing rate_request object with: " . Vend::Util::uneval_it( \%opt ) ) if $debug;
    
    eval { $rate_request->init( %opt ); };
    if ( $@ ) {
        Log( "[business-shipping] Error during rate_request->init(): $@ " );
        return;
    }
    
    # Setting maximum weight per package.
    
    $rate_request->shipment->max_weight( $Variable->{ BSHIPPING_MAX_WEIGHT } ) 
        if $Variable->{ BSHIPPING_MAX_WEIGHT }; 
    
    ::logDebug( "calling \$rate_request->go()" ) if $debug;

    my $success;
    my $submit_results;

    eval { $submit_results = $rate_request->go( %opt ); };
    if ( not $submit_results or $@ ) { 
        
        if ( 
             ( not $rate_request->invalid ) 
             or
             ( $rate_request->invalid and $Variable->{ BSHIPPING_LOG_INVALID_REQUESTS } )
           )
        {
            Log( "[business-shipping] Error: " . ( $rate_request->user_error() || 'no user_error returned, perl error: ' . $@ ) );
        }
        
        # Prevent 500 error on some systems?
        $@ = '';
        
        return;
    }
        
    my $charges;
    
    # get_charges() should be implemented for all shippers in the future.
    # For now, we just fall back on total_charges()

    $charges ||= $rate_request->total_charges();

    # This is a debugging / support tool.  It uses these variables: 
    #   BSHIPPING_GEN_INCIDENTS
    #   SYSTEMS_SUPPORT_EMAIL
    
    my $report_incident;
    if ( 
            ( ! $charges or $charges !~ /\d+/ )
        and
            $Variable->{ 'BSHIPPING_GEN_INCIDENTS' }
       ) 
    {
        # Don't report invalid rate requests:No zip code, GNDRES to Canada, etc.
       
        if ( $rate_request->invalid ) 
            { $report_incident = 0; }
        else 
            { $report_incident = 1; }
    }
    
    if ( $report_incident ) {
        my $vars_out = $rate_request->calc_debug_string;
        
        $vars_out .= "Important variables:\n";
        foreach ( 'shipper', 'service', 'to_country', 'weight', 'to_zip', 'to_city' ) {
            $vars_out .= "\t$_ => \t\'$opt{$_}\',\n";
        }
            
        $vars_out .= "\nAll variables\n";
        foreach ( sort keys %opt ) {
            $vars_out .= "\t$_ => \t\t\'$opt{$_}\',\n";
        }                
            
        $vars_out .= "\nActual values from the rate_request object\n";
        foreach ( sort keys %opt ) {
            $vars_out .= "\t$_ => \t\t\'" . $rate_request->$_() . "\',\n";
        }
        
        $vars_out .= "\nBusiness::Shipping Version:\t" . $Business::Shipping::VERSION . "\n";
        
        my $error = $rate_request->user_error();
        
        # Ignore errors if [incident] is missing or misbehaves.
        eval {
            $Tag->incident(
                {
                    subject => $shipper . ( $error ? ": $error" : '' ), 
                    content => ( $error ? "Error:\t$error\n" : '' ) . $vars_out
                }
            );
        };
        
    }
    ::logDebug( "[business-shipping] returning " . ( $charges || 'undef' ) ) if $debug;
    
    return $charges;
}

\&business_shipping_tag;

EOR
Message ...done.
endif
