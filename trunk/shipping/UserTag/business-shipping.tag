# [business-shipping] - Interchange Usertag for Business::Shipping
#
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.

ifndef DEF_USERTAG_BUSINESS_SHIPPING
Variable DEF_USERTAG_BUSINESS_SHIPPING     1
Message -i Loading [business-shipping] usertag...
Require Module Business::Shipping
UserTag  business-shipping  Order         shipper
UserTag  business-shipping  AttrAlias     mode    shipper
UserTag  business-shipping  AttrAlias     carrier shipper
UserTag  business-shipping  Addattr
UserTag  business-shipping  Documentation <<EOD
=head1 NAME

[business-shipping] - Interchange Usertag for Business::Shipping

=head1 VERSION

[business-shipping] usertag:    $Rev$
Requires Business::Shipping:     Revision: 1.04+

=head1 AUTHOR 

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.
    
=head1 SYNOPSIS

[business-shipping 
    shipper='Offline::UPS'
    service='GNDRES'
    from_zip='98682'
    to_zip='98270'
    weight='5.00'
]
    
=head1 REQUIRED MODULES

Bundle::DBD::CSV (any)
Cache::FileCache (any)
Class::MethodMaker::Engine (any)
Clone (any)
Config::IniFiles (any)
Crypt::SSLeay (any)
Getopt::Mixed (any)
Log::Log4perl (any)
LWP::UserAgent (any)
Math::BaseCnv (any)
Scalar::Util (1.10)
XML::DOM (any)
XML::Simple (2.05)

=head1 INSTALLATION

Here is a general outline for installing [business-shipping] in Interchange.

 * Follow the instructions for installing Business::Shipping.
    - (http://www.kavod.com/Business-Shipping/latest/doc/INSTALL.html)
 
 * Copy the business-shipping.tag file into one of these directories:
    - interchange/usertags (IC 4.8.x)
    - interchange/code/UserTags (IC 4.9+)

 * Add any shipping methods that are needed to catalog/products/shipping.asc
 
 * Add the following Interchange variables to provide default information.
   These can be added by copying/pasting into the variable.txt file, then
   restarting Interchange.
   
   Note that "XPS" is used to denote fields that can be used for UPS or USPS.

XPS_FROM_COUNTRY	US	Shipping
XPS_FROM_STATE	WA	Shipping
XPS_FROM_ZIP	98682	Shipping
XPS_TO_COUNTRY_FIELD	country	Shipping
XPS_TO_CITY_FIELD	city	Shipping
XPS_TO_ZIP_FIELD	zip	Shipping
UPS_ACCESS_KEY	AB12CDEF345G6	Shipping 
UPS_USER_ID	userid	Shipping
UPS_PASSWORD	mypassword	Shipping
UPS_PICKUPTYPE	Daily Pickup	Shipping
USPS_USER_ID	123456ABCDE7890	Shipping
USPS_PASSWORD	abcd1234d5	Shipping
    
 * Sample shipping.asc entry:

UPS_GROUND: UPS Ground
    criteria    [criteria-intl]
    min            0
    max            150
    cost        f [business-shipping mode="Offline::UPS" service="GNDRES" weight="@@TOTAL@@"]

=head1 UPGRADE from [ups-query]

See the replacement [ups-query] usertag in this directory.  
Untested, so please report any bugs. 

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut
EOD
UserTag  business-shipping  Routine <<EOR
use Business::Shipping;

sub {
    my ( $shipper, $opt ) = @_;
    
    my $debug = delete $opt->{ debug } || $Variable->{ BS_DEBUG } || 0;
    ::logDebug( "[business-shipping " . uneval( $opt ) ) if $debug;
    my $try_limit = delete $opt->{ 'try_limit' } || 2;
    
    unless ( $shipper and $opt->{weight} and $opt->{ 'service' }) {
        Log ( "mode, weight, and service required" );
        return;
    }
    
    # TODO: If the user didn't specify the "Online::" or "Offline::" 
    # prefix of the shipper variable, change it to "Online::" automatically?

    # We pass the options mostly unmodifed to the underlying library, so here we
    # take out anything Interchange-specific that isn't necessary with a hash
    # slice.

    delete @{ $opt }{ 'reparse', 'mode', 'hide' };
    

    # Business::Shipping takes a hash.

    my %opt = %$opt;
    $opt = undef;

    my $to_country_default = $Values->{ $Variable->{ XPS_TO_COUNTRY_FIELD } || 'country' };
    
    # STDOUT goes to the IC debug files (usually '/tmp/debug')
    # STDERR goes to the global error log (usually 'interchange/error.log').
    #
    # Defaults: Cache enabled.  Log errors only.
    
    my $defaults = {
        'all' => {
            'to_country'        => $Values->{ 
                $Variable->{ XPS_TO_COUNTRY_FIELD } || 'country' 
            },
            'to_zip'            => $Values->{ $Variable->{ XPS_TO_ZIP_FIELD } || 'zip' },
            'to_city'           => $Values->{ $Variable->{ XPS_TO_CITY_FIELD } || 'city' },
            'from_country'      => $Variable->{ XPS_FROM_COUNTRY },
            'from_zip'          => $Variable->{ XPS_FROM_ZIP },
            'cache'             => ( defined $opt{ cache } ? $opt{ cache } : 1 ),
        },
        'Online::USPS' => {
            'user_id'           => $Variable->{ "USPS_USER_ID" },
            'password'          => $Variable->{ "USPS_PASSWORD" },
            'to_country' => $Tag->data( 
                'country', 
                'name', 
                $Variable->{ XPS_TO_COUNTRY_FIELD } || 'country'
            )
        },
        'Online::UPS' => {
            'access_key'        => $Variable->{ "UPS_ACCESS_KEY" },
            'user_id'           => $Variable->{ "UPS_USER_ID" },
            'password'          => $Variable->{ "UPS_PASSWORD" },
        },
        'Offline::UPS' => { 
            'from_state'        => $Variable->{ XPS_FROM_STATE },
            'cache'             => 0,
        },
    };
    

    # Apply all of the above defaults.  Sorting the hash keys causes 'all' to
    # be applied first, which allows each shipper to override the default.
    # For example, Online::USPS overrides the to_country method.

    foreach my $shipper_key ( sort keys %$defaults ) {
        if ( $shipper_key eq $shipper or $shipper_key eq 'all' ) {
            #::logDebug( "shipper_key $shipper_key matched shipper $shipper, or was \'all\'.  Looking into defualts..." ) if $debug;
            
            my $shipper_defaults = $defaults->{ $shipper_key };
            
            for ( keys %$shipper_defaults ) {
                #::logDebug( "shipper default: $_ => " . $shipper_defaults->{ $_ } ) if $debug;
                my $value = $shipper_defaults->{ $_ };
                $opt{ $_ } ||= $value if ( $_ and defined $value );
            }
        }
    }
    ::logDebug( "After processing all defaults, the options are now: " . uneval( \%opt ) ) if $debug;
    
    my $rate_request;
    eval {
        $rate_request = Business::Shipping->rate_request( 'shipper' => $shipper );
    };
     
    if ( ! defined $rate_request or $@ ) {
        Log( "[business-shipping] failure when calling Business::Shipping->rate_request(): $@ " );
        return;
    }
    
    ::logDebug( "calling Business::Shipping::RateRequest::${shipper}->submit( " . uneval( \%opt ) . " )" ) if $debug;
    $rate_request->init( %opt );
    my $tries = 0;
    my $success;

    # Retry the connection if you get one of these errors.  
    # They usually indicate a problem on the shipper's server.

    my @retry_errors = (
        'HTTP Error',
        'HTTP Error. Status line: 500',
        'HTTP Error. Status line: 500 Server Error',        
        'HTTP Error. Status line: 500 read timeout',
        'HTTP Error. Status line: 500 Bizarre copy of ARRAY',
        'HTTP Error. Status line: 500 Connect failed:',
        'HTTP Error. Status line: 500 Can\'t connect to production.shippingapis.com:80',
    );
    
    for ( my $tries = 1; $tries <= $try_limit; $tries++ ) {
        my $submit_results;
        eval {
            $submit_results = $rate_request->submit();
        };
        if ( $submit_results and ! $@ ) {

            # Success, no more retries

            $success = 1;
            last;
        }
        else {
            Log( "Try $tries: error: " . $rate_request->error() . "$@" );
            my $error_on_server;
            for ( @retry_errors ) {
                if ( $rate_request->error() =~ /$_/ ) {
                    $error_on_server = 1;
                    
                }
            }
            
            if ( $error_on_server ) {
                Log( 'Error was on server, trying again...' );
            }
            else {
                Log( 'Error was not on the server, giving up...' );
                last;
            }
        }
    }
    return unless $success;
    
    my $charges;
    
    # get_charges() should be implemented for all shippers in the future.
    # For now, we just fall back on total_charges()

    $charges ||= $rate_request->total_charges();

    # This is a debugging / support tool.  It uses these variables: 
    #   XPS_GEN_INCIDENTS
    #   SYSTEMS_SUPPORT_EMAIL
    
    my $report_incident;
    if ( 
            ( ! $charges or $charges !~ /\d+/ )
        and     $Variable->{ 'XPS_GEN_INCIDENTS' }
        ) 
    {
        $report_incident = 1;
        my @do_not_report_errors = (
            'Offline::UPS cannot estimate Express Plus to Canada, because not all zip codes are supported.',
        );
        if ( $rate_request->error() ) {
            foreach ( @do_not_report_errors ) {
                if ( $rate_request->error =~ /$_/ ) {
                    $report_incident = 0;
                }
            }
            if ( $rate_request->invalid ) {
                #
                # Don't report invalid rate requests (like XDM to Brazil... Brazil only has XPD/XPR).
                # Or if they didn't input a zip code, etc. 
                #
                $report_incident = 0;
            }
        }
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
        $@ = '';
    }
    ::logDebug( "[business-shipping] returning " . uneval( $charges ) ) if $debug;
    
    return $charges;
}
EOR
Message ...done.
endif
